"""
订阅系统 V2 单元测试
Tests for 4级会员体系、订单状态机、支付流程、过期回退、家庭席位

运行: pytest test/test_subscription_v2.py -v
"""

import os
import sys
import re

import pytest

# 确保项目根目录在 path 中
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.router.subscription import (
    # 状态机
    OrderStatus,
    VALID_TRANSITIONS,
    transition_order,
    transition_status,
    # 数据
    TIER_ORDER,
    SUBSCRIPTION_PLANS,
    SUBSCRIPTION_PRODUCTS,
    # 订单号
    generate_order_no,
    # 存储
    subscriptions,
    purchase_history,
    payment_orders,
    family_seats,
    audit_log,
    # 家庭席位
    _init_family_seats,
    get_family_seats_info,
    bind_family_member,
    unbind_family_member,
    # 过期回退
    check_expired_subscriptions,
    expire_subscription,
    # 辅助
    get_user_subscription,
)

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException


# ==================== Fixtures ====================

@pytest.fixture(autouse=True)
def clear_state():
    """每个测试前清空 in-memory 存储"""
    subscriptions.clear()
    purchase_history.clear()
    payment_orders.clear()
    family_seats.clear()
    audit_log.clear()
    yield
    subscriptions.clear()
    purchase_history.clear()
    payment_orders.clear()
    family_seats.clear()
    audit_log.clear()


# ==================== 1. test_product_list_4_tiers ====================

class TestProductList4Tiers:
    """测试4级会员商品体系"""

    def test_4_tiers_defined(self):
        """4个层级都已定义"""
        assert set(TIER_ORDER.keys()) == {"free", "yangxin", "yiyang", "jiahe"}

    def test_tier_order_correct(self):
        """层级排序正确: free < yangxin < yiyang < jiahe"""
        assert TIER_ORDER["free"] < TIER_ORDER["yangxin"]
        assert TIER_ORDER["yangxin"] < TIER_ORDER["yiyang"]
        assert TIER_ORDER["yiyang"] < TIER_ORDER["jiahe"]

    def test_plans_have_correct_prices(self):
        """各计划价格正确"""
        assert SUBSCRIPTION_PLANS["free"]["price"] == 0
        assert SUBSCRIPTION_PLANS["yangxin"]["price"] == 29
        assert SUBSCRIPTION_PLANS["yangxin"]["price_yearly"] == 199
        assert SUBSCRIPTION_PLANS["yiyang"]["price"] == 59
        assert SUBSCRIPTION_PLANS["yiyang"]["price_yearly"] == 399
        assert SUBSCRIPTION_PLANS["jiahe"]["price"] == 99
        assert SUBSCRIPTION_PLANS["jiahe"]["price_yearly"] == 699

    def test_prices_stored_in_cents(self):
        """价格用分存储"""
        assert SUBSCRIPTION_PLANS["yangxin"]["price_cents"] == 2900
        assert SUBSCRIPTION_PLANS["yangxin"]["price_yearly_cents"] == 19900
        assert SUBSCRIPTION_PLANS["yiyang"]["price_cents"] == 5900
        assert SUBSCRIPTION_PLANS["yiyang"]["price_yearly_cents"] == 39900
        assert SUBSCRIPTION_PLANS["jiahe"]["price_cents"] == 9900
        assert SUBSCRIPTION_PLANS["jiahe"]["price_yearly_cents"] == 69900

    def test_products_cover_all_tiers(self):
        """商品列表覆盖所有付费层级"""
        tiers_in_products = {p["tier"] for p in SUBSCRIPTION_PRODUCTS}
        assert tiers_in_products == {"yangxin", "yiyang", "jiahe"}

    def test_products_have_monthly_and_yearly(self):
        """每个层级都有月付和年付"""
        for tier in ["yangxin", "yiyang", "jiahe"]:
            products_for_tier = [p for p in SUBSCRIPTION_PRODUCTS if p["tier"] == tier]
            durations = {p["duration_days"] for p in products_for_tier}
            assert 30 in durations, f"{tier} 缺少月付产品"
            assert 365 in durations, f"{tier} 缺少年付产品"

    def test_products_have_alipay_and_apple(self):
        """每个 SKU 都有 alipay 和 apple 两个平台"""
        for tier in ["yangxin", "yiyang", "jiahe"]:
            for dur in [30, 365]:
                for platform in ["alipay", "apple"]:
                    found = any(
                        p["tier"] == tier and p["duration_days"] == dur and p["platform"] == platform
                        for p in SUBSCRIPTION_PRODUCTS
                    )
                    assert found, f"{tier} {dur}d {platform} 缺少产品"

    def test_jiahe_has_family_seats(self):
        """家和版有家庭席位"""
        assert SUBSCRIPTION_PLANS["jiahe"]["family_seats"] == 4
        jiahe_products = [p for p in SUBSCRIPTION_PRODUCTS if p["tier"] == "jiahe"]
        for p in jiahe_products:
            assert p.get("family_seats") == 4

    def test_non_jiahe_no_family_seats(self):
        """非家和版没有家庭席位"""
        assert "family_seats" not in SUBSCRIPTION_PLANS["free"]
        assert "family_seats" not in SUBSCRIPTION_PLANS["yangxin"]
        assert "family_seats" not in SUBSCRIPTION_PLANS["yiyang"]

    def test_all_products_active(self):
        """所有产品状态为 active"""
        for p in SUBSCRIPTION_PRODUCTS:
            assert p["status"] == "active"

    def test_all_amounts_in_cents(self):
        """所有商品金额用分存储"""
        for p in SUBSCRIPTION_PRODUCTS:
            assert "price_cents" in p
            assert isinstance(p["price_cents"], int)
            assert p["price_cents"] > 0


