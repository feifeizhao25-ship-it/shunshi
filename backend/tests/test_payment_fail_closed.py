"""国内支付真实性回归：配置缺失和旧接口都不得制造支付成功。"""

import pytest
from fastapi import HTTPException

from app.router import subscription
from app.services import alipay_service as alipay_module


def test_alipay_service_rejects_missing_merchant_configuration(monkeypatch):
    monkeypatch.setattr(alipay_module, "ALIPAY_APP_ID", "")
    monkeypatch.setattr(alipay_module, "ALIPAY_PRIVATE_KEY", "")
    service = alipay_module.AlipayService()
    service.mode = "production"

    with pytest.raises(RuntimeError, match="商户配置不完整"):
        service.create_order("yangxin_monthly", "user-1")


@pytest.mark.asyncio
async def test_subscription_create_order_returns_503_instead_of_mock(monkeypatch):
    def unavailable(**_kwargs):
        raise RuntimeError("支付宝商户配置不完整")

    monkeypatch.setattr(alipay_module.alipay_service, "create_order", unavailable)
    request = subscription.CreateOrderRequest(
        product_id="yangxin_monthly",
        platform="alipay",
    )

    with pytest.raises(HTTPException) as error:
        await subscription.create_order(request, "user-1")
    assert error.value.status_code == 503


@pytest.mark.asyncio
async def test_legacy_client_cannot_self_report_alipay_success():
    with pytest.raises(HTTPException) as error:
        await subscription.alipay_verify(
            subscription.PaymentVerifyRequest(order_id="any", trade_no="invented")
        )
    assert error.value.status_code == 410

