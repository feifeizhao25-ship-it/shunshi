"""Stripe 路由必须使用真实配置并对缺配置、缺签名失败关闭。"""

from importlib import import_module
from types import SimpleNamespace

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
stripe_router = import_module("app.router.stripe")


def test_plans_are_public_and_complete():
    response = client.get("/api/v1/stripe/plans?locale=en-US")
    assert response.status_code == 200
    plans = response.json()["data"]
    assert {plan["id"] for plan in plans} == {"free", "serenity", "harmony", "family"}
    assert all({"name", "price", "currency", "features"} <= plan.keys() for plan in plans)


def test_config_fails_closed_without_publishable_key(monkeypatch):
    monkeypatch.setattr(stripe_router, "STRIPE_PUBLISHABLE_KEY", "")
    response = client.get("/api/v1/stripe/config")
    assert response.status_code == 503


def test_config_returns_real_configured_key(monkeypatch):
    monkeypatch.setattr(stripe_router, "STRIPE_PUBLISHABLE_KEY", "pk_live_configured")
    response = client.get("/api/v1/stripe/config")
    assert response.status_code == 200
    assert response.json()["data"]["publishable_key"] == "pk_live_configured"


def test_checkout_fails_closed_without_stripe(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", False)
    response = client.post("/api/v1/stripe/create-checkout-session", json={"plan_id": "serenity", "user_id": "user-001"})
    assert response.status_code == 503
    assert "checkout_url" not in response.text


def test_checkout_uses_stripe_session_when_configured(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", True)
    monkeypatch.setitem(stripe_router.STRIPE_PRICE_IDS, "serenity", "price_real")
    monkeypatch.setattr(stripe_router.stripe.checkout.Session, "create", lambda **kwargs: SimpleNamespace(url="https://checkout.stripe.com/real", id="cs_real"))
    response = client.post("/api/v1/stripe/create-checkout-session", json={"plan_id": "serenity", "user_id": "user-001"})
    assert response.status_code == 200
    assert response.json()["data"] == {"checkout_url": "https://checkout.stripe.com/real", "session_id": "cs_real"}


def test_checkout_rejects_free_and_unknown_plans():
    assert client.post("/api/v1/stripe/create-checkout-session", json={"plan_id": "free"}).status_code == 400
    assert client.post("/api/v1/stripe/create-checkout-session", json={"plan_id": "unknown"}).status_code == 400


def test_portal_fails_closed_without_stripe(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", False)
    assert client.post("/api/v1/stripe/create-portal-session?user_id=user-001").status_code == 503


def test_webhook_fails_closed_without_configuration(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", False)
    monkeypatch.setattr(stripe_router, "STRIPE_WEBHOOK_SECRET", "")
    assert client.post("/api/v1/stripe/webhook", json={"type": "anything"}).status_code == 503


def test_webhook_requires_signature_when_configured(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", True)
    monkeypatch.setattr(stripe_router, "STRIPE_WEBHOOK_SECRET", "whsec_real")
    assert client.post("/api/v1/stripe/webhook", json={"type": "anything"}).status_code == 400


def test_verified_unknown_webhook_is_acknowledged(monkeypatch):
    monkeypatch.setattr(stripe_router, "_stripe_configured", True)
    monkeypatch.setattr(stripe_router, "STRIPE_WEBHOOK_SECRET", "whsec_real")
    monkeypatch.setattr(stripe_router.stripe.Webhook, "construct_event", lambda payload, signature, secret: {"type": "unknown.event", "data": {"object": {}}})
    response = client.post("/api/v1/stripe/webhook", content=b"{}", headers={"stripe-signature": "signed"})
    assert response.status_code == 200
    assert response.json() == {"success": True, "received": True}
