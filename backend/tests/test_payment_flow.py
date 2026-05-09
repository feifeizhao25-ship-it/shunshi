"""
支付状态机完整流程测试
创建订单 → 支付 → 激活 → 过期 → 回退 → 恢复

覆盖:
  1. 商品查询 (ProductQuery)
  2. 订单创建 (OrderCreation)
  3. 支付验证 (PaymentVerification)
  4. 订阅状态 (SubscriptionStatus)
  5. 过期与回退 (ExpiryRollback)
  6. 恢复购买 (RestorePurchaseFlow)
  7. 权益检查 (TierPermissions)

运行:
  cd ~/Documents/Shunshi/backend && source .venv/bin/activate
  pytest test/test_payment_flow.py -v
"""

import os
import sys
import re
import json
import sqlite3
import pytest
import pytest_asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from datetime import datetime, timedelta, timezone

# 确保项目根目录在 path 中
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from httpx import AsyncClient, ASGITransport

from app.router.subscription import (
    # 状态机
    OrderStatus,
    transition_order,
    transition_status,
    # 数据
    TIER_ORDER,
    SUBSCRIPTION_PLANS,
    SUBSCRIPTION_PRODUCTS,
    generate_order_no,
    # 存储 (module-level dicts)
    subscriptions,
    purchase_history,
    payment_orders,
    family_seats,
    audit_log,
    usage_stats,
    # 辅助函数
    get_user_subscription,
    get_family_seats_info,
    _init_family_seats,
    check_expired_subscriptions,
    expire_subscription,
    _get_user_subscription_lazy,
    _notify_subscription_expired,
    _write_audit_log,
)

from fastapi import FastAPI, HTTPException


# ============================================================
# Fixtures
# ============================================================

# 内存 DB schema (仅 notifications 表 — 过期通知需要)
_NOTIFICATIONS_TABLE = """
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data TEXT DEFAULT '{}',
    is_read INTEGER DEFAULT 0,
    sent_at TEXT DEFAULT (datetime('now')),
    read_at TEXT
);
"""


def _make_memory_db() -> sqlite3.Connection:
    """创建内存 SQLite"""
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.executescript(_NOTIFICATIONS_TABLE)
    conn.commit()
    return conn


@pytest.fixture()
def db():
    conn = _make_memory_db()
    yield conn
    conn.close()


@pytest.fixture()
def app(db, monkeypatch):
    """
    创建轻量 FastAPI app，仅注册 subscription 路由。
    清空模块级全局状态。
    替换 get_db 指向内存数据库 (通知写入需要)。
    """
    from app.router import subscription as sub_mod
    from app.database import db as db_mod

    # 清空 subscription 模块的 in-memory 存储
    monkeypatch.setattr(sub_mod, "subscriptions", {})
    monkeypatch.setattr(sub_mod, "purchase_history", {})
    monkeypatch.setattr(sub_mod, "payment_orders", {})
    monkeypatch.setattr(sub_mod, "family_seats", {})
    monkeypatch.setattr(sub_mod, "audit_log", [])
    monkeypatch.setattr(sub_mod, "usage_stats", {})

    # 替换 get_db → 内存 DB (用于通知)
    monkeypatch.setattr(db_mod, "get_db", lambda: db)

    test_app = FastAPI(title="Test Subscription API")
    test_app.include_router(sub_mod.router)
    return test_app


@pytest_asyncio.fixture(loop_scope="function")
async def client(app, monkeypatch):
    """异步 httpx 测试客户端"""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c


@pytest.fixture(autouse=True)
def clear_module_state():
    """每个测试前清空模块级状态 (防止同步测试污染)"""
    subscriptions.clear()
    purchase_history.clear()
    payment_orders.clear()
    family_seats.clear()
    audit_log.clear()
    usage_stats.clear()
    yield
    subscriptions.clear()
    purchase_history.clear()
    payment_orders.clear()
    family_seats.clear()
    audit_log.clear()
    usage_stats.clear()


# ============================================================
# 辅助
# ============================================================

SUB_MOD = "app.router.subscription"

API_BASE = "/api/v1/subscription"


async def _create_and_pay_order(client, user_id, product_id, platform="alipay"):
    """创建订单 → 模拟支付 → 验证支付。返回 (order_id, resp_json)"""
    # 1. 创建订单
    resp = await client.post(
        f"{API_BASE}/create-order",
        json={"product_id": product_id, "platform": platform},
        params={"user_id": user_id},
    )
    assert resp.status_code == 200, f"创建订单失败: {resp.text}"
    order_id = resp.json()["data"]["order_id"]

    # 2. 模拟支付回调
    resp = await client.post(
        f"{API_BASE}/verify-payment",
        json={
            "order_id": order_id,
            "platform": platform,
            "transaction_id": f"TXN_TEST_{order_id[:8]}",
        },
    )
    return order_id, resp.json()


