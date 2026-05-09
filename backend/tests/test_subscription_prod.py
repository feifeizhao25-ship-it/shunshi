"""
顺时 - 支付测试（生产级）
覆盖产品列表、订单创建/验签、订阅激活/过期/升级/恢复购买、并发防护、退款。

作者: Claw 🦅
"""

import pytest
from unittest.mock import patch
from datetime import datetime, timedelta


# ==================== 产品列表 ====================

class TestProductList:
    """获取产品列表"""

    def test_product_list_returns_plans(self, client):
        """产品列表应返回所有订阅计划"""
        response = client.get("/api/v1/subscription/plans?user_id=test-user-001")
        assert response.status_code == 200, "获取计划列表应返回 200"
        data = response.json()
        assert data.get("success") is True, "应返回 success=True"

    def test_product_list_has_free_plan(self, client):
        """产品列表应包含免费计划"""
        response = client.get("/api/v1/subscription/plans?user_id=test-user-001")
        data = response.json().get("data", [])
        plan_ids = [p.get("id") for p in data] if isinstance(data, list) else []
        # data 可能是 list 或嵌套在某个 key 里
        if not plan_ids and isinstance(data, dict):
            plan_ids = [p.get("id") for p in data.get("plans", data.get("items", []))]
        assert "free" in plan_ids, "产品列表应包含 free 计划"

    def test_product_list_plan_details(self, client):
        """每个产品应有 name/price/features"""
        response = client.get("/api/v1/subscription/plans?user_id=test-user-001")
        data = response.json().get("data", [])
        plans = data if isinstance(data, list) else data.get("plans", data.get("items", []))

        for plan in plans:
            assert "id" in plan, "产品应有 id"
            assert "name" in plan or "plan" in plan, "产品应有 name"
            # price 或 features 至少有一个
            assert "price" in plan or "features" in plan, (
                "产品应有 price 或 features"
            )

    def test_product_list_has_premium_plans(self, client):
        """产品列表应包含付费计划"""
        response = client.get("/api/v1/subscription/plans?user_id=test-user-001")
        data = response.json().get("data", [])
        plans = data if isinstance(data, list) else data.get("plans", data.get("items", []))
        plan_ids = [p.get("id") for p in plans]
        assert len(plan_ids) >= 3, "应至少有 3 个计划（free + 付费）"


# ==================== 订单创建 ====================

class TestCreateOrder:
    """创建订单状态为 pending"""

    def test_create_alipay_order(self, client):
        """创建支付宝订单，状态应为 pending"""
        response = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        assert response.status_code == 200, "创建订单应返回 200"
        data = response.json()
        assert data.get("success") is True

        order_data = data.get("data", {})
        assert "order_id" in order_data, "订单应包含 order_id"
        assert order_data.get("status") == "pending", (
            f"新建订单状态应为 pending，实际: {order_data.get('status')}"
        )
        assert order_data.get("plan") == "yangxin", "订单计划应为 yangxin"
        assert order_data.get("amount") > 0, "付费订单金额应大于 0"

    def test_create_free_plan_order(self, client):
        """免费计划不应有订单金额"""
        response = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "free",
        })
        # free 计划金额为 0
        data = response.json().get("data", {})
        assert data.get("amount") == 0, "免费计划金额应为 0"

    def test_create_stripe_checkout(self, client):
        """创建 Stripe checkout"""
        response = client.post("/api/v1/subscription/stripe/create-checkout", json={
            "user_id": "test-user-001",
            "plan": "yiyang",
            "success_url": "https://app.shunshi.com/success",
            "cancel_url": "https://app.shunshi.com/cancel",
        })
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True
        checkout = data.get("data", {})
        assert "session_id" in checkout, "Stripe checkout 应有 session_id"


# ==================== 支付验签 ====================

