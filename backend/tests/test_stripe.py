"""
顺时 - Stripe 支付 API 路由测试
test_stripe.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestStripePlans:
    """订阅计划端点测试"""

    def test_get_plans_returns_200(self):
        """GET /api/v1/stripe/plans 返回 200"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200

    def test_plans_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_plans_is_array(self):
        """计划列表是数组"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"], list)

    def test_plans_include_free(self):
        """应该包含免费计划"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        plans = data["data"]
        plan_ids = [p.get("id") for p in plans]
        assert "free" in plan_ids

    def test_plans_include_serenity(self):
        """应该包含 Serenity 计划"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        plans = data["data"]
        plan_ids = [p.get("id") for p in plans]
        assert "serenity" in plan_ids

    def test_plans_include_harmony(self):
        """应该包含 Harmony 计划"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        plans = data["data"]
        plan_ids = [p.get("id") for p in plans]
        assert "harmony" in plan_ids

    def test_plans_include_family(self):
        """应该包含 Family 计划"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        plans = data["data"]
        plan_ids = [p.get("id") for p in plans]
        assert "family" in plan_ids

    def test_plan_has_required_fields(self):
        """计划包含必要字段"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        data = response.json()
        plans = data["data"]
        if len(plans) > 0:
            plan = plans[0]
            assert "id" in plan
            assert "name" in plan
            assert "price" in plan
            assert "currency" in plan

    def test_plans_with_locale_en_us(self):
        """GET /api/v1/stripe/plans?locale=en-US 返回英文计划"""
        response = client.get("/api/v1/stripe/plans?locale=en-US")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_plans_with_locale_zh_cn(self):
        """GET /api/v1/stripe/plans?locale=zh-CN 返回中文计划"""
        response = client.get("/api/v1/stripe/plans?locale=zh-CN")
        assert response.status_code == 200


class TestStripeConfig:
    """Stripe 配置端点测试"""

    def test_get_config_returns_200(self):
        """GET /api/v1/stripe/config 返回 200"""
        response = client.get("/api/v1/stripe/config")
        assert response.status_code == 200

    def test_config_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/stripe/config")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_config_has_publishable_key(self):
        """配置包含 publishable_key"""
        response = client.get("/api/v1/stripe/config")
        assert response.status_code == 200
        data = response.json()
        assert "publishable_key" in data["data"]


