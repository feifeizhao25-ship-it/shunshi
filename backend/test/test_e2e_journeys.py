"""
E2E 端到端测试 — 覆盖关键用户旅程

旅程:
  1. 新用户首用: 游客注册 → 绑定手机 → 浏览首页 → 内容库 → 发送消息
  2. 会员购买: 查看计划 → 创建订单 → 模拟支付 → 访问付费内容
  3. 节气: 当前节气 → 节气详情 → 节气内容推荐
  4. 体质测试: 获取问卷 → 提交答案 → 获取结果
  5. 危机场景: 危机输入返回热线 → 不调用LLM

运行:
  cd ~/Documents/Shunshi/backend && source .venv/bin/activate
  pytest test/test_e2e_journeys.py -v
"""

import os
import sys
import json
import time
import sqlite3
import pytest
import pytest_asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from datetime import datetime, timedelta, timezone
from contextlib import asynccontextmanager

# 确保项目根目录在 path 中
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from httpx import AsyncClient, ASGITransport
from fastapi import FastAPI

# 导入所有需要注册的路由模块
from app.router import (
    auth, chat, contents, family, notifications, solar_terms,
    subscription, today_plan, records, settings,
    constitution, content_cms, cards, recommendations,
    skills,
)
from app.router.stripe import router as stripe_router
from app.router.lifecycle import router as lifecycle_router
from app.router.memory import router as memory_router
from app.router.followup import router as followup_router
from app.router.push import router as push_router
from app.router.audit import router as audit_router
from app.safety.router import router as safety_router
from app.feature_flags.router import router as flag_router
from app.prompts.router import router as prompt_router
from app.alerts.router import router as alert_router
from app.rag.router import router as rag_router

# ============================================================
# Fixtures
# ============================================================


@pytest.fixture(autouse=True)
def _reset_module_state():
    """
    每个测试前重置各模块的内存状态,
    避免测试之间互相污染。

    注意: subscription 模块不做 autouse 重置,
    因 TestSubscriptionJourney 需要跨测试共享订单状态。
    """
    from app.router import chat as chat_mod
    chat_mod.conversations_db.clear()

    # SMS codes / rate limits
    from app.router import auth as auth_mod
    if hasattr(auth_mod, "_sms_codes"):
        auth_mod._sms_codes.clear()
    if hasattr(auth_mod, "_sms_rate_limit"):
        auth_mod._sms_rate_limit.clear()

    yield