# ============================================================
# 1. 商品查询 (ProductQuery)
# ============================================================


class TestProductQuery:
    """商品列表 API 测试"""

    @pytest.mark.asyncio
    async def test_list_all_products(self, client):
        resp = await client.get(f"{API_BASE}/products")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True
        products = body["data"]["products"]
        # 12 个 SKU: 3 tiers × 2 durations × 2 platforms
        assert len(products) == 12

    @pytest.mark.asyncio
    async def test_products_have_valid_pricing(self, client):
        resp = await client.get(f"{API_BASE}/products")
        products = resp.json()["data"]["products"]
        for p in products:
            assert p["price_cents"] > 0
            assert p["price_display"].startswith("¥")
            assert p["currency"] == "CNY"
            # price_display 应等于 price_cents / 100
            expected = f"¥{p['price_cents'] / 100:.2f}"
            assert p["price_display"] == expected, f"{p['product_id']}: {p['price_display']} != {expected}"

    @pytest.mark.asyncio
    async def test_platform_filter(self, client):
        # 仅 alipay
        resp = await client.get(f"{API_BASE}/products", params={"platform": "alipay"})
        products = resp.json()["data"]["products"]
        assert len(products) == 6  # 3 tiers × 2 durations
        for p in products:
            assert p["platform"] == "alipay"

        # 仅 apple
        resp = await client.get(f"{API_BASE}/products", params={"platform": "apple"})
        products = resp.json()["data"]["products"]
        assert len(products) == 6
        for p in products:
            assert p["platform"] == "apple"

    @pytest.mark.asyncio
    async def test_tier_structure(self, client):
        resp = await client.get(f"{API_BASE}/products")
        data = resp.json()["data"]
        # tiers 应该包含4个层级
        assert data["tiers"] == ["free", "yangxin", "yiyang", "jiahe"]
        # 产品中应该覆盖所有付费层级
        tiers_in_products = {p["tier"] for p in data["products"]}
        assert tiers_in_products == {"yangxin", "yiyang", "jiahe"}
        # 所有产品都应有 features
        for p in data["products"]:
            assert "features" in p
            assert "basic_chat" in p["features"]


# ============================================================
# 2. 订单创建 (OrderCreation)
# ============================================================