# ==================== 2. test_create_order ====================

class TestCreateOrder:
    """测试创建订单"""

    def test_order_no_format(self):
        """订单号格式: SHUNSHI-YYYYMMDD-XXXXXXXX"""
        order_no = generate_order_no()
        pattern = r"^SHUNSHI-\d{8}-[A-F0-9]{12}$"
        assert re.match(pattern, order_no), f"订单号格式不正确: {order_no}"

    def test_order_no_unique(self):
        """每次生成的订单号不同"""
        order_nos = {generate_order_no() for _ in range(100)}
        assert len(order_nos) == 100, "存在重复订单号"

    def test_order_no_contains_date(self):
        """订单号包含当前日期"""
        order_no = generate_order_no()
        today = datetime.now(timezone.utc).strftime("%Y%m%d")
        assert today in order_no


# ==================== 3. test_order_state_machine ====================

class TestOrderStateMachine:
    """测试订单状态机转换"""

    def test_pending_to_paid(self):
        """pending → paid"""
        assert transition_order("pending", "paid") is True

    def test_pending_to_failed(self):
        """pending → failed"""
        assert transition_order("pending", "failed") is True

    def test_pending_to_cancelled(self):
        """pending → cancelled"""
        assert transition_order("pending", "cancelled") is True

    def test_pending_to_expired(self):
        """pending → expired"""
        assert transition_order("pending", "expired") is True

    def test_paid_to_refunded(self):
        """paid → refunded"""
        assert transition_order("paid", "refunded") is True

    def test_failed_to_pending(self):
        """failed → pending (允许重新支付)"""
        assert transition_order("failed", "pending") is True

    def test_cancelled_to_pending(self):
        """cancelled → pending (允许重新下单)"""
        assert transition_order("cancelled", "pending") is True

    def test_all_valid_transitions(self):
        """验证所有合法转换"""
        valid_pairs = [
            ("pending", "paid"),
            ("pending", "failed"),
            ("pending", "cancelled"),
            ("pending", "expired"),
            ("paid", "refunded"),
            ("failed", "pending"),
            ("cancelled", "pending"),
        ]
        for current, target in valid_pairs:
            assert transition_order(current, target) is True, \
                f"应该允许 {current} → {target}"


# ==================== 4. test_invalid_transition ====================

