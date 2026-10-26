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
}


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
    assert response.json() == {"active": False, "plan": "free", "tier": "free"}


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
        raw, signature = _signed("callback-secret", {**CALLBACK_BODY, "user_id": user_id, "original_transaction_id": "txn-2"})
        assert client.post(
            "/api/v1/billing/callback",
            content=raw,
            headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
        ).status_code == 200
        status = client.get("/api/v1/subscription/status", headers=headers)
        assert status.json()["active"] is True
        assert status.json()["product_id"] == "shunshi_yangxin_monthly"
