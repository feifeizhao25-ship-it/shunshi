"""权益注册表：schema 校验 + /api/v1/entitlements + subscription status 同源 tier。"""

import hashlib
import hmac
import json
import time

import jwt as pyjwt
import pytest
from fastapi.testclient import TestClient

from app.entitlements import (
    REQUIRED_DIMENSIONS,
    REQUIRED_TIERS,
    RegistryError,
    get_registry,
    tier_for_product,
    validate_registry,
)
from app.main import create_app


def test_registry_endpoint_returns_valid_schema(client):
    response = client.get("/api/v1/entitlements")
    assert response.status_code == 200
    data = response.json()
    assert data["product"] == "shunshi"
    assert data["version"]
    for tier in REQUIRED_TIERS:
        assert tier in data["tiers"]
        for dim in REQUIRED_DIMENSIONS:
            assert dim in data["tiers"][tier]


def test_builtin_registry_passes_validation():
    registry = get_registry()
    assert validate_registry(registry) is registry


def test_validate_registry_rejects_bad_schema():
    with pytest.raises(RegistryError):
        validate_registry({"product": "other", "version": "1", "tiers": {}})
    with pytest.raises(RegistryError):
        validate_registry({"product": "shunshi", "version": "1", "tiers": {"free": {}}})
    good = json.loads(json.dumps(get_registry()))
    del good["tiers"]["pro"]["export"]
    with pytest.raises(RegistryError):
        validate_registry(good)
    bad_map = json.loads(json.dumps(get_registry()))
    bad_map["product_tier_map"]["x"] = "nonexistent-tier"
    with pytest.raises(RegistryError):
        validate_registry(bad_map)


def test_tier_for_product_mapping():
    assert tier_for_product("shunshi_yangxin_monthly") == "pro"
    assert tier_for_product("shunshi_family_monthly") == "family"
    assert tier_for_product("unknown-product") == "free"


def test_subscription_status_tier_from_registry(settings):
    """status 的 tier 必须由注册表 product_tier_map 推导，与 entitlements 表同源。"""
    settings.payment_callback_secret = "callback-secret"
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        user_id = pyjwt.decode(
            headers["Authorization"][7:], settings.jwt_secret, algorithms=["HS256"]
        )["sub"]
        body = {
            "user_id": user_id,
            "product_id": "shunshi_family_monthly",
            "store": "app_store",
            "expires_at": int(time.time()) + 30 * 86400,
            "original_transaction_id": "txn-registry-1",
        }
        raw = json.dumps(body).encode()
        signature = hmac.new(b"callback-secret", raw, hashlib.sha256).hexdigest()
        assert client.post(
            "/api/v1/billing/callback",
            content=raw,
            headers={"X-Payment-Signature": signature, "Content-Type": "application/json"},
        ).status_code == 200

        status = client.get("/api/v1/subscription/status", headers=headers)
        assert status.status_code == 200
        assert status.json()["active"] is True
        assert status.json()["tier"] == "family"
