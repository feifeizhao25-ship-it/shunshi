"""国内支付真实性回归：配置缺失和旧接口都不得制造支付成功。"""

import pytest
import jwt
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


def test_alipay_catalog_matches_domestic_display_prices_and_entitlements():
    canonical = {
        product["product_id"]: product
        for product in subscription.SUBSCRIPTION_PRODUCTS
        if product["platform"] == "alipay"
    }
    sku_to_product = {
        "yangxin_monthly": "yangxin_monthly",
        "yangxin_yearly": "yangxin_yearly",
        "yiyang_monthly": "yiyang_monthly",
        "yiyang_yearly": "yiyang_yearly",
        "family_monthly": "jiahe_monthly",
        "family_yearly": "jiahe_yearly",
    }
    for sku, product_id in sku_to_product.items():
        provider = alipay_module.ALIPAY_PRODUCTS[sku]
        displayed = canonical[product_id]
        assert int(provider["price"] * 100) == displayed["price_cents"]
        assert provider["tier"] == displayed["tier"]
        assert provider["max_family_seats"] == displayed.get("family_seats", 0)


def test_alipay_bypass_order_endpoint_is_retired(client):
    response = client.post(
        "/api/v1/payments/alipay/create-order",
        json={"product_sku": "yangxin_monthly", "user_id": "forged-user"},
    )
    assert response.status_code == 410


def test_alipay_query_and_refund_require_authentication(client):
    query = client.get(
        "/api/v1/payments/alipay/query-order", params={"order_no": "unknown"}
    )
    refund = client.post(
        "/api/v1/payments/alipay/refund",
        json={"order_no": "unknown", "refund_amount": "1.00"},
    )
    assert query.status_code == 401
    assert refund.status_code == 401


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


def test_verified_alipay_callback_activates_mobile_entitlement(
    client, auth_headers, settings, monkeypatch
):
    token = auth_headers["Authorization"].removeprefix("Bearer ")
    user_id = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])["sub"]
    created = client.post(
        "/api/v1/subscription/create-order",
        json={"product_id": "yiyang_yearly", "platform": "alipay"},
        headers=auth_headers,
    )
    assert created.status_code == 200, created.text
    order_id = created.json()["data"]["order_id"]
    order_no = subscription.payment_orders[order_id]["order_no"]

    notify = alipay_module.AlipayNotifyData(
        out_trade_no=order_no,
        trade_no=f"TRADE-{order_id}",
        trade_status="TRADE_SUCCESS",
        total_amount="399.00",
        buyer_id="buyer-test",
        passback_params=f"user_id={user_id}&sku=yiyang_yearly",
    )
    monkeypatch.setattr(alipay_module.alipay_service, "verify_notify", lambda _params: notify)

    callback = client.post(
        "/api/v1/payments/alipay/notify",
        data={"sign": "verified-by-test-adapter"},
    )
    assert callback.status_code == 200, callback.text
    assert subscription.payment_orders[order_id]["status"] == "paid"

    # 模拟进程重启清空内存，订单查询仍须从持久化存储恢复。
    subscription.payment_orders.clear()
    persisted = client.get(
        f"/api/v1/subscription/orders/{order_id}", headers=auth_headers
    )
    assert persisted.status_code == 200
    assert persisted.json()["data"]["status"] == "paid"

    status = client.get("/api/v1/subscription/status", headers=auth_headers)
    assert status.status_code == 200
    assert status.json()["data"]["plan"] == "yiyang"
    assert status.json()["data"]["is_active"] is True