@pytest.fixture()
def db():
    """创建内存 SQLite (测试用)"""
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    # 创建必要表
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            phone TEXT,
            life_stage TEXT DEFAULT 'exploration',
            auth_provider TEXT DEFAULT 'guest',
            status TEXT DEFAULT 'active',
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS auth_tokens (
            token TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            device_id TEXT,
            jti TEXT,
            type TEXT DEFAULT 'access',
            expires_at TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS conversations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS contents (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            type TEXT,
            category TEXT,
            tags TEXT DEFAULT '[]',
            locale TEXT DEFAULT 'zh-CN',
            difficulty TEXT,
            duration TEXT,
            ingredients TEXT DEFAULT '[]',
            steps TEXT DEFAULT '[]',
            location TEXT,
            method TEXT,
            effect TEXT,
            benefits TEXT DEFAULT '[]',
            best_time TEXT,
            season_tag TEXT,
            view_count INTEGER DEFAULT 0,
            like_count INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS follow_ups (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            status TEXT DEFAULT 'pending',
            created_at TEXT DEFAULT (datetime('now'))
        );
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
        CREATE TABLE IF NOT EXISTS constitution_results (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            version TEXT DEFAULT 'v1',
            answers TEXT NOT NULL DEFAULT '[]',
            scores TEXT NOT NULL DEFAULT '{}',
            primary_type TEXT NOT NULL,
            secondary_types TEXT NOT NULL DEFAULT '[]',
            advice TEXT NOT NULL DEFAULT '',
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS feature_flags (
            key TEXT PRIMARY KEY,
            value_type TEXT NOT NULL,
            value_default TEXT NOT NULL,
            rollout_pct REAL DEFAULT 100.0,
            user_whitelist TEXT DEFAULT '[]',
            description TEXT DEFAULT '',
            category TEXT DEFAULT 'general',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS flag_evaluations (
            id TEXT PRIMARY KEY,
            flag_key TEXT NOT NULL,
            user_id TEXT,
            result TEXT NOT NULL,
            evaluated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS prompt_versions (
            id TEXT PRIMARY KEY,
            prompt_key TEXT NOT NULL,
            version INTEGER NOT NULL,
            content TEXT NOT NULL,
            changelog TEXT DEFAULT '',
            category TEXT DEFAULT 'general',
            is_active INTEGER DEFAULT 0,
            created_by TEXT,
            created_at TEXT NOT NULL,
            UNIQUE(prompt_key, version)
        );
        CREATE TABLE IF NOT EXISTS llm_audit_log (
            id TEXT PRIMARY KEY,
            timestamp TEXT DEFAULT (datetime('now')),
            model TEXT,
            user_id TEXT,
            input_tokens INTEGER DEFAULT 0,
            output_tokens INTEGER DEFAULT 0,
            latency_ms INTEGER DEFAULT 0,
            status TEXT DEFAULT 'ok',
            error TEXT
        );
        CREATE TABLE IF NOT EXISTS alerts (
            id TEXT PRIMARY KEY,
            rule TEXT,
            severity TEXT,
            message TEXT,
            data TEXT DEFAULT '{}',
            sent INTEGER DEFAULT 0,
            channel TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS alert_rules (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE NOT NULL,
            enabled INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS alert_logs (
            id TEXT PRIMARY KEY,
            alert_id TEXT NOT NULL,
            level TEXT NOT NULL,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT DEFAULT '',
            context TEXT DEFAULT '{}',
            sent INTEGER DEFAULT 0,
            channel TEXT DEFAULT '',
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS safety_audit_log (
            id TEXT PRIMARY KEY,
            timestamp TEXT DEFAULT (datetime('now')),
            user_id TEXT,
            level TEXT,
            flag TEXT,
            reason TEXT,
            detection_rules TEXT DEFAULT '[]'
        );
        CREATE TABLE IF NOT EXISTS safety_audit_logs (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            level TEXT NOT NULL,
            content_hash TEXT,
            detection_rules TEXT DEFAULT '[]',
            action_taken TEXT,
            model_used TEXT,
            latency_ms REAL,
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS knowledge_bases (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            source_type TEXT DEFAULT 'file',
            source_path TEXT,
            enabled INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS push_tokens (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            platform TEXT DEFAULT 'ios',
            token TEXT NOT NULL,
            device_id TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS memory_entries (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            category TEXT DEFAULT 'general',
            content TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS user_devices (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            platform TEXT DEFAULT 'unknown',
            device_name TEXT,
            last_active_at TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT,
            UNIQUE(user_id, device_id)
        );
    """)
    conn.commit()
    return conn


@pytest.fixture()
def mock_db(db, monkeypatch):
    """用内存 DB 替换 get_db — 覆盖所有导入点"""
    from app.database import db as db_mod

    # 覆盖底层连接函数 (所有 get_db 调用都会走这里)
    monkeypatch.setattr(db_mod, "_get_connection", lambda: db)
    return db


def _create_test_app(db_conn):
    """
    创建轻量 FastAPI app, 注册所有路由, 跳过重初始化。
    数据库已在 db fixture 中建好表。
    """
    # 用空 lifespan 避免 init_db / load_knowledge_bases 等开销
    @asynccontextmanager
    async def _empty_lifespan(app: FastAPI):
        yield

    test_app = FastAPI(
        title="E2E Test App",
        version="test",
        lifespan=_empty_lifespan,
    )

    # 按照和 main.py 相同的方式注册路由
    test_app.include_router(auth.router)
    test_app.include_router(contents.router)
    test_app.include_router(family.router)
    test_app.include_router(solar_terms.router)
    test_app.include_router(subscription.router)
    test_app.include_router(notifications.router)
    test_app.include_router(records.router)
    test_app.include_router(settings.router)
    test_app.include_router(today_plan.router)
    test_app.include_router(chat.router)
    test_app.include_router(lifecycle_router)
    test_app.include_router(memory_router)
    test_app.include_router(followup_router)
    test_app.include_router(skills.router, prefix="/api/v1/skills")
    test_app.include_router(constitution.router, prefix="/api/v1/constitution")
    test_app.include_router(content_cms.router, prefix="/api/v1/cms")
    test_app.include_router(cards.router)
    test_app.include_router(recommendations.router)
    test_app.include_router(stripe_router)
    test_app.include_router(rag_router)
    test_app.include_router(push_router)
    test_app.include_router(audit_router)
    test_app.include_router(safety_router)
    test_app.include_router(flag_router, prefix="/api/v1/flags")
    test_app.include_router(prompt_router)
    test_app.include_router(alert_router)

    return test_app


@pytest_asyncio.fixture(loop_scope="function")
async def client(mock_db):
    """创建异步测试客户端"""
    # 清理 thread-local 缓存的连接, 强制使用 mock 的 _get_connection
    from app.database import db as db_mod
    if hasattr(db_mod._local, "connection"):
        db_mod._local.connection = None

    test_app = _create_test_app(mock_db)

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac


# ============================================================
# 辅助
# ============================================================

MOCK_LLM_RESPONSE = {
    "choices": [
        {
            "message": {"role": "assistant", "content": "这是AI的养生建议回复。"},
            "finish_reason": "stop",
        }
    ],
    "usage": {"prompt_tokens": 50, "completion_tokens": 80, "total_tokens": 130},
}


def _mock_siliconflow_chat(*args, **kwargs):
    """创建 mock 的 SiliconFlow.chat 返回值"""
    return MOCK_LLM_RESPONSE


async def _async_mock_chat(*args, **kwargs):
    return MOCK_LLM_RESPONSE


# ============================================================
# 1. 新用户首用旅程
# ============================================================


class TestNewUserJourney:
    """新用户从游客到正式用户的完整旅程"""

    @pytest.mark.asyncio
    async def test_guest_register(self, client: AsyncClient):
        """游客注册 → 获取token → 查看首页"""
        resp = await client.post(
            "/api/v1/auth/guest-login",
            json={
                "platform": "ios",
                "device_id": "test-device-001",
                "device_name": "iPhone 15 Pro",
            },
        )
        assert resp.status_code == 200, f"游客注册失败: {resp.text}"
        data = resp.json()["data"]
        # token 字段名可能是 "token" 或 "access_token"
        token = data.get("token") or data.get("access_token")
        assert token, f"缺少 token, data keys: {list(data.keys())}"
        assert "refresh_token" in data, "缺少 refresh_token"
        assert "user" in data or "user_id" in data, "缺少 user/user_id"
        user_id = (data.get("user") or {}).get("id") or data.get("user_id")
        assert user_id and user_id.startswith("guest_"), f"user_id 格式不对: {user_id}"
        # 保存 token 供后续测试使用
        TestNewUserJourney._token = token
        TestNewUserJourney._user_id = user_id

    @pytest.mark.asyncio
    async def test_guest_to_sms_conversion(self, client: AsyncClient):
        """游客 → 发送验证码 → 验证 → 绑定手机"""
        token = getattr(TestNewUserJourney, "_token", None)
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        phone = "13800138001"

        # Step 1: 发送验证码
        resp = await client.post(
            "/api/v1/auth/sms/send",
            json={"phone": phone},
            headers=headers,
        )
        assert resp.status_code == 200, f"发送验证码失败: {resp.text}"
        assert resp.json()["success"] is True
        # 开发环境返回验证码
        code = resp.json().get("_debug_code")
        if not code:
            # 如果是生产环境, 需要手动 mock
            from app.router.auth import _sms_codes
            if phone in _sms_codes:
                code = _sms_codes[phone]["code"]

        # Step 2: 验证验证码
        if code:
            resp = await client.post(
                "/api/v1/auth/sms/verify",
                json={"phone": phone, "code": code},
                headers=headers,
            )
            assert resp.status_code == 200, f"验证码校验失败: {resp.text}"
            assert resp.json()["success"] is True

    @pytest.mark.asyncio
    async def test_view_home_dashboard(self, client: AsyncClient):
        """查看首页dashboard — 订阅状态 + 节气 + 推荐内容"""
        token = getattr(TestNewUserJourney, "_token", None)
        user_id = getattr(TestNewUserJourney, "_user_id", "user-001")
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        # 查看订阅状态 (免费用户首页信息)
        resp = await client.get(
            "/api/v1/subscription/status",
            params={"user_id": user_id},
            headers=headers,
        )
        assert resp.status_code == 200, f"获取订阅状态失败: {resp.text}"
        data = resp.json()["data"]
        assert data["plan"] == "free", f"新用户应该是 free: {data['plan']}"

        # 查看当前节气 (首页展示)
        resp = await client.get("/api/v1/solar-terms/current")
        assert resp.status_code == 200, f"获取当前节气失败: {resp.text}"
        st_data = resp.json()["data"]
        assert "name" in st_data, "节气数据缺少 name"
        assert "suggestions" in st_data, "节气数据缺少 suggestions"

    @pytest.mark.asyncio
    async def test_view_content_library(self, client: AsyncClient):
        """浏览内容库"""
        # 获取内容类型
        resp = await client.get("/api/v1/contents/types")
        assert resp.status_code == 200, f"获取内容类型失败: {resp.text}"
        types = resp.json()["data"]
        assert isinstance(types, list) and len(types) >= 1, "内容类型列表为空"

        # 获取内容列表
        resp = await client.get(
            "/api/v1/contents",
            params={"page": 1, "limit": 10},
        )
        assert resp.status_code == 200, f"获取内容列表失败: {resp.text}"
        data = resp.json()["data"]
        assert "items" in data, "内容列表缺少 items"
        assert "total" in data, "内容列表缺少 total"
        assert isinstance(data["items"], list)

        # 搜索内容
        resp = await client.get(
            "/api/v1/contents/search",
            params={"q": "养生", "limit": 5},
        )
        assert resp.status_code == 200, f"搜索内容失败: {resp.text}"
        search_data = resp.json()["data"]
        assert "items" in search_data

    @patch("app.llm.siliconflow.SiliconFlowClient.chat_completion", new_callable=AsyncMock)
    @pytest.mark.asyncio
    async def test_chat_first_message(self, mock_chat, client: AsyncClient):
        """发送第一条AI消息"""
        mock_chat.return_value = MOCK_LLM_RESPONSE

        resp = await client.post(
            "/api/v1/chat",
            params={
                "message": "我最近总是失眠，有什么养生建议吗？",
                "user_id": "user-e2e-001",
            },
        )
        assert resp.status_code == 200, f"发送消息失败: {resp.text}"
        data = resp.json()["data"]
        assert "text" in data, "AI回复缺少 text"
        assert "message_id" in data, "缺少 message_id"
        assert "conversation_id" in data, "缺少 conversation_id"
        assert len(data["text"]) > 0, "AI回复为空"

        # 验证 mock 被调用 (非危机场景应调用LLM)
        mock_chat.assert_called_once()


# ============================================================
# 2. 会员购买旅程
# ============================================================


class TestSubscriptionJourney:
    """会员购买完整旅程: 浏览计划 → 创建订单 → 支付 → 权益激活"""

    @pytest.fixture(autouse=True)
    def reset_subscription_state(self):
        """仅在第一个测试前重置订阅状态 (确保干净起点)"""
        from app.router import subscription as sub_mod
        # 每个测试前: 仅在第一次时重置
        if not hasattr(TestSubscriptionJourney, "_state_reset"):
            sub_mod.subscriptions.clear()
            sub_mod.purchase_history.clear()
            sub_mod.payment_orders.clear()
            sub_mod.usage_stats.clear()
            sub_mod.family_seats.clear()
            sub_mod.audit_log.clear()
            TestSubscriptionJourney._state_reset = True
        yield

    @pytest.mark.asyncio
    async def test_view_plans(self, client: AsyncClient):
        """查看会员计划"""
        resp = await client.get("/api/v1/subscription/plans")
        assert resp.status_code == 200, f"获取计划列表失败: {resp.text}"
        plans = resp.json()["data"]
        assert isinstance(plans, list), "plans 应该是列表"
        assert len(plans) >= 4, f"至少4个计划, 实际: {len(plans)}"

        plan_ids = [p["id"] for p in plans]
        assert "free" in plan_ids, "缺少 free 计划"
        assert "yangxin" in plan_ids, "缺少 yangxin 计划"
        assert "yiyang" in plan_ids, "缺少 yiyang 计划"
        assert "jiahe" in plan_ids, "缺少 jiahe 计划"

        # 检查每个计划有 features
        for plan in plans:
            assert "features" in plan, f"{plan['id']} 缺少 features"
            assert "price" in plan, f"{plan['id']} 缺少 price"

        # 查看商品列表 (SKU)
        resp = await client.get("/api/v1/subscription/products")
        assert resp.status_code == 200, f"获取商品列表失败: {resp.text}"
        products = resp.json()["data"]["products"]
        assert len(products) >= 6, f"至少6个SKU, 实际: {len(products)}"

    @pytest.mark.asyncio
    async def test_create_order(self, client: AsyncClient):
        """创建订单"""
        resp = await client.post(
            "/api/v1/subscription/create-order",
            json={
                "product_id": "yiyang_monthly",
                "platform": "alipay",
            },
            params={"user_id": "user-e2e-sub"},
        )
        assert resp.status_code == 200, f"创建订单失败: {resp.text}"
        data = resp.json()["data"]
        assert "order_id" in data, "缺少 order_id"
        assert data["status"] == "pending", f"订单状态应为 pending: {data['status']}"
        assert data["amount_cents"] == 5900, f"颐养版月付应为 5900 分: {data['amount_cents']}"

        # 保存 order_id
        TestSubscriptionJourney._order_id = data["order_id"]

    @pytest.mark.asyncio
    async def test_verify_payment(self, client: AsyncClient):
        """验证支付（模拟）"""
        order_id = getattr(TestSubscriptionJourney, "_order_id", None)
        assert order_id is not None, "缺少 order_id, 请先运行 test_create_order"

        resp = await client.post(
            "/api/v1/subscription/verify-payment",
            json={
                "order_id": order_id,
                "platform": "alipay",
                "transaction_id": "MOCK_TXN_001",
            },
        )
        assert resp.status_code == 200, f"支付验证失败: {resp.text}"
        data = resp.json()["data"]
        assert data["status"] == "paid", f"支付状态应为 paid: {data['status']}"
        assert "subscription" in data, "缺少 subscription 信息"
        assert data["subscription"]["plan"] == "yiyang", "订阅计划应为 yiyang"
        assert data["subscription"]["status"] == "active", "订阅应已激活"

        # 验证订阅状态
        resp = await client.get(
            "/api/v1/subscription/status",
            params={"user_id": "user-e2e-sub"},
        )
        assert resp.status_code == 200
        status = resp.json()["data"]
        assert status["plan"] == "yiyang"

    @pytest.mark.asyncio
    async def test_premium_content_access(self, client: AsyncClient):
        """付费用户访问高级内容 — 推荐系统"""
        # 免费用户也可以访问推荐, 但付费用户有更多权益
        resp = await client.get(
            "/api/v1/contents/recommend",
            params={"user_id": "user-e2e-sub", "limit": 5},
        )
        assert resp.status_code == 200, f"获取推荐内容失败: {resp.text}"
        data = resp.json()["data"]
        assert "items" in data
        assert "season" in data

        # 检查使用量 (付费用户应 unlimited)
        resp = await client.get(
            "/api/v1/subscription/usage",
            params={"user_id": "user-e2e-sub"},
        )
        assert resp.status_code == 200
        usage = resp.json()["data"]
        assert usage["limits"]["daily_chat"] == "unlimited", "付费用户应有无限聊天"
        assert usage["limits"]["daily_api"] == "unlimited", "付费用户应有无限API"


# ============================================================
# 3. 节气旅程
# ============================================================


class TestSolarTermJourney:
    """节气相关API旅程"""

    @pytest.mark.asyncio
    async def test_get_current_term(self, client: AsyncClient):
        """获取当前节气"""
        resp = await client.get("/api/v1/solar-terms/current")
        assert resp.status_code == 200, f"获取当前节气失败: {resp.text}"
        data = resp.json()["data"]
        assert "name" in data, "缺少 name"
        assert "emoji" in data, "缺少 emoji"
        assert "description" in data, "缺少 description"
        assert "foods" in data, "缺少 foods"
        assert "exercises" in data, "缺少 exercises"
        assert "suggestions" in data, "缺少 suggestions"
        assert "activities" in data, "缺少 activities"
        assert "start_date" in data, "缺少 start_date"
        assert "end_date" in data, "缺少 end_date"

        # 保存当前节气名供后续测试使用
        TestSolarTermJourney._current_name = data["name"]

    @pytest.mark.asyncio
    async def test_get_term_detail(self, client: AsyncClient):
        """获取节气详情"""
        # 用一个已知节气名测试
        term_name = getattr(TestSolarTermJourney, "_current_name", "立春")
        resp = await client.get(f"/api/v1/solar-terms/{term_name}")
        assert resp.status_code == 200, f"获取节气详情失败: {resp.text}"
        data = resp.json()["data"]
        assert data["name"] == term_name, f"节气名不匹配: {data['name']} != {term_name}"
        assert isinstance(data["suggestions"], list) and len(data["suggestions"]) > 0
        assert isinstance(data["foods"], list) and len(data["foods"]) > 0

        # 测试英文本地化
        resp = await client.get(
            f"/api/v1/solar-terms/{term_name}",
            params={"locale": "en-US"},
        )
        assert resp.status_code == 200
        en_data = resp.json()["data"]
        assert "en_description" not in en_data or "description" in en_data

    @pytest.mark.asyncio
    async def test_term_content_recommendations(self, client: AsyncClient):
        """节气内容推荐 + 今日节气信息"""
        # 今日节气 (含前后节气 + 7日建议)
        resp = await client.get("/api/v1/solar-terms/today")
        assert resp.status_code == 200, f"获取今日节气失败: {resp.text}"
        data = resp.json()["data"]
        assert "current" in data, "缺少 current"
        assert "previous" in data, "缺少 previous"
        assert "next" in data, "缺少 next"
        assert "seven_day_suggestions" in data, "缺少 seven_day_suggestions"

        suggestions = data["seven_day_suggestions"]
        assert isinstance(suggestions, list) and len(suggestions) == 7

        # 获取即将到来的节气
        resp = await client.get("/api/v1/solar-terms/upcoming")
        assert resp.status_code == 200, f"获取即将到来的节气失败: {resp.text}"
        upcoming = resp.json()["data"]
        assert "items" in upcoming, "缺少 items"
        assert "now" in upcoming, "缺少 now"

        # 节气通知
        resp = await client.get("/api/v1/solar-terms/notifications")
        assert resp.status_code == 200
        notifs = resp.json()["data"]
        assert "notifications" in notifs
        assert "has_immediate" in notifs

        # 增强版当前节气
        resp = await client.get("/api/v1/solar-terms/enhanced/current")
        assert resp.status_code == 200

        # 增强版所有节气
        resp = await client.get("/api/v1/solar-terms/enhanced/all")
        assert resp.status_code == 200
        all_data = resp.json()["data"]
        assert "terms" in all_data
        assert all_data["total"] == 24, f"应有24个节气, 实际: {all_data['total']}"


# ============================================================
# 4. 体质测试旅程
# ============================================================


class TestConstitutionJourney:
    """体质辨识完整旅程"""

    @pytest.mark.asyncio
    async def test_get_questions(self, client: AsyncClient):
        """获取体质问卷"""
        resp = await client.get("/api/v1/constitution/questions")
        assert resp.status_code == 200, f"获取问卷失败: {resp.text}"
        questions = resp.json()
        assert isinstance(questions, list), "问卷应为列表"
        assert len(questions) == 25, f"应有25道题目, 实际: {len(questions)}"

        # 检查每题结构
        q0 = questions[0]
        assert "id" in q0, "题目缺少 id"
        assert "question" in q0, "题目缺少 question"
        assert "options" in q0, "题目缺少 options"
        assert isinstance(q0["options"], list) and len(q0["options"]) == 3

    @pytest.mark.asyncio
    async def test_submit_and_get_result(self, client: AsyncClient):
        """提交答案 → 获取结果"""
        # 构造测试答案: 每题选第一项 (偏平和质)
        answers = [{"question_id": q_id, "option_index": 0} for q_id in range(1, 26)]

        # Step 1: 提交答案
        resp = await client.post(
            "/api/v1/constitution/submit",
            json={
                "user_id": "user-e2e-constitution",
                "answers": answers,
            },
        )
        assert resp.status_code == 200, f"提交答案失败: {resp.text}"
        data = resp.json()
        assert "result_id" in data, "缺少 result_id"
        assert "primary_type" in data, "缺少 primary_type"
        assert "primary_name" in data, "缺少 primary_name"
        assert "scores" in data, "缺少 scores"
        assert "advice" in data, "缺少 advice"
        assert len(data["advice"]) > 0, "养生建议为空"

        # scores 应有9种体质
        assert len(data["scores"]) == 9, f"应有9种体质分数, 实际: {len(data['scores'])}"

        # Step 2: 获取体质结果
        user_id = "user-e2e-constitution"
        resp = await client.get(f"/api/v1/constitution/result/{user_id}")
        assert resp.status_code == 200, f"获取体质结果失败: {resp.text}"
        result = resp.json()
        assert result["user_id"] == user_id
        assert "primary_type" in result
        assert "primary_name" in result
        assert "scores" in result
        assert "created_at" in result

        # 查看体质类型列表
        resp = await client.get("/api/v1/constitution/types")
        assert resp.status_code == 200
        types = resp.json()
        assert isinstance(types, list) and len(types) == 9

        # 查看某个体质详情
        resp = await client.get("/api/v1/constitution/types/pinghe")
        assert resp.status_code == 200
        detail = resp.json()
        assert detail["type"] == "pinghe"
        assert "characteristics" in detail
        assert "diet_advice" in detail


# ============================================================
# 5. 危机场景旅程
# ============================================================


class TestCrisisJourney:
    """危机场景: 安全过滤应拦截并返回热线, 不调用LLM"""

    @pytest.mark.asyncio
    async def test_crisis_input_returns_hotline(self, client: AsyncClient):
        """危机输入返回热线信息"""
        # 使用明确的危机关键词
        crisis_messages = [
            "我想自杀",
            "不想活了，太痛苦了",
        ]

        for msg in crisis_messages:
            resp = await client.post(
                "/api/v1/chat",
                params={"message": msg, "user_id": "user-crisis-test"},
            )
            assert resp.status_code == 200, f"危机消息应返回200: {resp.text}"
            data = resp.json()["data"]

            # 应标记为危机
            assert data.get("safety_flag") == "crisis", (
                f"消息 '{msg}' 应标记为 crisis, 实际: {data.get('safety_flag')}"
            )
            # 回复中应包含热线信息
            text = data.get("text", "")
            assert "400" in text or "热线" in text or "电话" in text or "心理援助" in text, (
                f"危机回复应包含热线信息, 实际: {text[:100]}"
            )

    @patch("app.llm.siliconflow.SiliconFlowClient.chat_completion", new_callable=AsyncMock)
    @pytest.mark.asyncio
    async def test_crisis_does_not_call_llm(self, mock_chat, client: AsyncClient):
        """危机场景不调用LLM（快速响应）"""
        mock_chat.return_value = MOCK_LLM_RESPONSE

        resp = await client.post(
            "/api/v1/chat",
            params={
                "message": "我真的想死，活不下去了",
                "user_id": "user-crisis-no-llm",
            },
        )
        assert resp.status_code == 200, f"请求失败: {resp.text}"
        data = resp.json()["data"]

        # 确认是危机
        assert data.get("safety_flag") == "crisis" or data.get("care_status") == "crisis"

        # LLM 不应被调用
        mock_chat.assert_not_called()
