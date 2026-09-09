"""Interleave real independent SQLite writes with the main payment activation."""
import sqlite3
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.database import db as db_module
from app.router import subscription as sub
from app.services.payment_activation import activate_verified_domestic_payment
from app.simple_models import Entitlement


@pytest.mark.parametrize("competing_write", ["cancel", "reuse_transaction"])
def test_stale_order_read_cannot_grant_entitlements(client, tmp_path, monkeypatch, competing_write):
    path = tmp_path / "payment-race.db"
    writer = sqlite3.connect(path)
    writer.row_factory = sqlite3.Row
    sub._ensure_payment_orders_table(writer)
    writer.executescript("""
        CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT);
        CREATE TABLE subscriptions (id TEXT PRIMARY KEY, user_id TEXT, plan TEXT,
            status TEXT, started_at TEXT, expires_at TEXT, auto_renew INTEGER,
            platform TEXT, subscribed_at TEXT);
    """)
    for identifier in ("target", "competitor"):
        writer.execute("""INSERT INTO payment_orders
            (id,order_no,user_id,product_id,tier,platform,amount_cents,created_at,expires_at)
            VALUES (?,?,?,'yangxin_monthly','yangxin','alipay',2900,'2026-09-09','2026-09-10')
        """, (identifier, identifier, identifier))
    writer.commit()
    competitor = sqlite3.connect(path)

    class InterleavedConnection:
        fired = False

        def execute(self, sql, parameters=()):
            cursor = writer.execute(sql, parameters)
            if sql.startswith("SELECT 1 FROM payment_orders WHERE transaction_id") and not self.fired:
                # Freeze the initial non-conflicting result, then commit another
                # connection's transition before activation starts its writes.
                result = cursor.fetchone()
                self.fired = True
                if competing_write == "cancel":
                    competitor.execute("UPDATE payment_orders SET status='cancelled' WHERE id='target'")
                else:
                    competitor.execute("UPDATE payment_orders SET status='paid',transaction_id='shared-trade' WHERE id='competitor'")
                competitor.commit()
                return SimpleNamespace(fetchone=lambda: result)
            return cursor

        def __getattr__(self, name):
            return getattr(writer, name)

    connection = InterleavedConnection()
    monkeypatch.setattr(db_module, "get_db", lambda: connection)
    monkeypatch.setattr(sub, "_init_family_seats", lambda *args: None)
    monkeypatch.setattr(sub, "_write_audit_log", lambda *args: None)
    monkeypatch.setattr(sub, "subscriptions", {})
    monkeypatch.setattr(sub, "purchase_history", {})
    try:
        with pytest.raises(HTTPException) as error:
            activate_verified_domestic_payment(SimpleNamespace(app=client.app),
                order_no="target", transaction_id="shared-trade", amount_cents=2900, provider="alipay")
        assert error.value.status_code == 409
        assert connection.fired
        expected = "cancelled" if competing_write == "cancel" else "pending"
        assert writer.execute("SELECT status FROM payment_orders WHERE id='target'").fetchone()[0] == expected
        assert writer.execute("SELECT count(*) FROM subscriptions").fetchone()[0] == 0
        assert not sub.subscriptions
        with client.app.state.session_factory() as session:
            assert session.get(Entitlement, "target") is None
        assert not writer.in_transaction
    finally:
        competitor.close()
        writer.close()