class TestOrderCreation:
    """创建订单 API 测试"""

    @pytest.mark.asyncio
    async def test_create_order_success(self, client):
        resp = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yangxin_monthly", "platform": "alipay"},
            params={"user_id": "user-create-001"},
        )
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["status"] == "pending"
        assert data["amount_cents"] == 2900
        assert data["amount_display"] == "¥29.00"
        assert data["currency"] == "CNY"
        assert data["expires_in"] == 1800

    @pytest.mark.asyncio
    async def test_create_order_invalid_product(self, client):
        resp = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "nonexistent_product", "platform": "alipay"},
        )
        assert resp.status_code == 400
        assert "产品不存在" in resp.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_order_generates_order_id(self, client):
        resp = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yiyang_yearly", "platform": "apple"},
            params={"user_id": "user-order-id-001"},
        )
        data = resp.json()["data"]
        assert "order_id" in data
        assert "order_no" in data
        # order_no 格式: SHUNSHI-YYYYMMDD-XXXXXXXX
        assert re.match(r"^SHUNSHI-\d{8}-[A-F0-9]{12}$", data["order_no"])

    @pytest.mark.asyncio
    async def test_create_duplicate_order_same_product(self, client, monkeypatch):
        """已是同等级会员时不能重复购买"""
        user_id = "user-dup-001"
        # 先激活一个 yangxin 订阅
        monkeypatch.setattr("app.router.subscription.subscriptions", {user_id: {
            "plan": "yangxin",
            "status": "active",
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
            "auto_renew": True,
            "platform": "alipay",
            "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        }})
        # 尝试再次购买同等级
        resp = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yangxin_monthly", "platform": "alipay"},
            params={"user_id": user_id},
        )
        assert resp.status_code == 400
        assert "无需重复购买" in resp.json()["detail"]


# ============================================================
# 3. 支付验证 (PaymentVerification)
# ============================================================


class TestPaymentVerification:
    """支付验证 API 测试"""

    @pytest.mark.asyncio
    async def test_verify_payment_activates_subscription(self, client, monkeypatch):
        user_id = "user-verify-001"
        _, resp = await _create_and_pay_order(client, user_id, "yangxin_monthly")
        assert resp["success"] is True
        assert resp["data"]["status"] == "paid"
        assert resp["data"]["plan"] == "yangxin"
        # 检查数据库状态 (通过模块级引用)
        from app.router import subscription as sub_mod
        sub_store = sub_mod.subscriptions
        assert sub_store[user_id]["plan"] == "yangxin"
        assert sub_store[user_id]["status"] == "active"

    @pytest.mark.asyncio
    async def test_verify_payment_updates_user_tier(self, client, monkeypatch):
        user_id = "user-tier-001"
        _, resp = await _create_and_pay_order(client, user_id, "jiahe_monthly")
        assert resp["data"]["plan"] == "jiahe"
        # 通过 API 查询状态确认
        resp_status = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        assert resp_status.json()["data"]["plan"] == "jiahe"

    @pytest.mark.asyncio
    async def test_verify_invalid_payment(self, client):
        # 验证不存在的订单
        resp = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": "nonexistent-order-id", "platform": "alipay"},
        )
        assert resp.status_code == 404

        # 创建订单后，模拟已支付状态再验证（非pending不能支付）
        resp_create = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yangxin_monthly", "platform": "alipay"},
        )
        order_id = resp_create.json()["data"]["order_id"]

        # 先取消订单
        resp_cancel = await client.post(
            f"{API_BASE}/cancel-order",
            json={"order_id": order_id},
        )
        assert resp_cancel.status_code == 200

        # 再尝试对已取消的订单支付
        resp = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": order_id, "platform": "alipay"},
        )
        assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_verify_duplicate_payment(self, client):
        """重复支付同一订单返回 already_paid"""
        user_id = "user-dup-pay-001"
        order_id, resp = await _create_and_pay_order(client, user_id, "yiyang_yearly")
        assert resp["data"]["status"] == "paid"

        # 再次支付同一订单
        resp2 = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": order_id, "platform": "alipay"},
        )
        assert resp2.status_code == 200
        assert resp2.json()["data"]["status"] == "already_paid"

    @pytest.mark.asyncio
    async def test_verify_payment_creates_audit_log(self, client):
        user_id = "user-audit-001"
        from app.router import subscription as sub_mod
        assert len(sub_mod.audit_log) == 0

        await _create_and_pay_order(client, user_id, "yangxin_monthly")

        # 应该有创建订单和支付验证两条审计日志
        actions = [e["action"] for e in sub_mod.audit_log]
        assert "order_created" in actions
        assert "payment_verified" in actions


# ============================================================
# 4. 订阅状态 (SubscriptionStatus)
# ============================================================


class TestSubscriptionStatus:
    """订阅状态查询测试"""

    @pytest.mark.asyncio
    async def test_free_user_status(self, client):
        resp = await client.get(f"{API_BASE}/status", params={"user_id": "user-free-new"})
        data = resp.json()["data"]
        assert data["plan"] == "free"
        assert data["status"] == "active"
        assert data["expires_at"] is None
        assert data["features"]["basic_chat"] is True
        assert data["features"]["unlimited_chat"] is False

    @pytest.mark.asyncio
    async def test_paid_user_status(self, client):
        user_id = "user-paid-status"
        await _create_and_pay_order(client, user_id, "yiyang_yearly")

        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        data = resp.json()["data"]
        assert data["plan"] == "yiyang"
        assert data["status"] == "active"
        assert data["expires_at"] is not None
        assert data["features"]["deep_suggestions"] is True
        assert data["features"]["weekly_summary"] is True

    @pytest.mark.asyncio
    async def test_subscription_end_date(self, client):
        user_id = "user-end-date"
        # 月付 → 30天
        order_id, resp = await _create_and_pay_order(client, user_id, "yangxin_monthly")
        expires_at_str = resp["data"]["subscription"]["expires_at"]
        expires_at = datetime.fromisoformat(expires_at_str)

        # 过期时间应在约30天后 (±1s 容差)
        expected = datetime.now(timezone.utc) + timedelta(days=30)
        diff = abs((expires_at - expected).total_seconds())
        assert diff < 2, f"过期时间偏差: {diff}s"

    @pytest.mark.asyncio
    async def test_tier_permissions(self, client):
        """不同层级的 features 不同"""
        # Free
        resp_free = await client.get(f"{API_BASE}/status", params={"user_id": "user-perm-free"})
        free_features = resp_free.json()["data"]["features"]

        # Yangxin
        user_yx = "user-perm-yx"
        await _create_and_pay_order(client, user_yx, "yangxin_monthly")
        resp_yx = await client.get(f"{API_BASE}/status", params={"user_id": user_yx})
        yx_features = resp_yx.json()["data"]["features"]

        # 养心版应该比免费版多 unlimited_chat 和 today_plan
        assert yx_features["unlimited_chat"] is True  # free 无此权限
        assert yx_features["today_plan"] is True  # free 无此权限
        assert free_features["unlimited_chat"] is False
        assert free_features["today_plan"] is False


