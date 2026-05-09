"""
顺时 - 订阅系统测试
test_subscription.py
"""

import pytest
from unittest.mock import patch, MagicMock


class TestSubscriptionPlans:
    """订阅计划列表测试"""

    def test_get_plans(self, client):
        response = client.get("/api/v1/subscription/plans?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        # 返回计划列表
        assert "plans" in data or "data" in data


class TestSubscriptionGet:
    """获取订阅状态测试"""

    def test_get_user_subscription(self, client):
        response = client.get("/api/v1/subscription?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data or "plan" in data or "status" in data


class TestSubscriptionCreate:
    """创建订阅测试"""

    def test_subscribe_monthly(self, client):
        # 实际 API 不支持 "monthly" plan，只有 free/yangxin/yiyang/family
        # 使用实际存在的 plan
        response = client.post(
            "/api/v1/subscription/subscribe?user_id=test-user-001",
            json={"plan": "yangxin", "platform": "ios"},
        )
        assert response.status_code == 200

    def test_subscribe_free(self, client):
        response = client.post(
            "/api/v1/subscription/subscribe?user_id=test-user-001",
            json={"plan": "free", "platform": "ios"},
        )
        assert response.status_code == 200


class TestSubscriptionAlipay:
    """支付宝支付测试"""

    def test_create_alipay_order(self, client):
        # 实际 API 路径是 /alipay/create-order
        response = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        assert response.status_code == 200

    def test_verify_alipay_order(self, client):
        """支付宝回调验证"""
        # 先创建一个订单
        create_resp = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        order_id = create_resp.json()["data"]["order_id"]
        
        # 验证订单（实际 API 需要 PaymentVerifyRequest: order_id + trade_no）
        response = client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id,
            "trade_no": "TEST_TRADE_001",
        })
        assert response.status_code == 200


class TestSubscriptionStripe:
    """Stripe 支付测试"""

    def test_create_stripe_checkout(self, client):
        """测试 Stripe checkout session 创建"""
        # 实际 API 路径是 /stripe/create-checkout
        response = client.post("/api/v1/subscription/stripe/create-checkout", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
            "success_url": "https://app.shunshi.com/payment/success",
            "cancel_url": "https://app.shunshi.com/payment/cancel",
        })
        assert response.status_code == 200

    def test_stripe_webhook(self, client):
        """Stripe webhook 端点"""
        response = client.post(
            "/api/v1/subscription/stripe/webhook",
            json={
                "type": "checkout.session.completed",
                "data": {
                    "id": "cs_test_mock",
                    "object": {"metadata": {"user_id": "test-user-001", "plan": "yangxin"}}
                },
            },
            headers={"Stripe-Signature": "mock_signature"},
        )
        assert response.status_code == 200


class TestSubscriptionExpiry:
    """订阅到期检查测试"""

    def test_check_expiry(self, client):
        # 实际 API 使用 GET 方法
        response = client.get("/api/v1/subscription/check-expiry")
        assert response.status_code == 200
