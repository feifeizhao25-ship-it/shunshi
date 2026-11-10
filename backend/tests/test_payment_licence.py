"""Paid checkout stays closed unless BUSINESS_LICENSE_GRANTED is explicit."""
import os

from app.services.payment_licence import license_granted_from_env, paid_checkout_open


def test_licence_flag_defaults_closed_and_accepts_only_explicit_open_values():
    assert paid_checkout_open(False) is False
    assert paid_checkout_open(True) is True
    assert license_granted_from_env({}) is False
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": ""}) is False
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": "0"}) is False
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": "1"}) is True
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": "true"}) is True
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": "yes"}) is True
    assert license_granted_from_env({"BUSINESS_LICENSE_GRANTED": "granted"}) is True


def test_create_order_refuses_when_the_licence_flag_is_unset(client, auth_headers, monkeypatch):
    monkeypatch.delenv("BUSINESS_LICENSE_GRANTED", raising=False)
    called = {"n": 0}

    def _boom(*_a, **_k):
        called["n"] += 1
        raise AssertionError("payment provider must not be called")

    monkeypatch.setattr("app.services.alipay_service.alipay_service.create_order", _boom)
    response = client.post(
        "/api/v1/subscription/create-order",
        headers=auth_headers,
        json={"product_id": "content_yearly", "platform": "alipay"},
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "经营许可未取得，收费入口关闭"
    assert called["n"] == 0


def test_conftest_documents_the_open_flag_for_the_rest_of_the_suite():
    assert os.environ.get("BUSINESS_LICENSE_GRANTED") == "1"