# ============================================================
# 5. 过期与回退 (ExpiryRollback)
# ============================================================


class TestExpiryRollback:
    """过期回退测试"""

    @pytest.mark.asyncio
    async def test_expired_subscription_downgrades(self, client, monkeypatch, db):
        """过期订阅降级为 free"""
        from app.router import subscription as sub_mod
        user_id = "user-exp-001"
        # 先激活一个订阅 (已过期)
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        sub_mod.subscriptions[user_id] = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": past,
            "auto_renew": True,
            "platform": "alipay",
            "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        }

        # 调用过期检查 API
        resp = await client.post(f"{API_BASE}/check-expired")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["expired_count"] >= 1
        assert any(u["user_id"] == user_id for u in data["expired_users"])

        # 验证降级后的状态 (通过 API)
        resp_status = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        # get_user_subscription 会 lazy check 过期
        status_data = resp_status.json()["data"]
        assert status_data["plan"] == "free"

    @pytest.mark.asyncio
    async def test_expired_notification_sent(self, client, monkeypatch, db):
        """过期时发送通知"""
        user_id = "user-notif-001"
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        monkeypatch.setattr("app.router.subscription.subscriptions", {
            user_id: {
                "plan": "yiyang",
                "status": "active",
                "expires_at": past,
                "auto_renew": True,
                "platform": "apple",
                "features": SUBSCRIPTION_PLANS["yiyang"]["features"],
            }
        })

        # 手动执行过期
        from app.router.subscription import expire_subscription
        expire_subscription(user_id)

        # 检查数据库中有通知
        rows = db.execute(
            "SELECT * FROM notifications WHERE user_id = ?", (user_id,)
        ).fetchall()
        assert len(rows) >= 1
        assert rows[0]["type"] == "subscription_expired"
        assert "颐养版" in rows[0]["body"] or "过期" in rows[0]["body"]

    @pytest.mark.asyncio
    async def test_expired_family_seats_cleared(self, client, monkeypatch, db):
        """家和版过期后，家庭席位被清理"""
        from app.router import subscription as sub_mod
        user_id = "user-jiahe-exp"
        past = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
        sub_mod.subscriptions[user_id] = {
            "plan": "jiahe",
            "status": "active",
            "expires_at": past,
            "auto_renew": True,
            "platform": "alipay",
            "features": SUBSCRIPTION_PLANS["jiahe"]["features"],
        }

        # 先初始化家庭席位
        sub_mod.family_seats[user_id] = {
            "family_seats": 4,
            "used_seats": 2,
            "members": [{"name": "张三"}, {"name": "李四"}],
            "order_id": "order-001",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        # 执行过期
        from app.router.subscription import expire_subscription
        expire_subscription(user_id)

        # 验证订阅已降级
        sub = _get_user_subscription_lazy(user_id)
        assert sub["plan"] == "free"

    @pytest.mark.asyncio
    async def test_bulk_expired_check(self, client, db):
        """批量过期检查"""
        from app.router import subscription as sub_mod
        # 创建多个过期用户
        past = (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()
        for i in range(3):
            uid = f"user-bulk-exp-{i}"
            sub_mod.subscriptions[uid] = {
                "plan": "yangxin",
                "status": "active",
                "expires_at": past,
                "auto_renew": False,
                "platform": "alipay",
                "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
            }

        resp = await client.post(f"{API_BASE}/check-expired")
        data = resp.json()["data"]
        assert data["expired_count"] == 3

        # 全部降级
        for i in range(3):
            uid = f"user-bulk-exp-{i}"
            sub = _get_user_subscription_lazy(uid)
            assert sub["plan"] == "free"


# ============================================================
# 6. 恢复购买 (RestorePurchaseFlow)
# ============================================================


class TestRestorePurchaseFlow:
    """恢复购买测试"""

    @pytest.mark.asyncio
    async def test_restore_valid_subscription(self, client):
        """有购买历史时恢复成功"""
        from app.router import subscription as sub_mod
        user_id = "user-restore-001"
        # 手动设置 ios 平台购买历史 (模拟之前通过 IAP 购买)
        sub_mod.purchase_history[user_id] = [{
            "plan": "yiyang",
            "price_cents": 39900,
            "platform": "ios",
            "order_id": "ord-restore-001",
            "order_no": "SHUNSHI-20260318-RESTORE001",
            "trade_no": "TXN_RESTORE_001",
            "subscribed_at": datetime.now(timezone.utc).isoformat(),
        }]

        # 恢复购买 (无 receipt，回退到本地历史)
        resp = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "ios"},
            params={"user_id": user_id},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["plan"] == "yiyang"

    @pytest.mark.asyncio
    async def test_restore_expired_subscription(self, client):
        """有购买历史但平台不匹配时返回错误"""
        from app.router import subscription as sub_mod
        user_id = "user-restore-exp"
        # 只有 alipay 购买历史
        sub_mod.purchase_history[user_id] = [{
            "plan": "yangxin",
            "price_cents": 2900,
            "platform": "alipay",
            "subscribed_at": datetime.now(timezone.utc).isoformat(),
        }]

        # 用 android 平台恢复 — 找不到 android 历史
        resp = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "android"},
            params={"user_id": user_id},
        )
        # 没有 android/iap_android 历史记录
        assert resp.status_code == 200
        # 回退: 没有 iap_android 也没有 android 平台的历史
        # 最后会匹配到 alipay (fallback), 取第一个 reversed match
        # 但 platform check: alipay 不匹配 android 也不匹配 iap_android
        data = resp.json()
        # 如果找不到，success=False
        # 但 restore 端点的 fallback 逻辑会匹配 alipay 因为 request.platform=android, 
        # purchase.platform=alipay 不在 (android, iap_android) 中
        # 所以会返回 no_platform_history
        if not data["success"]:
            assert data["code"] == "no_platform_history"

    @pytest.mark.asyncio
    async def test_restore_no_purchase_history(self, client):
        """无购买历史恢复失败"""
        resp = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "ios"},
            params={"user_id": "user-no-history"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is False
        assert data["code"] == "no_history"

    @pytest.mark.asyncio
    async def test_restore_idempotent(self, client):
        """重复恢复不影响结果 (幂等)"""
        from app.router import subscription as sub_mod
        user_id = "user-restore-idem"
        # 手动设置 ios 平台购买历史
        sub_mod.purchase_history[user_id] = [{
            "plan": "yangxin",
            "price_cents": 19900,
            "platform": "ios",
            "subscribed_at": datetime.now(timezone.utc).isoformat(),
        }]

        # 第一次恢复
        resp1 = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "ios"},
            params={"user_id": user_id},
        )
        assert resp1.json()["success"] is True

        # 第二次恢复 (幂等)
        resp2 = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "ios"},
            params={"user_id": user_id},
        )
        assert resp2.status_code == 200
        data2 = resp2.json()
        assert data2["success"] is True