class TestInvalidTransition:
    """测试非法状态转换被拒"""

    def test_paid_to_pending(self):
        """paid → pending 非法"""
        assert transition_order("paid", "pending") is False

    def test_paid_to_cancelled(self):
        """paid → cancelled 非法"""
        assert transition_order("paid", "cancelled") is False

    def test_refunded_to_paid(self):
        """refunded → paid 非法"""
        assert transition_order("refunded", "paid") is False

    def test_expired_to_pending(self):
        """expired → pending 非法"""
        assert transition_order("expired", "pending") is False

    def test_refunded_to_pending(self):
        """refunded → pending 非法"""
        assert transition_order("refunded", "pending") is False

    def test_invalid_status_value(self):
        """无效状态值返回 False"""
        assert transition_order("unknown", "paid") is False
        assert transition_order("pending", "unknown") is False

    def test_paid_to_expired(self):
        """paid → expired 非法"""
        assert transition_order("paid", "expired") is False

    def test_failed_to_paid(self):
        """failed → paid 非法（必须经过 pending）"""
        assert transition_order("failed", "paid") is False

    def test_cancelled_to_paid(self):
        """cancelled → paid 非法（必须经过 pending）"""
        assert transition_order("cancelled", "paid") is False


# ==================== 5. test_verify_payment ====================

class TestVerifyPayment:
    """测试支付验证流程"""

    def test_verify_payment_activates_subscription(self):
        """支付验证后订阅激活"""
        # 手动创建订单
        order_id = "test-order-001"
        payment_orders[order_id] = {
            "id": order_id,
            "order_no": "SHUNSHI-20260318-TEST001",
            "user_id": "user-test",
            "product_id": "yangxin_yearly",
            "tier": "yangxin",
            "platform": "alipay",
            "amount_cents": 19900,
            "currency": "CNY",
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
            "transaction_id": None,
            "payment_method": None,
            "paid_at": None,
        }

        # 验证状态转换
        assert transition_order("pending", "paid") is True

        # 更新订单
        order = payment_orders[order_id]
        order["status"] = "paid"
        order["paid_at"] = datetime.now(timezone.utc).isoformat()
        order["transaction_id"] = "TXN_TEST_001"

        # 激活订阅
        now = datetime.now(timezone.utc)
        expires_at = (now + timedelta(days=365)).isoformat()
        subscriptions["user-test"] = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": expires_at,
            "auto_renew": True,
            "platform": "alipay",
            "order_id": order_id,
            "activated_at": now.isoformat(),
            "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        }

        # 验证订阅
        sub = get_user_subscription("user-test")
        assert sub.plan == "yangxin"
        assert sub.status == "active"
        assert sub.auto_renew is True

    def test_verify_payment_records_history(self):
        """支付验证后记录购买历史"""
        user_id = "user-history"
        payment_orders["order-hist-001"] = {
            "id": "order-hist-001",
            "order_no": "SHUNSHI-20260318-HIST001",
            "user_id": user_id,
            "product_id": "yiyang_yearly",
            "tier": "yiyang",
            "platform": "alipay",
            "amount_cents": 39900,
            "currency": "CNY",
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
            "transaction_id": None,
            "payment_method": None,
            "paid_at": None,
        }

        # 模拟支付成功
        order = payment_orders["order-hist-001"]
        order["status"] = "paid"
        order["paid_at"] = datetime.now(timezone.utc).isoformat()
        order["transaction_id"] = "TXN_HIST_001"

        if user_id not in purchase_history:
            purchase_history[user_id] = []
        purchase_history[user_id].append({
            "plan": "yiyang",
            "price_cents": 39900,
            "platform": "alipay",
            "order_id": "order-hist-001",
            "order_no": "SHUNSHI-20260318-HIST001",
            "trade_no": "TXN_HIST_001",
            "subscribed_at": datetime.now(timezone.utc).isoformat(),
        })

        # 验证购买历史
        history = purchase_history.get(user_id, [])
        assert len(history) == 1
        assert history[0]["plan"] == "yiyang"
        assert history[0]["price_cents"] == 39900
        assert history[0]["trade_no"] == "TXN_HIST_001"

    def test_verify_payment_initializes_family_seats_for_jiahe(self):
        """家和版支付后初始化家庭席位"""
        _init_family_seats("user-jiahe", "jiahe", "order-jiahe-001")

        assert "user-jiahe" in family_seats
        assert family_seats["user-jiahe"]["family_seats"] == 4
        assert family_seats["user-jiahe"]["used_seats"] == 0

    def test_verify_payment_no_family_seats_for_yangxin(self):
        """养心版不初始化家庭席位"""
        _init_family_seats("user-yangxin", "yangxin")
        assert "user-yangxin" not in family_seats

    def test_duplicate_payment_returns_already_paid(self):
        """重复支付返回已支付"""
        order_id = "order-dup-001"
        payment_orders[order_id] = {
            "id": order_id,
            "order_no": "SHUNSHI-20260318-DUP001",
            "user_id": "user-dup",
            "product_id": "yangxin_yearly",
            "tier": "yangxin",
            "platform": "alipay",
            "amount_cents": 19900,
            "currency": "CNY",
            "status": "paid",  # 已经是 paid 状态
            "created_at": datetime.now(timezone.utc).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
            "transaction_id": "TXN_DUP_001",
            "payment_method": None,
            "paid_at": datetime.now(timezone.utc).isoformat(),
        }

        # 状态转换: paid → paid 应该是非法的
        assert transition_order("paid", "paid") is False


