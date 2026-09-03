"""Stripe 服务适配器不能绕过验签或伪报订单查询成功。"""

import pytest

from app.services import stripe_service as module


def test_webhook_verification_fails_without_configuration(monkeypatch):
    service = module.StripeService()
    monkeypatch.setattr(service, "_configured", False)
    with pytest.raises(RuntimeError, match="Webhook 未配置"):
        service.verify_webhook(b"{}", "signature")


def test_webhook_verification_requires_signature(monkeypatch):
    service = module.StripeService()
    monkeypatch.setattr(service, "_configured", True)
    monkeypatch.setattr(module, "STRIPE_WEBHOOK_SECRET", "whsec_real")
    with pytest.raises(ValueError, match="请求头缺失"):
        service.verify_webhook(b"{}", "")


@pytest.mark.asyncio
async def test_dictionary_callback_cannot_bypass_signature():
    gateway = module.StripeGateway()
    result = await gateway.verify_callback({"type": "checkout.session.completed"})
    assert result.success is False
    assert "原始请求体和签名" in result.message


@pytest.mark.asyncio
async def test_unimplemented_order_query_is_not_reported_as_success():
    gateway = module.StripeGateway()
    result = await gateway.query_order("cs_unknown")
    assert result.success is False