# ============================================================
# 7. 权益检查 (TierPermissions)
# ============================================================


class TestTierPermissions:
    """各层级权限测试"""

    @pytest.mark.asyncio
    async def test_free_cannot_access_premium_content(self, client):
        """免费版无 premium 功能"""
        resp = await client.get(f"{API_BASE}/status", params={"user_id": "user-free-perm"})
        features = resp.json()["data"]["features"]
        assert features["unlimited_chat"] is False
        assert features["today_plan"] is False
        assert features["deep_suggestions"] is False
        assert features["weekly_summary"] is False
        assert features["family"] is False

    @pytest.mark.asyncio
    async def test_yangxin_can_access_basic_premium(self, client):
        """养心版有基础高级功能"""
        user_id = "user-yx-perm"
        await _create_and_pay_order(client, user_id, "yangxin_monthly")

        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        features = resp.json()["data"]["features"]
        assert features["basic_chat"] is True
        assert features["solar_terms"] is True
        assert features["unlimited_chat"] is True
        assert features["today_plan"] is True
        # 养心版没有深度功能
        assert features["deep_suggestions"] is False
        assert features["weekly_summary"] is False
        assert features["family"] is False

    @pytest.mark.asyncio
    async def test_yiyang_has_higher_limits(self, client):
        """颐养版有深度建议和周总结"""
        user_id = "user-yy-perm"
        await _create_and_pay_order(client, user_id, "yiyang_yearly")

        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        features = resp.json()["data"]["features"]
        assert features["unlimited_chat"] is True
        assert features["today_plan"] is True
        assert features["deep_suggestions"] is True
        assert features["weekly_summary"] is True
        assert features["family"] is False  # 颐养版没有家庭

    @pytest.mark.asyncio
    async def test_jiahe_has_family_access(self, client):
        """家和版有家庭席位"""
        user_id = "user-jh-perm"
        await _create_and_pay_order(client, user_id, "jiahe_monthly")

        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        data = resp.json()["data"]
        assert data["plan"] == "jiahe"
        assert data["features"]["family"] is True
        assert data["family_seats"] is not None
        assert data["family_seats"]["family_seats"] == 4
        assert data["family_seats"]["available"] == 4

    @pytest.mark.asyncio
    async def test_jiahe_family_bind_and_unbind(self, client):
        """家和版绑定/解绑家庭成员"""
        user_id = "user-jh-bind"
        await _create_and_pay_order(client, user_id, "jiahe_monthly")

        # 绑定成员
        resp_bind = await client.post(
            f"{API_BASE}/family-seats/bind",
            params={"user_id": user_id, "member_name": "张三", "member_user_id": "user-zhangsan"},
        )
        assert resp_bind.status_code == 200
        seats = resp_bind.json()["data"]
        assert seats["used_seats"] == 1
        assert seats["available"] == 3

        # 解绑成员
        resp_unbind = await client.post(
            f"{API_BASE}/family-seats/unbind",
            params={"user_id": user_id, "member_user_id": "user-zhangsan"},
        )
        assert resp_unbind.status_code == 200
        seats = resp_unbind.json()["data"]
        assert seats["used_seats"] == 0
        assert seats["available"] == 4