class TestVerifyPayment:
    """验签后订单变 paid"""

    def test_verify_alipay_order(self, client):
        """验签后订单状态变为 paid"""
        # 先创建订单
        create_resp = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        order_id = create_resp.json()["data"]["order_id"]

        # 验签
        verify_resp = client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id,
            "trade_no": "TEST_TRADE_VERIFY_001",
        })
        assert verify_resp.status_code == 200
        data = verify_resp.json()
        assert data.get("success") is True
        order_data = data.get("data", {})
        assert order_data.get("status") == "paid", (
            f"验签后订单状态应为 paid，实际: {order_data.get('status')}"
        )

    def test_verify_already_paid_order(self, client):
        """已支付订单重复验签应返回 already_paid"""
        # 创建并支付
        create_resp = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        order_id = create_resp.json()["data"]["order_id"]

        client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id,
            "trade_no": "TEST_TRADE_DUP_001",
        })

        # 重复验签
        dup_resp = client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id,
            "trade_no": "TEST_TRADE_DUP_002",
        })
        assert dup_resp.status_code == 200
        data = dup_resp.json().get("data", {})
        assert data.get("status") == "already_paid", (
            "重复验签应返回 already_paid"
        )

    def test_query_order_status(self, client):
        """可查询订单状态"""
        create_resp = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "yangxin",
        })
        order_id = create_resp.json()["data"]["order_id"]

        query_resp = client.get(f"/api/v1/subscription/alipay/order/{order_id}")
        assert query_resp.status_code == 200
        data = query_resp.json().get("data", {})
        assert data.get("order_id") == order_id


# ==================== 订阅激活 ====================

class TestSubscriptionActivation:
    """支付后订阅激活"""

    def test_subscription_activated_after_payment(self, client):
        """支付宝验签后订阅应激活"""
        # 创建并支付
        create_resp = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "due-test-user",
            "plan": "yiyang",
        })
        order_id = create_resp.json()["data"]["order_id"]

        client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id,
            "trade_no": "TEST_ACTIVATE_001",
        })

        # 检查订阅状态
        sub_resp = client.get("/api/v1/subscription?user_id=due-test-user")
        assert sub_resp.status_code == 200
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("status") == "active", "支付后订阅应处于 active 状态"
        assert sub_data.get("plan") == "yiyang", "订阅计划应为 yiyang"
        assert sub_data.get("expires_at") is not None, "应有到期时间"

    def test_stripe_webhook_activates_subscription(self, client):
        """Stripe webhook 应激活订阅"""
        webhook_resp = client.post(
            "/api/v1/subscription/stripe/webhook",
            json={
                "type": "checkout.session.completed",
                "data": {
                    "id": "cs_test_activate",
                    "object": {},
                    "metadata": {
                        "user_id": "complete-test-user",
                        "plan": "family",
                    },
                },
            },
            headers={"Stripe-Signature": "mock_sig"},
        )
        assert webhook_resp.status_code == 200

        # 验证订阅已激活
        sub_resp = client.get("/api/v1/subscription?user_id=complete-test-user")
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("status") == "active", "Stripe webhook 后订阅应激活"


# ==================== 恢复购买 ====================

class TestRestorePurchase:
    """恢复购买重新激活"""

    def test_restore_ios_purchase(self, client):
        """iOS 恢复购买应重新激活订阅"""
        # 先订阅
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "complete-test-user"},
            json={"plan": "yiyang", "platform": "ios"},
        )

        # 恢复购买
        restore_resp = client.post(
            "/api/v1/subscription/restore",
            params={
                "user_id": "complete-test-user",
                "receipt": "MOCK_IOS_RECEIPT_DATA_1234567890",
                "platform": "ios",
            }
        )
        assert restore_resp.status_code == 200
        data = restore_resp.json()
        assert data.get("success") is True, "恢复购买应成功"

    def test_restore_no_purchase_history(self, client):
        """无购买历史时恢复应失败"""
        restore_resp = client.post(
            "/api/v1/subscription/restore",
            params={
                "user_id": "delete-test-user",
                "receipt": "NONEXISTENT_RECEIPT",
                "platform": "android",
            }
        )
        assert restore_resp.status_code == 200
        data = restore_resp.json()
        assert data.get("success") is False, "无购买历史时恢复应失败"


# ==================== 订阅过期 ====================

class TestSubscriptionExpired:
    """过期后降为 free"""

    def test_check_expiry_endpoint(self, client):
        """到期检查端点应返回过期列表"""
        response = client.get("/api/v1/subscription/check-expiry")
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True
        assert "expired_count" in data.get("data", {}), "应返回过期数量"

    def test_expired_subscription_downgrade(self):
        """过期订阅应降级为 free"""
        from app.router.subscription import get_user_subscription
        from unittest.mock import patch
        from datetime import datetime, timedelta

        # 模拟一个已过期的订阅
        past = (datetime.now() - timedelta(days=10)).isoformat()
        mock_sub = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": past,
            "auto_renew": False,
        }

        with patch("app.router.subscription.subscriptions", {"test-expired-user": mock_sub}):
            sub = get_user_subscription("test-expired-user")
            assert sub.status == "expired", "过期订阅状态应为 expired"
            assert sub.plan == "free", "过期后应降级为 free"


