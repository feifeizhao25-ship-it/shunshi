"""Concurrent state transitions on independent real SQLite connections."""
from concurrent.futures import ThreadPoolExecutor
import sqlite3
import threading

import pytest
from fastapi import HTTPException

from app.database import db as db_module
from app.router.subscription import _ensure_payment_orders_table, _transition_pending_order


@pytest.mark.parametrize("same_order", [True, False])
def test_only_one_conflicting_transition_commits(tmp_path, monkeypatch, same_order):
    database = str(tmp_path / "orders.db")
    with sqlite3.connect(database) as connection:
        _ensure_payment_orders_table(connection)
        for order_id in ("first", "second"):
            connection.execute("INSERT INTO payment_orders (id, order_no, user_id, product_id, tier, platform, amount_cents, created_at, expires_at, status) VALUES (?, ?, ?, 'sku', 'yangxin', 'alipay', 2900, '2026-09-08', '2026-09-09', 'pending')", (order_id, order_id, "owner"))
    local = threading.local()
    monkeypatch.setattr(db_module, "get_db", lambda: local.connection)
    barrier = threading.Barrier(2)

    def transition(index):
        local.connection = sqlite3.connect(database, timeout=5)
        order = {"id": "first" if same_order or index == 0 else "second", "user_id": "owner", "status": "pending"}
        target = "cancelled" if same_order and index == 1 else "paid"
        try:
            barrier.wait(timeout=5)
            _transition_pending_order(order, target, "same-transaction" if target == "paid" else None)
            return target
        except HTTPException as exc:
            assert exc.status_code == 409
            assert order["status"] == "pending"
            return "conflict"
        finally:
            local.connection.close()

    with ThreadPoolExecutor(max_workers=2) as pool:
        outcomes = list(pool.map(transition, [0, 1]))
    assert outcomes.count("conflict") == 1
    with sqlite3.connect(database) as connection:
        rows = connection.execute("SELECT status FROM payment_orders").fetchall()
        assert sum(row[0] != "pending" for row in rows) == 1