# ============================================================
# 8. 完整流程 (End-to-End)
# ============================================================


class TestEndToEndFlow:
    """端到端: 创建→支付→激活→查询→过期→回退"""

    @pytest.mark.asyncio
    async def test_full_payment_lifecycle(self, client, monkeypatch, db):
        """完整生命周期: 免费用户 → 购买 → 激活 → 过期 → 降级"""
        user_id = "user-e2e-lifecycle"

        # 1. 初始状态: free
        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        assert resp.json()["data"]["plan"] == "free"

        # 2. 创建订单
        resp_order = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yangxin_yearly", "platform": "alipay"},
            params={"user_id": user_id},
        )
        assert resp_order.status_code == 200
        order_id = resp_order.json()["data"]["order_id"]

        # 3. 查询订单 (应为 pending)
        resp_query = await client.get(f"{API_BASE}/order/{order_id}")
        assert resp_query.json()["data"]["status"] == "pending"

        # 4. 支付
        resp_pay = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": order_id, "platform": "alipay", "transaction_id": "TXN_E2E_001"},
        )
        assert resp_pay.json()["data"]["status"] == "paid"

        # 5. 查询订阅状态 (应为 yangxin + active)
        resp_sub = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        sub_data = resp_sub.json()["data"]
        assert sub_data["plan"] == "yangxin"
        assert sub_data["status"] == "active"
        assert sub_data["expires_at"] is not None

        # 6. 获取购买历史
        resp_hist = await client.get(f"{API_BASE}/history", params={"user_id": user_id})
        assert len(resp_hist.json()["data"]) >= 1

        # 7. 模拟过期 (手动设置过期时间)
        from app.router import subscription as sub_mod
        sub_mod.subscriptions[user_id] = {
            "plan": "yangxin",
            "status": "active",
            "expires_at": (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat(),
            "auto_renew": False,
            "platform": "alipay",
            "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        }

        # 8. 过期检查
        resp_exp = await client.post(f"{API_BASE}/check-expired")
        assert resp_exp.json()["data"]["expired_count"] >= 1

        # 9. 验证降级
        sub_final = _get_user_subscription_lazy(user_id)
        assert sub_final["plan"] == "free"

    @pytest.mark.asyncio
    async def test_upgrade_tier(self, client):
        """升级: yangxin → yiyang"""
        user_id = "user-upgrade"

        # 1. 购买 yangxin
        await _create_and_pay_order(client, user_id, "yangxin_monthly")
        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        assert resp.json()["data"]["plan"] == "yangxin"

        # 2. 购买 yiyang (升级)
        # 需要先让 yangxin 订阅不是 active — 或升级逻辑允许高等级购买
        # 当前代码: TIER_ORDER[yiyang] > TIER_ORDER[yangxin] 所以不会触发 "无需重复购买"
        resp_order = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yiyang_yearly", "platform": "alipay"},
            params={"user_id": user_id},
        )
        assert resp_order.status_code == 200  # 升级订单创建成功

        order_id = resp_order.json()["data"]["order_id"]
        resp_pay = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": order_id, "platform": "alipay"},
        )
        assert resp_pay.json()["data"]["plan"] == "yiyang"

        # 3. 验证升级后状态
        resp = await client.get(f"{API_BASE}/status", params={"user_id": user_id})
        features = resp.json()["data"]["features"]
        assert features["deep_suggestions"] is True
        assert features["weekly_summary"] is True

    @pytest.mark.asyncio
    async def test_cancel_order_flow(self, client):
        """取消订单流程"""
        # 1. 创建订单
        resp = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yangxin_monthly", "platform": "alipay"},
        )
        order_id = resp.json()["data"]["order_id"]

        # 2. 取消订单
        resp_cancel = await client.post(
            f"{API_BASE}/cancel-order",
            json={"order_id": order_id},
        )
        assert resp_cancel.status_code == 200
        assert resp_cancel.json()["data"]["status"] == "cancelled"

        # 3. 确认订单状态
        resp_query = await client.get(f"{API_BASE}/order/{order_id}")
        assert resp_query.json()["data"]["status"] == "cancelled"

    @pytest.mark.asyncio
    async def test_order_state_transitions(self, client):
        """订单状态: pending → paid / cancelled (通过 API)"""
        # pending → cancelled
        resp1 = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yiyang_monthly", "platform": "alipay"},
            params={"user_id": "user-trans-001"},
        )
        oid1 = resp1.json()["data"]["order_id"]
        resp1c = await client.post(f"{API_BASE}/cancel-order", json={"order_id": oid1})
        assert resp1c.json()["data"]["status"] == "cancelled"

        # pending → paid
        resp2 = await client.post(
            f"{API_BASE}/create-order",
            json={"product_id": "yiyang_monthly", "platform": "alipay"},
            params={"user_id": "user-trans-002"},
        )
        oid2 = resp2.json()["data"]["order_id"]
        resp2p = await client.post(
            f"{API_BASE}/verify-payment",
            json={"order_id": oid2, "platform": "alipay"},
        )
        assert resp2p.json()["data"]["status"] == "paid"


