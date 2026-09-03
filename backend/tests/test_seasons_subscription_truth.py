"""SEASONS 旧订阅入口不得授予未验证权益或返回伪支付地址。"""

from importlib import import_module
from types import SimpleNamespace

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
seasons = import_module("app.router.seasons_subscription")


def test_legacy_entitlement_grants_are_retired():
    assert client.post("/api/v1/seasons/subscription/trial?user_id=u1", json={"product_id": "serenity"}).status_code == 410
    assert client.post("/api/v1/seasons/subscription/restore?user_id=u1").status_code == 410
    assert client.post("/api/v1/seasons/subscription/validate-code?user_id=u1", json={"code": "WELCOME20"}).status_code == 410


def test_checkout_fails_closed_without_configuration(monkeypatch):
    monkeypatch.delenv("STRIPE_SECRET_KEY", raising=False)
    response = client.post(
        "/api/v1/seasons/subscription/checkout?user_id=u1",
        json={"product_id": "serenity", "billing": "monthly"},
    )
    assert response.status_code == 503
    assert "checkout_url" not in response.text


def test_checkout_uses_real_stripe_session(monkeypatch):
    for key, value in {
        "STRIPE_SECRET_KEY": "sk_live_real",
        "STRIPE_PRICE_SERENITY_MONTHLY": "price_real",
        "SEASONS_CHECKOUT_SUCCESS_URL": "https://seasons.care/success",
        "SEASONS_CHECKOUT_CANCEL_URL": "https://seasons.care/cancel",
    }.items():
        monkeypatch.setenv(key, value)
    monkeypatch.setattr(seasons.stripe.checkout.Session, "create", lambda **kwargs: SimpleNamespace(url="https://checkout.stripe.com/real", id="cs_real"))
    response = client.post(
        "/api/v1/seasons/subscription/checkout?user_id=u1",
        json={"product_id": "serenity", "billing": "monthly"},
    )
    assert response.status_code == 200
    assert response.json() == {"checkout_url": "https://checkout.stripe.com/real", "session_id": "cs_real"}


def test_webhook_rejects_unsigned_payload(monkeypatch):
    monkeypatch.setenv("STRIPE_SECRET_KEY", "sk_live_real")
    monkeypatch.setenv("STRIPE_WEBHOOK_SECRET", "whsec_real")
    assert client.post("/api/v1/seasons/subscription/webhook/stripe", json={"type": "invoice.paid"}).status_code == 400
