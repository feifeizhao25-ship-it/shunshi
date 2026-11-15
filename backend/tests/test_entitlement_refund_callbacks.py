"""Entitlement callbacks with mocked providers only.

Payment and refund notices are injected after signature verification. No test
calls a merchant payment or refund API. Partial refunds are not implemented:
a smaller verified fee is stored as deferred and does not prorate the term.
"""
import hashlib
import hmac
import json
import time
from datetime import datetime, timedelta, timezone

import jwt as pyjwt
import pytest
from fastapi.testclient import TestClient

from app.database.db import close_test_connection, get_db
from app.main import create_app
from app.router import subscription as sub
from app.services.alipay_service import AlipayNotifyData
from app.simple_models import Entitlement

NOTIFY = "/api/v1/payments/alipay/notify"
PRODUCT = "content_yearly"


def _yuan(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def _place_order(client, auth_headers):
    response = client.post(
        "/api/v1/subscription/create-order",
        headers=auth_headers,
        json={"product_id": PRODUCT, "platform": "alipay"},
    )
    assert response.status_code == 200, response.text
    return sub.payment_orders[response.json()["data"]["order_id"]]


def _notice(order, **changes):
    payload = dict(
        out_trade_no=order["order_no"],
        trade_no="trade-" + order["id"],
        trade_status="TRADE_SUCCESS",
        total_amount=_yuan(order["amount_cents"]),
        buyer_id="buyer",
    )
    payload.update(changes)
    return AlipayNotifyData(**payload)


def _post_notice(client, monkeypatch, notice):
    from app.services import alipay_service as module

    monkeypatch.setattr(module.alipay_service, "verify_notify", lambda _params: notice)
    monkeypatch.setattr(
        module.alipay_service,
        "refund",
        lambda *args, **kwargs: pytest.fail("merchant refund must not run"),
    )
    return client.post(NOTIFY, data={"sign": "verifier-stub"})


def _expiry(app, user_id):
    with app.state.session_factory() as session:
        row = session.get(Entitlement, user_id)
        return None if row is None else row.expires_at


def _order_row(order_no):
    db = get_db()
    try:
        return dict(db.execute("SELECT * FROM payment_orders WHERE order_no=?", (order_no,)).fetchone())
    finally:
        close_test_connection(db)


def _subscriptions(user_id):
    db = get_db()
    try:
        rows = db.execute(
            "SELECT id, status, expires_at FROM subscriptions WHERE user_id=? ORDER BY expires_at",
            (user_id,),
        ).fetchall()
        return [dict(row) for row in rows]
    finally:
        close_test_connection(db)


def _refund_events(order_no):
    db = get_db()
    try:
        exists = db.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='domestic_refund_events'"
        ).fetchone()
        if exists is None:
            return []
        rows = db.execute(
            "SELECT event_key, outcome, refund_cents FROM domestic_refund_events WHERE order_no=? ORDER BY event_key",
            (order_no,),
        ).fetchall()
        return [dict(row) for row in rows]
    finally:
        close_test_connection(db)


def _pay(client, monkeypatch, auth_headers):
    order = _place_order(client, auth_headers)
    response = _post_notice(client, monkeypatch, _notice(order))
    assert response.status_code == 200, response.text
    assert response.text == "success"
    return order


def _subscription_expiry(user_id, order_no):
    subscription_id = "sub_alipay_" + order_no
    match = next(row for row in _subscriptions(user_id) if row["id"] == subscription_id)
    return datetime.fromisoformat(match["expires_at"])


def test_repeated_payment_callback_does_not_credit_twice(client, auth_headers, monkeypatch):
    order = _pay(client, monkeypatch, auth_headers)
    user_id = order["user_id"]
    credited = _expiry(client.app, user_id)
    term = _subscription_expiry(user_id, order["order_no"])
    assert credited == int(term.timestamp())

    again = _post_notice(client, monkeypatch, _notice(order))
    assert again.status_code == 200
    assert again.text == "success"
    assert _expiry(client.app, user_id) == credited
    assert len(_subscriptions(user_id)) == 1
    assert _order_row(order["order_no"])["status"] == "paid"
    assert len([item for item in sub.purchase_history[user_id] if item.get("order_id") == order["id"]]) == 1


def test_stacked_renewals_extend_from_the_latest_expiry(client, auth_headers, monkeypatch):
    first = _pay(client, monkeypatch, auth_headers)
    user_id = first["user_id"]
    first_end = _subscription_expiry(user_id, first["order_no"])
    second = _pay(client, monkeypatch, auth_headers)
    second_end = _subscription_expiry(user_id, second["order_no"])
    assert second_end - first_end == timedelta(days=365)
    assert _expiry(client.app, user_id) == int(second_end.timestamp())

    # Replaying either paid callback restores the latest term and does not add days.
    assert _post_notice(client, monkeypatch, _notice(first)).status_code == 200
    assert _post_notice(client, monkeypatch, _notice(second)).status_code == 200
    assert _expiry(client.app, user_id) == int(second_end.timestamp())
    assert len(_subscriptions(user_id)) == 2

    third = _pay(client, monkeypatch, auth_headers)
    third_end = _subscription_expiry(user_id, third["order_no"])
    assert third_end - second_end == timedelta(days=365)
    assert _expiry(client.app, user_id) == int(third_end.timestamp())
    for order in (first, second, third):
        assert _post_notice(client, monkeypatch, _notice(order)).status_code == 200
    assert _expiry(client.app, user_id) == int(third_end.timestamp())
    assert len(_subscriptions(user_id)) == 3
    assert all(row["status"] == "active" for row in _subscriptions(user_id))