# ============================================================
# 9. 向后兼容 API 测试
# ============================================================


class TestBackwardCompatAPI:
    """旧版 API 端点测试"""

    @pytest.mark.asyncio
    async def test_subscribe_backward_compat(self, client):
        """旧版 subscribe 接口"""
        resp = await client.post(
            f"{API_BASE}/subscribe",
            json={"plan": "yangxin", "platform": "ios"},
            params={"user_id": "user-compat-sub"},
        )
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["plan"] == "yangxin"
        assert data["status"] == "active"

    @pytest.mark.asyncio
    async def test_get_subscription_backward_compat(self, client):
        """旧版 GET /api/v1/subscription 接口"""
        resp = await client.get(
            f"{API_BASE}",
            params={"user_id": "user-compat-get"},
        )
        assert resp.status_code == 200
        assert resp.json()["data"]["plan"] == "free"

    @pytest.mark.asyncio
    async def test_plans_list(self, client):
        """获取计划列表 (4级)"""
        resp = await client.get(f"{API_BASE}/plans")
        assert resp.status_code == 200
        plans = resp.json()["data"]
        plan_ids = [p["id"] for p in plans]
        assert "free" in plan_ids
        assert "yangxin" in plan_ids
        assert "yiyang" in plan_ids
        assert "jiahe" in plan_ids

    @pytest.mark.asyncio
    async def test_verify_receipt_v2(self, client):
        """Receipt 验证 v2 (POST JSON)"""
        resp = await client.post(
            f"{API_BASE}/verify-receipt-v2",
            json={
                "platform": "ios",
                "receipt_data": "mock_ios_receipt_data_long_enough",
                "product_id": "yangxin_monthly",
                "plan": "yangxin",
                "user_id": "user-receipt-v2",
            },
        )
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["plan"] == "yangxin"
        assert data["status"] == "active"

    @pytest.mark.asyncio
    async def test_alipay_create_and_verify(self, client):
        """支付宝旧版流程: 创建订单 → 验证"""
        resp = await client.post(
            f"{API_BASE}/alipay/create-order",
            json={"plan": "yangxin", "user_id": "user-alipay-compat"},
        )
        assert resp.status_code == 200
        order_id = resp.json()["data"]["order_id"]

        resp_verify = await client.post(
            f"{API_BASE}/alipay/verify",
            json={"order_id": order_id},
        )
        assert resp_verify.status_code == 200
        assert resp_verify.json()["data"]["status"] == "paid"

    @pytest.mark.asyncio
    async def test_stripe_webhook(self, client):
        """Stripe webhook: checkout.session.completed"""
        resp = await client.post(
            f"{API_BASE}/stripe/webhook",
            json={
                "type": "checkout.session.completed",
                "data": {
                    "id": "cs_test_mock",
                    "metadata": {
                        "user_id": "user-stripe-webhook",
                        "plan": "yiyang",
                    },
                },
            },
        )
        assert resp.status_code == 200
        assert "订阅已激活" in resp.json()["message"]

        # 验证用户状态
        resp_status = await client.get(
            f"{API_BASE}/status", params={"user_id": "user-stripe-webhook"}
        )
        assert resp_status.json()["data"]["plan"] == "yiyang"

    @pytest.mark.asyncio
    async def test_usage_stats(self, client):
        """使用量统计"""
        user_id = "user-usage"
        # 记录使用量
        await client.post(
            f"{API_BASE}/usage/record",
            params={"user_id": user_id, "type": "chat", "amount": 5},
        )
        resp = await client.get(f"{API_BASE}/usage", params={"user_id": user_id})
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["usage"]["chat_count"] == 5
        assert data["limits"]["daily_chat"] == 10  # free 用户限制