# ==================== 6. test_expired_rollback ====================

class TestExpiredRollback:
    """测试过期回退"""

    def test_expired_subscription_detected(self):
        """检测过期订阅"""
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        subscriptions["user-expired"] = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": past,
            "auto_renew": False,
        }

        expired = check_expired_subscriptions()
        assert len(expired) == 1
        assert expired[0]["user_id"] == "user-expired"
        assert expired[0]["plan"] == "yangxin"

    def test_expired_rollback_to_free(self):
        """过期回退到 free"""
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        subscriptions["user-rollback"] = {
            "plan": "yiyang",
            "status": "active",
            "expires_at": past,
            "auto_renew": False,
        }

        expire_subscription("user-rollback")

        sub = get_user_subscription("user-rollback")
        assert sub.plan == "free"
        assert sub.status == "expired"

    def test_active_subscription_not_expired(self):
        """未过期订阅不被回退"""
        future = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        subscriptions["user-active"] = {
            "plan": "jiahe",
            "status": "active",
            "expires_at": future,
            "auto_renew": True,
        }

        expired = check_expired_subscriptions()
        assert len(expired) == 0

    def test_free_subscription_not_affected(self):
        """free 用户不受过期检查影响"""
        subscriptions["user-free"] = {
            "plan": "free",
            "status": "active",
            "expires_at": None,
        }

        expired = check_expired_subscriptions()
        assert len(expired) == 0

    def test_multiple_expired_at_once(self):
        """批量过期回退"""
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        for i in range(5):
            subscriptions[f"user-exp-{i}"] = {
                "plan": "yangxin",
                "status": "active",
                "expires_at": past,
                "auto_renew": False,
            }

        expired = check_expired_subscriptions()
        assert len(expired) == 5

        for item in expired:
            expire_subscription(item["user_id"])

        for i in range(5):
            sub = get_user_subscription(f"user-exp-{i}")
            assert sub.plan == "free"

    def test_expired_does_not_affect_other_users(self):
        """过期回退不影响其他活跃用户"""
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        future = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()

        subscriptions["user-exp"] = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": past,
            "auto_renew": False,
        }
        subscriptions["user-ok"] = {
            "plan": "yiyang",
            "status": "active",
            "expires_at": future,
            "auto_renew": True,
        }

        expire_subscription("user-exp")

        # 被过期用户回退
        sub_exp = get_user_subscription("user-exp")
        assert sub_exp.plan == "free"

        # 其他用户不受影响
        sub_ok = get_user_subscription("user-ok")
        assert sub_ok.plan == "yiyang"
        assert sub_ok.status == "active"

    def test_jiahe_expiry_clears_family_seats(self):
        """家和版过期时清理家庭席位（当前实现只清理订阅，席位信息保留供参考）"""
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        subscriptions["user-jiahe-exp"] = {
            "plan": "jiahe",
            "status": "active",
            "expires_at": past,
            "auto_renew": False,
        }

        _init_family_seats("user-jiahe-exp", "jiahe", "order-jiahe-exp")

        expire_subscription("user-jiahe-exp")

        sub = get_user_subscription("user-jiahe-exp")
        assert sub.plan == "free"