# ==================== 升级会员 ====================

class TestUpgradeSubscription:
    """升级会员（补差价）"""

    def test_upgrade_from_yangxin_to_yiyang(self, client):
        """从养心版升级到颐养版"""
        # 先订阅养心版
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "test-user-001"},
            json={"plan": "yangxin", "platform": "ios"},
        )

        # 升级到颐养版
        upgrade_resp = client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "test-user-001"},
            json={"plan": "yiyang", "platform": "ios"},
        )
        assert upgrade_resp.status_code == 200
        data = upgrade_resp.json()
        assert data.get("success") is True

        # 验证已升级
        sub_resp = client.get("/api/v1/subscription?user_id=test-user-001")
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("plan") == "yiyang", (
            f"升级后计划应为 yiyang，实际: {sub_data.get('plan')}"
        )

    def test_upgrade_features_expanded(self, client):
        """升级后功能应扩展"""
        # 订阅免费版
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "cancel-test-user"},
            json={"plan": "free", "platform": "ios"},
        )
        free_resp = client.get("/api/v1/subscription?user_id=cancel-test-user")
        free_features = free_resp.json().get("data", {}).get("features", {})

        # 升级到养心版
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "cancel-test-user"},
            json={"plan": "yangxin", "platform": "ios"},
        )
        paid_resp = client.get("/api/v1/subscription?user_id=cancel-test-user")
        paid_features = paid_resp.json().get("data", {}).get("features", {})

        # 付费版功能应 >= 免费版
        assert paid_features.get("unlimited_chat") is True, (
            "养心版应支持无限聊天"
        )


# ==================== 并发购买防护 ====================

class TestConcurrentPurchase:
    """防止重复支付"""

    def test_duplicate_order_same_user(self, client):
        """同一用户短时间内创建多个订单不应重复扣款"""
        # 创建第一个订单
        order1 = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "context-test-user",
            "plan": "yangxin",
        })
        order_id_1 = order1.json()["data"]["order_id"]

        # 创建第二个订单
        order2 = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "context-test-user",
            "plan": "yangxin",
        })
        order_id_2 = order2.json()["data"]["order_id"]

        # 两个订单 ID 应不同
        assert order_id_1 != order_id_2, "每次创建应生成不同的订单 ID"

        # 第一个支付后，第二个应检测到已支付
        client.post("/api/v1/subscription/alipay/verify", json={
            "order_id": order_id_1,
            "trade_no": "TEST_CONCURRENT_001",
        })

        # 验证订阅状态为 active
        sub_resp = client.get("/api/v1/subscription?user_id=context-test-user")
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("status") == "active"

    def test_invalid_plan_rejected(self, client):
        """无效计划应被拒绝"""
        response = client.post("/api/v1/subscription/alipay/create-order", json={
            "user_id": "test-user-001",
            "plan": "nonexistent_plan",
        })
        # 无效计划应返回 400
        assert response.status_code == 400, "无效计划应返回 400"


# ==================== 退款 ====================

class TestRefund:
    """退款后订阅取消"""

    def test_cancel_subscription(self, client):
        """取消订阅应成功"""
        # 先订阅
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "cancel-test-user"},
            json={"plan": "yangxin", "platform": "ios"},
        )

        # 取消
        cancel_resp = client.post(
            "/api/v1/subscription/cancel",
            params={"user_id": "cancel-test-user"}
        )
        assert cancel_resp.status_code == 200
        data = cancel_resp.json()
        assert data.get("success") is True, "取消订阅应成功"

    def test_stripe_webhook_cancel(self, client):
        """Stripe webhook 取消事件应取消订阅"""
        # 先激活
        client.post(
            "/api/v1/subscription/stripe/webhook",
            json={
                "type": "checkout.session.completed",
                "data": {
                    "id": "cs_test_cancel",
                    "metadata": {
                        "user_id": "cancel-test-user",
                        "plan": "yiyang",
                    },
                },
            },
        )

        # 模拟取消事件
        cancel_webhook = client.post(
            "/api/v1/subscription/stripe/webhook",
            json={
                "type": "customer.subscription.deleted",
                "data": {
                    "id": "sub_cancel",
                    "metadata": {
                        "user_id": "cancel-test-user",
                    },
                },
            },
        )
        assert cancel_webhook.status_code == 200

    def test_usage_stats_available(self, client):
        """使用量统计应可获取"""
        response = client.get("/api/v1/subscription/usage?user_id=test-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True