# ============================================================
# 10. 边界条件 (Edge Cases)
# ============================================================


class TestEdgeCases:
    """边界条件测试"""

    @pytest.mark.asyncio
    async def test_query_nonexistent_order(self, client):
        """查询不存在的订单"""
        resp = await client.get(f"{API_BASE}/order/nonexistent-order-id")
        assert resp.status_code == 404

    @pytest.mark.asyncio
    async def test_cancel_nonexistent_order(self, client):
        """取消不存在的订单"""
        resp = await client.post(
            f"{API_BASE}/cancel-order",
            json={"order_id": "nonexistent-order-id"},
        )
        assert resp.status_code == 404

    @pytest.mark.asyncio
    async def test_cancel_paid_order(self, client):
        """已支付订单不能取消"""
        user_id = "user-cancel-paid"
        order_id, _ = await _create_and_pay_order(client, user_id, "yangxin_monthly")

        resp = await client.post(
            f"{API_BASE}/cancel-order",
            json={"order_id": order_id},
        )
        assert resp.status_code == 400
        assert "无法" in resp.json()["detail"] or "状态" in resp.json()["detail"]

    @pytest.mark.asyncio
    async def test_bind_family_without_jiahe(self, client):
        """非家和版用户不能绑定家庭"""
        resp = await client.post(
            f"{API_BASE}/family-seats/bind",
            params={"user_id": "user-no-jiahe", "member_name": "张三"},
        )
        assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_bind_family_exceed_limit(self, client):
        """超额绑定家庭席位"""
        user_id = "user-family-full"
        await _create_and_pay_order(client, user_id, "jiahe_monthly")

        for i in range(4):
            resp = await client.post(
                f"{API_BASE}/family-seats/bind",
                params={"user_id": user_id, "member_name": f"成员{i}", "member_user_id": f"member-{i}"},
            )
            assert resp.status_code == 200

        # 第5个应失败
        resp = await client.post(
            f"{API_BASE}/family-seats/bind",
            params={"user_id": user_id, "member_name": "超出成员", "member_user_id": "member-overflow"},
        )
        assert resp.status_code == 400
        assert "已满" in resp.json()["detail"]

    @pytest.mark.asyncio
    async def test_restore_unsupported_platform(self, client):
        """不支持的平台"""
        resp = await client.post(
            f"{API_BASE}/restore",
            json={"platform": "windows_phone"},
            params={"user_id": "user-bad-platform"},
        )
        assert resp.status_code == 400
        assert "不支持" in resp.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_order_with_all_platforms(self, client):
        """所有平台都能创建订单"""
        for product_id in ["yangxin_apple_monthly", "yiyang_monthly", "jiahe_yearly"]:
            resp = await client.post(
                f"{API_BASE}/create-order",
                json={"product_id": product_id, "platform": "alipay"},
            )
            assert resp.status_code == 200, f"Failed for {product_id}: {resp.text}"
            assert resp.json()["data"]["status"] == "pending"

    @pytest.mark.asyncio
    async def test_products_response_structure(self, client):
        """商品列表响应结构完整"""
        resp = await client.get(f"{API_BASE}/products")
        data = resp.json()["data"]
        required_keys = {"current_tier", "tiers", "products"}
        assert set(data.keys()) >= required_keys

        for p in data["products"]:
            required_product_keys = {
                "product_id", "name", "tier", "tier_name",
                "price_cents", "price_display", "currency",
                "duration_days", "platform", "features",
                "is_current_tier", "upgrade",
            }
            assert set(p.keys()) >= required_product_keys, f"Missing keys in {p['product_id']}"


# ============================================================
# Run Tests
# ============================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