def test_repeated_refund_callback_does_not_refund_twice(client, auth_headers, monkeypatch):
    first = _pay(client, monkeypatch, auth_headers)
    user_id = first["user_id"]
    first_end = _subscription_expiry(user_id, first["order_no"])
    second = _pay(client, monkeypatch, auth_headers)
    second_end = _subscription_expiry(user_id, second["order_no"])
    assert _expiry(client.app, user_id) == int(second_end.timestamp())

    refund = _notice(
        second,
        trade_status="TRADE_CLOSED",
        refund_fee=_yuan(second["amount_cents"]),
        gmt_refund="2026-11-07 18:00:00",
        out_biz_no="RF-FULL-LATEST",
    )
    assert _post_notice(client, monkeypatch, refund).status_code == 200
    # The later term is removed once. The earlier paid term remains the expiry.
    assert _expiry(client.app, user_id) == int(first_end.timestamp())
    assert _order_row(second["order_no"])["status"] == "refunded"
    assert _order_row(first["order_no"])["status"] == "paid"
    assert _refund_events(second["order_no"]) == [{
        "event_key": f"{second['order_no']}:trade-{second['id']}:RF-FULL-LATEST",
        "outcome": "settled",
        "refund_cents": second["amount_cents"],
    }]

    assert _post_notice(client, monkeypatch, refund).status_code == 200
    assert _expiry(client.app, user_id) == int(first_end.timestamp())
    assert len(_refund_events(second["order_no"])) == 1
    assert _subscription_expiry(user_id, first["order_no"]) == first_end

    # A payment replay of the refunded order must not credit that term again.
    replay = _notice(second)
    assert _post_notice(client, monkeypatch, replay).status_code == 409
    assert _expiry(client.app, user_id) == int(first_end.timestamp())


def test_partial_refund_is_not_implemented_and_does_not_change_entitlement(client, auth_headers, monkeypatch):
    """Partial refunds are not implemented.

    The current code stores a verified refund_fee smaller than the paid amount
    as a deferred event. It does not prorate or shorten the entitlement, it
    does not mark the order refunded, and it does not call the merchant refund
    API. Repeating that notice does not create a second event. This documents
    the current behaviour and does not define a proration policy.
    """
    order = _pay(client, monkeypatch, auth_headers)
    user_id = order["user_id"]
    expiry = _expiry(client.app, user_id)
    partial = _notice(
        order,
        trade_status="TRADE_SUCCESS",
        refund_fee="1.00",
        gmt_refund="2026-11-07 18:00:00",
        out_biz_no="RF-PARTIAL",
    )
    assert _post_notice(client, monkeypatch, partial).status_code == 200
    assert _expiry(client.app, user_id) == expiry
    assert _order_row(order["order_no"])["status"] == "paid"
    assert _refund_events(order["order_no"]) == [{
        "event_key": f"{order['order_no']}:trade-{order['id']}:RF-PARTIAL",
        "outcome": "deferred",
        "refund_cents": 100,
    }]

    assert _post_notice(client, monkeypatch, partial).status_code == 200
    assert _expiry(client.app, user_id) == expiry
    assert _refund_events(order["order_no"]) == [{
        "event_key": f"{order['order_no']}:trade-{order['id']}:RF-PARTIAL",
        "outcome": "deferred",
        "refund_cents": 100,
    }]

    other_partial = _notice(
        order,
        trade_status="TRADE_SUCCESS",
        refund_fee="2.00",
        gmt_refund="2026-11-07 18:05:00",
        out_biz_no="RF-PARTIAL-2",
    )
    assert _post_notice(client, monkeypatch, other_partial).status_code == 200
    assert _expiry(client.app, user_id) == expiry
    assert _order_row(order["order_no"])["status"] == "paid"
    assert [row["outcome"] for row in _refund_events(order["order_no"])] == ["deferred", "deferred"]
    assert len(sub.purchase_history[user_id]) == 1


def _signed(secret, body):
    raw = json.dumps(body).encode()
    signature = hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()
    return raw, signature


def test_repeated_store_callback_does_not_add_a_second_term(settings):
    """The store callback stores the signed expires_at. A replay keeps it.

    A later renewal callback replaces that instant with the new signed expiry.
    The server does not add the previous term again.
    """
    settings.payment_callback_secret = "callback-secret"
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        user_id = pyjwt.decode(
            login.json()["access_token"], settings.jwt_secret, algorithms=["HS256"]
        )["sub"]
        first_expiry = int(time.time()) + 10 * 86400
        body = {
            "user_id": user_id,
            "product_id": "shunshi_yangxin_monthly",
            "store": "app_store",
            "expires_at": first_expiry,
            "original_transaction_id": "txn-stack-1",
            "order_no": "order-stack-1",
            "amount_cents": 2900,
        }
        from .test_subscription import _insert_pending_order

        _insert_pending_order(user_id, body["product_id"], body["order_no"], body["amount_cents"])
        for _ in range(2):
            raw, signature = _signed("callback-secret", body)
            response = client.post(
                "/api/v1/billing/callback",
                content=raw,
                headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
            )
            assert response.status_code == 200
            assert _expiry(client.app, user_id) == first_expiry

        renewed = first_expiry + 10 * 86400
        renewed_body = {
            **body,
            "expires_at": renewed,
            "original_transaction_id": "txn-stack-2",
            "order_no": "order-stack-2",
        }
        _insert_pending_order(user_id, renewed_body["product_id"], renewed_body["order_no"], renewed_body["amount_cents"])
        for _ in range(2):
            raw, signature = _signed("callback-secret", renewed_body)
            assert client.post(
                "/api/v1/billing/callback",
                content=raw,
                headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
            ).status_code == 200
            assert _expiry(client.app, user_id) == renewed
            assert _expiry(client.app, user_id) != renewed + 365 * 86400
