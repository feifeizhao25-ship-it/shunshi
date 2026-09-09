"""Merchant-bound RSA2 notification validation, without real money or network."""
import base64

import pytest
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

from app.services import alipay_service as module


@pytest.fixture
def merchant(monkeypatch):
    # Independent signing key representing Alipay's public verification key.
    signer = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    app_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    monkeypatch.setattr(module, "ALIPAY_APP_ID", "test-application")
    monkeypatch.setattr(module, "ALIPAY_SELLER_ID", "test-merchant")
    monkeypatch.setattr(module, "ALIPAY_PUBLIC_KEY", signer.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo).decode())
    monkeypatch.setattr(module, "ALIPAY_PRIVATE_KEY", app_key.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption()).decode())
    service = module.AlipayService()
    service.mode = "sandbox"

    def signed(**changes):
        data = dict(app_id="test-application", seller_id="test-merchant",
                    out_trade_no="order-1", trade_no="transaction-1",
                    trade_status="TRADE_SUCCESS", total_amount="29.00",
                    buyer_id="buyer", subject="顺时会员")
        data.update(changes)
        message = "&".join(f"{key}={data[key]}" for key in sorted(data))
        data["sign"] = base64.b64encode(signer.sign(
            message.encode(), padding.PKCS1v15(), hashes.SHA256())).decode()
        data["sign_type"] = "RSA2"
        return data

    return service, signed


def test_real_sdk_verifies_rsa2_and_does_not_mutate_input(merchant):
    service, signed = merchant
    params = signed()
    before = dict(params)
    assert service.verify_notify(params).total_amount == "29.00"
    assert params == before
    params["total_amount"] = "0.01"
    with pytest.raises(ValueError, match="签名"):
        service.verify_notify(params)


@pytest.mark.parametrize("changes", [
    {"app_id": "another-app"}, {"seller_id": "another-merchant"},
    {"app_id": ""}, {"seller_id": ""}, {"trade_no": ""},
    {"out_trade_no": " "}, {"trade_status": "PAID"},
    {"total_amount": "29.001"}, {"total_amount": "NaN"},
    {"total_amount": "Infinity"}, {"total_amount": "-29.00"},
    {"total_amount": "2.9e1"}, {"total_amount": "0.00"},
])
def test_valid_signature_is_not_sufficient_payment_proof(merchant, changes):
    service, signed = merchant
    with pytest.raises(ValueError):
        service.verify_notify(signed(**changes))


@pytest.mark.parametrize("field,value", [("sign", ""), ("sign", "broken"), ("sign_type", "RSA")])
def test_rejects_invalid_signature_fields(merchant, field, value):
    service, signed = merchant
    data = signed()
    data[field] = value
    with pytest.raises(ValueError):
        service.verify_notify(data)


def test_missing_merchant_configuration_fails_closed(merchant, monkeypatch):
    service, signed = merchant
    monkeypatch.setattr(module, "ALIPAY_SELLER_ID", "")
    with pytest.raises(RuntimeError):
        service.verify_notify(signed())


def test_duplicate_form_fields_never_reach_verifier(client, monkeypatch):
    def unexpected(_params):
        pytest.fail("ambiguous form must be rejected before verification")
    monkeypatch.setattr(module.alipay_service, "verify_notify", unexpected)
    response = client.post("/api/v1/payments/alipay/notify",
                           content="sign=one&sign=two",
                           headers={"Content-Type": "application/x-www-form-urlencoded"})
    assert response.status_code == 400


def test_unavailable_verifier_returns_retryable_failure(client, monkeypatch):
    def unavailable(_params):
        raise RuntimeError("unavailable")
    monkeypatch.setattr(module.alipay_service, "verify_notify", unavailable)
    assert client.post("/api/v1/payments/alipay/notify", data={"sign": "test"}).status_code == 503


@pytest.mark.parametrize("amount", ["29.001", "NaN", "Infinity", "-1", "0"])
def test_router_rejects_invalid_amount_before_activation(client, monkeypatch, amount):
    from app.services import payment_activation
    notify = module.AlipayNotifyData(out_trade_no="order", trade_no="trade",
        trade_status="TRADE_SUCCESS", total_amount=amount, buyer_id="buyer")
    monkeypatch.setattr(module.alipay_service, "verify_notify", lambda _: notify)
    monkeypatch.setattr(payment_activation, "activate_verified_domestic_payment",
                        lambda *args, **kwargs: pytest.fail("invalid amount must not activate"))
    assert client.post("/api/v1/payments/alipay/notify", data={"sign": "test"}).status_code == 400