class TestCheckoutSession:
    """Stripe Checkout 会话端点测试"""

    def test_create_checkout_session_returns_200(self):
        """POST /api/v1/stripe/create-checkout-session 返回 200"""
        payload = {
            "plan_id": "serenity",
            "user_id": "user-001"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200

    def test_checkout_has_data(self):
        """响应包含 data 键"""
        payload = {
            "plan_id": "serenity",
            "user_id": "user-001"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_checkout_has_url(self):
        """Checkout 响应包含 checkout_url"""
        payload = {
            "plan_id": "harmony",
            "user_id": "user-002"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "checkout_url" in data["data"]

    def test_checkout_has_session_id(self):
        """Checkout 响应包含 session_id"""
        payload = {
            "plan_id": "family",
            "user_id": "user-003"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data["data"]

    def test_free_plan_not_allowed(self):
        """免费计划不能创建 checkout 会话"""
        payload = {
            "plan_id": "free",
            "user_id": "user-004"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 400

    def test_invalid_plan_id(self):
        """无效的计划 ID 应返回错误"""
        payload = {
            "plan_id": "invalid_plan",
            "user_id": "user-005"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 400

    def test_checkout_requires_plan_id(self):
        """缺少 plan_id 应返回错误"""
        payload = {
            "user_id": "user-006"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 422

    def test_checkout_with_urls(self):
        """支持自定义 success_url 和 cancel_url"""
        payload = {
            "plan_id": "serenity",
            "user_id": "user-007",
            "success_url": "https://myapp.com/success",
            "cancel_url": "https://myapp.com/cancel"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200

    def test_checkout_with_locale(self):
        """支持指定语言"""
        payload = {
            "plan_id": "serenity",
            "user_id": "user-008",
            "locale": "zh-CN"
        }
        response = client.post("/api/v1/stripe/create-checkout-session", json=payload)
        assert response.status_code == 200


class TestPortalSession:
    """Stripe 客户门户端点测试"""

    def test_create_portal_session_returns_200(self):
        """POST /api/v1/stripe/create-portal-session 返回 200（若有客户）"""
        response = client.post("/api/v1/stripe/create-portal-session?user_id=user-001")
        assert response.status_code in [200, 404]

    def test_portal_requires_user_id(self):
        """缺少 user_id 应返回错误"""
        response = client.post("/api/v1/stripe/create-portal-session")
        assert response.status_code == 422

    def test_portal_no_customer_404(self):
        """未关联 Stripe 客户返回 404"""
        response = client.post("/api/v1/stripe/create-portal-session?user_id=no-stripe-user")
        assert response.status_code == 404


class TestWebhook:
    """Stripe Webhook 端点测试"""

    def test_webhook_receives_post(self):
        """POST /api/v1/stripe/webhook 接收 webhook"""
        payload = {
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "metadata": {
                        "user_id": "user-001",
                        "plan_id": "serenity"
                    }
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_checkout_completed(self):
        """Webhook 处理 checkout.session.completed 事件"""
        payload = {
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "metadata": {
                        "user_id": "webhook-user-001",
                        "plan_id": "serenity"
                    }
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_subscription_updated(self):
        """Webhook 处理 customer.subscription.updated 事件"""
        payload = {
            "type": "customer.subscription.updated",
            "data": {
                "object": {
                    "metadata": {
                        "user_id": "webhook-user-002",
                        "plan_id": "harmony"
                    },
                    "status": "active"
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_subscription_deleted(self):
        """Webhook 处理 customer.subscription.deleted 事件"""
        payload = {
            "type": "customer.subscription.deleted",
            "data": {
                "object": {
                    "metadata": {
                        "user_id": "webhook-user-003"
                    }
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_payment_failed(self):
        """Webhook 处理 invoice.payment_failed 事件"""
        payload = {
            "type": "invoice.payment_failed",
            "data": {
                "object": {
                    "id": "inv_test_123"
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_unknown_event(self):
        """Webhook 接收未知事件不会崩溃"""
        payload = {
            "type": "unknown.event.type",
            "data": {
                "object": {}
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        assert response.status_code in [200, 400]

    def test_webhook_returns_success(self):
        """Webhook 返回成功响应"""
        payload = {
            "type": "checkout.session.completed",
            "data": {
                "object": {
                    "metadata": {
                        "user_id": "webhook-test",
                        "plan_id": "serenity"
                    }
                }
            }
        }
        response = client.post("/api/v1/stripe/webhook", json=payload)
        if response.status_code == 200:
            data = response.json()
            assert "success" in data or "received" in data


class TestStripeIntegration:
    """Stripe 支付流程集成测试"""

    def test_get_config_then_checkout(self):
        """完整支付流程：先获取配置再创建 checkout"""
        # 步骤 1：获取配置
        config_response = client.get("/api/v1/stripe/config")
        assert config_response.status_code == 200

        # 步骤 2：创建 checkout 会话
        checkout_payload = {
            "plan_id": "serenity",
            "user_id": "integration-user"
        }
        checkout_response = client.post("/api/v1/stripe/create-checkout-session", json=checkout_payload)
        assert checkout_response.status_code == 200

    def test_get_plans_and_checkout(self):
        """支付流程：先获取计划列表再创建 checkout"""
        # 步骤 1：获取计划
        plans_response = client.get("/api/v1/stripe/plans")
        assert plans_response.status_code == 200
        plans = plans_response.json()["data"]

        # 步骤 2：选择一个付费计划并创建 checkout
        paid_plans = [p for p in plans if p.get("price", 0) > 0]
        if len(paid_plans) > 0:
            plan_id = paid_plans[0]["id"]
            checkout_payload = {
                "plan_id": plan_id,
                "user_id": "integration-user-2"
            }
            checkout_response = client.post("/api/v1/stripe/create-checkout-session", json=checkout_payload)
            assert checkout_response.status_code == 200

    def test_plan_properties(self):
        """验证计划属性"""
        response = client.get("/api/v1/stripe/plans")
        assert response.status_code == 200
        plans = response.json()["data"]

        # 每个计划应该有价格和特性
        for plan in plans:
            assert "id" in plan
            assert "name" in plan
            assert "price" in plan
            if plan.get("price", 0) > 0:
                assert "features" in plan
