"""订阅模块：回调 fail-closed；验签通过才入账；禁止假开通会员。"""

import hashlib
import hmac
import json
import time

from fastapi.testclient import TestClient

from app.main import create_app

CALLBACK_BODY = {
    "user_id": "user-1",
    "product_id": "shunshi_yangxin_monthly",
    "store": "app_store",
    "expires_at": int(time.time()) + 30 * 86400,
    "original_transaction_id": "txn-1",
    "order_no": "order-callback-1",
    "amount_cents": 2900,
}


def _insert_pending_order(user_id, product_id, order_no, amount_cents):
    from app.database.db import close_test_connection, get_db
    from app.router.subscription import _ensure_payment_orders_table

    db = get_db()
    try:
        _ensure_payment_orders_table(db)
        db.execute(
            """INSERT INTO payment_orders
               (id, order_no, user_id, product_id, tier, platform, amount_cents,
                currency, status, created_at, expires_at)
               VALUES (?, ?, ?, ?, 'yangxin', 'apple', ?, 'CNY', 'pending', ?, ?)""",
            (
                order_no,
                order_no,
                user_id,
                product_id,
                amount_cents,
                "2026-01-01T00:00:00+00:00",
                "2026-01-01T00:30:00+00:00",
            ),
        )
        db.commit()
    finally:
        close_test_connection(db)


def _signed(secret: str, body: dict) -> tuple[bytes, str]:
    raw = json.dumps(body).encode()
    return raw, hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()


def test_callback_fail_closed_when_secret_unconfigured(client):
    response = client.post("/api/v1/billing/callback", json=CALLBACK_BODY)
    assert response.status_code == 503
    detail = response.json()["detail"]
    assert detail["configured"] is False


def test_subscription_status_defaults_to_free(client, auth_headers):
    response = client.get("/api/v1/subscription/status", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    assert body["active"] is False
    assert body["plan"] == "free"
    assert body["tier"] == "free"
    assert body["success"] is True
    assert body["data"]["plan"] == "free"


def test_callback_rejects_bad_signature(settings):
    settings.payment_callback_secret = "callback-secret"
    with TestClient(create_app(settings)) as client:
        response = client.post(
            "/api/v1/billing/callback",
            json=CALLBACK_BODY,
            headers={"X-Payment-Signature": "0" * 64},
        )
    assert response.status_code == 401


def test_callback_activates_entitlement_with_valid_signature(settings):
    settings.payment_callback_secret = "callback-secret"
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        # 回调 body 的 user_id 必须与登录用户一致才能查到权益；先拿到真实 user_id
        # guest token 的 sub 即用户 id，这里直接用回调返回 + status 查询闭环验证
        _insert_pending_order("user-1", CALLBACK_BODY["product_id"], CALLBACK_BODY["order_no"], CALLBACK_BODY["amount_cents"])
        raw, signature = _signed("callback-secret", CALLBACK_BODY)
        callback = client.post(
            "/api/v1/billing/callback",
            content=raw,
            headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
        )
        assert callback.status_code == 200
        assert callback.json()["active"] is True

        # 给当前登录用户补一条有效回调，验证 status 查询
        import jwt as pyjwt

        user_id = pyjwt.decode(
            headers["Authorization"][7:], settings.jwt_secret, algorithms=["HS256"]
        )["sub"]
        second = {**CALLBACK_BODY, "user_id": user_id, "original_transaction_id": "txn-2", "order_no": "order-callback-2"}
        _insert_pending_order(user_id, second["product_id"], second["order_no"], second["amount_cents"])
        raw, signature = _signed("callback-secret", second)
        assert client.post(
            "/api/v1/billing/callback",
            content=raw,
            headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
        ).status_code == 200
        status = client.get("/api/v1/subscription/status", headers=headers)
        assert status.json()["active"] is True
        assert status.json()["product_id"] == "shunshi_yangxin_monthly"


def _post_signed(client, secret, body):
    raw, signature = _signed(secret, body)
    return client.post(
        "/api/v1/billing/callback",
        content=raw,
        headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
    )


def test_callback_rejects_unknown_product_even_with_pending_order(settings):
    settings.payment_callback_secret = "callback-secret"
    body = {**CALLBACK_BODY, "product_id": "not-a-real-sku", "order_no": "order-unknown"}
    _insert_pending_order(body["user_id"], body["product_id"], body["order_no"], body["amount_cents"])
    with TestClient(create_app(settings)) as client:
        response = _post_signed(client, "callback-secret", body)
    assert response.status_code == 400


def test_callback_rejects_when_no_pending_order(settings):
    settings.payment_callback_secret = "callback-secret"
    body = {**CALLBACK_BODY, "order_no": "order-missing"}
    with TestClient(create_app(settings)) as client:
        response = _post_signed(client, "callback-secret", body)
    assert response.status_code == 400


def test_callback_rejects_amount_that_does_not_match_the_order(settings):
    settings.payment_callback_secret = "callback-secret"
    body = {**CALLBACK_BODY, "order_no": "order-amount", "amount_cents": 1}
    _insert_pending_order(body["user_id"], body["product_id"], body["order_no"], 2900)
    with TestClient(create_app(settings)) as client:
        response = _post_signed(client, "callback-secret", body)
    assert response.status_code == 400


def test_callback_rejects_catalog_price_mismatch(settings):
    from app.router.subscription import SUBSCRIPTION_PRODUCTS

    price = next(
        int(product["price_cents"])
        for product in SUBSCRIPTION_PRODUCTS
        if product["product_id"] == "content_yearly" and product.get("price_cents")
    )
    settings.payment_callback_secret = "callback-secret"
    body = {
        **CALLBACK_BODY,
        "product_id": "content_yearly",
        "order_no": "order-catalog",
        "amount_cents": price - 1,
        "original_transaction_id": "txn-catalog",
    }
    _insert_pending_order(body["user_id"], body["product_id"], body["order_no"], body["amount_cents"])
    with TestClient(create_app(settings)) as client:
        response = _post_signed(client, "callback-secret", body)
    assert response.status_code == 400


def test_callback_rejects_expiry_beyond_the_product_term(settings):
    settings.payment_callback_secret = "callback-secret"
    body = {
        **CALLBACK_BODY,
        "order_no": "order-expiry",
        "expires_at": int(time.time()) + 400 * 86400,
        "original_transaction_id": "txn-expiry",
    }
    _insert_pending_order(body["user_id"], body["product_id"], body["order_no"], body["amount_cents"])
    with TestClient(create_app(settings)) as client:
        response = _post_signed(client, "callback-secret", body)
    assert response.status_code == 400