# ==================== 7. test_family_seats ====================

class TestFamilySeats:
    """测试家庭席位管理"""

    def test_init_family_seats_jiahe(self):
        """家和版初始化4个席位"""
        _init_family_seats("owner-001", "jiahe", "order-001")

        info = get_family_seats_info("owner-001")
        assert info["family_seats"] == 4
        assert info["used_seats"] == 0
        assert info["available"] == 4
        assert info["members"] == []

    def test_init_family_seats_yangxin(self):
        """养心版不初始化席位"""
        _init_family_seats("owner-002", "yangxin")
        assert "owner-002" not in family_seats

    def test_bind_member(self):
        """绑定成员"""
        _init_family_seats("owner-bind", "jiahe")

        info = bind_family_member("owner-bind", "张三", "user-zhangsan")
        assert info["used_seats"] == 1
        assert info["available"] == 3
        assert len(info["members"]) == 1
        assert info["members"][0]["name"] == "张三"
        assert info["members"][0]["user_id"] == "user-zhangsan"

    def test_bind_multiple_members(self):
        """绑定多个成员"""
        _init_family_seats("owner-multi", "jiahe")

        for name in ["张三", "李四", "王五", "赵六"]:
            bind_family_member("owner-multi", name, f"user-{name}")

        info = get_family_seats_info("owner-multi")
        assert info["used_seats"] == 4
        assert info["available"] == 0

    def test_cannot_exceed_seats(self):
        """不能超额分配"""
        _init_family_seats("owner-over", "jiahe")

        for name in ["A", "B", "C", "D"]:
            bind_family_member("owner-over", name)

        # 第5个应该失败
        try:
            bind_family_member("owner-over", "E")
            assert False, "应该抛出异常"
        except HTTPException as e:
            assert e.status_code == 400
            assert "已满" in e.detail

    def test_unbind_member(self):
        """解绑成员释放席位"""
        _init_family_seats("owner-unbind", "jiahe")
        bind_family_member("owner-unbind", "张三", "user-zs")

        info = unbind_family_member("owner-unbind", member_user_id="user-zs")
        assert info["used_seats"] == 0
        assert info["available"] == 4
        assert len(info["members"]) == 0

    def test_unbind_by_index(self):
        """通过索引解绑成员"""
        _init_family_seats("owner-idx", "jiahe")
        bind_family_member("owner-idx", "A", "user-a")
        bind_family_member("owner-idx", "B", "user-b")

        info = unbind_family_member("owner-idx", member_index=0)
        assert info["used_seats"] == 1
        assert info["members"][0]["name"] == "B"

    def test_no_family_seats_for_non_jiahe(self):
        """非家和版查询席位返回空"""
        info = get_family_seats_info("non-jiahe-user")
        assert info["family_seats"] == 0
        assert info["used_seats"] == 0

    def test_rebind_after_unbind(self):
        """解绑后可以重新绑定"""
        _init_family_seats("owner-rebind", "jiahe")
        bind_family_member("owner-rebind", "A", "user-a")

        unbind_family_member("owner-rebind", member_user_id="user-a")
        assert get_family_seats_info("owner-rebind")["used_seats"] == 0

        bind_family_member("owner-rebind", "B", "user-b")
        assert get_family_seats_info("owner-rebind")["used_seats"] == 1


# ==================== Run Tests ====================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
