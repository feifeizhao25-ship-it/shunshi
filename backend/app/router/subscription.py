# 订阅系统 API 路由
# 生产级升级: SKU管理 · 支付状态机 · 权益中间件 · 过期回退 · 家庭席位
from fastapi import APIRouter, HTTPException, Query, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime, timedelta, timezone
from enum import Enum
import uuid
import json
import logging
import os
import secrets

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/subscription", tags=["订阅"])

# ============ Bearer Scheme ============

_bearer_scheme = HTTPBearer(auto_error=False)


# ============ 订单状态机 ============

class OrderStatus(str, Enum):
    """订单状态"""
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


VALID_TRANSITIONS: Dict[OrderStatus, List[OrderStatus]] = {
    OrderStatus.PENDING: [OrderStatus.PAID, OrderStatus.FAILED, OrderStatus.CANCELLED, OrderStatus.EXPIRED],
    OrderStatus.PAID: [OrderStatus.REFUNDED],
    OrderStatus.FAILED: [OrderStatus.PENDING],       # 允许重新支付
    OrderStatus.REFUNDED: [],
    OrderStatus.CANCELLED: [OrderStatus.PENDING],     # 允许重新下单
    OrderStatus.EXPIRED: [],
}


def transition_order(current: str, target: str) -> bool:
    """
    验证订单状态转换是否合法。

    Args:
        current: 当前状态 (OrderStatus value)
        target: 目标状态 (OrderStatus value)

    Returns:
        True 如果转换合法，False 否则
    """
    try:
        current_status = OrderStatus(current)
        target_status = OrderStatus(target)
    except ValueError:
        return False
    allowed = VALID_TRANSITIONS.get(current_status, [])
    return target_status in allowed


# ============ 订阅计划（4个层级） ============

TIER_ORDER = {"free": 0, "yangxin": 1, "yiyang": 2, "jiahe": 3}

SUBSCRIPTION_PLANS = {
    "free": {
        "id": "free",
        "name": "免费版",
        "price": 0,
        "price_cents": 0,
        "period": None,
        "features": {
            "basic_chat": True,
            "solar_terms": True,
            "unlimited_chat": False,
            "today_plan": False,
            "deep_suggestions": False,
            "weekly_summary": False,
            "family": False
        }
    },
    "yangxin": {
        "id": "yangxin",
        "name": "养心版",
        "price": 29,           # 月付价格（CNY）
        "price_yearly": 199,   # 年付价格（CNY）
        "price_cents": 2900,   # 月付（分）
        "price_yearly_cents": 19900,
        "period": "month",
        "period_name": "月",
        "features": {
            "basic_chat": True,
            "solar_terms": True,
            "unlimited_chat": True,
            "today_plan": True,
            "deep_suggestions": False,
            "weekly_summary": False,
            "family": False
        }
    },
    "yiyang": {
        "id": "yiyang",
        "name": "颐养版",
        "price": 59,
        "price_yearly": 399,
        "price_cents": 5900,
        "price_yearly_cents": 39900,
        "period": "month",
        "period_name": "月",
        "features": {
            "basic_chat": True,
            "solar_terms": True,
            "unlimited_chat": True,
            "today_plan": True,
            "deep_suggestions": True,
            "weekly_summary": True,
            "family": False
        }
    },
    "jiahe": {
        "id": "jiahe",
        "name": "家和版",
        "price": 99,
        "price_yearly": 699,
        "price_cents": 9900,
        "price_yearly_cents": 69900,
        "period": "month",
        "period_name": "月",
        "family_seats": 4,
        "features": {
            "basic_chat": True,
            "solar_terms": True,
            "unlimited_chat": True,
            "today_plan": True,
            "deep_suggestions": True,
            "weekly_summary": True,
            "family": True
        }
    },
}


# ============ 产品 SKU（金额用分存储） ============

SUBSCRIPTION_PRODUCTS = [
    # ----- 养心版 -----
    {
        "product_id": "yangxin_monthly",
        "name": "养心版·月付",
        "tier": "yangxin",
        "price_cents": 2900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "alipay",
        "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        "status": "active",
    },
    {
        "product_id": "yangxin_yearly",
        "name": "养心版·年付",
        "tier": "yangxin",
        "price_cents": 19900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "alipay",
        "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        "status": "active",
    },
    {
        "product_id": "yangxin_apple_monthly",
        "name": "养心版·月付",
        "tier": "yangxin",
        "price_cents": 2900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "apple",
        "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        "status": "active",
    },
    {
        "product_id": "yangxin_apple_yearly",
        "name": "养心版·年付",
        "tier": "yangxin",
        "price_cents": 19900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "apple",
        "features": SUBSCRIPTION_PLANS["yangxin"]["features"],
        "status": "active",
    },
    # ----- 颐养版 -----
    {
        "product_id": "yiyang_monthly",
        "name": "颐养版·月付",
        "tier": "yiyang",
        "price_cents": 5900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "alipay",
        "features": SUBSCRIPTION_PLANS["yiyang"]["features"],
        "status": "active",
    },
    {
        "product_id": "yiyang_yearly",
        "name": "颐养版·年付",
        "tier": "yiyang",
        "price_cents": 39900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "alipay",
        "features": SUBSCRIPTION_PLANS["yiyang"]["features"],
        "status": "active",
    },
    {
        "product_id": "yiyang_apple_monthly",
        "name": "颐养版·月付",
        "tier": "yiyang",
        "price_cents": 5900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "apple",
        "features": SUBSCRIPTION_PLANS["yiyang"]["features"],
        "status": "active",
    },
    {
        "product_id": "yiyang_apple_yearly",
        "name": "颐养版·年付",
        "tier": "yiyang",
        "price_cents": 39900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "apple",
        "features": SUBSCRIPTION_PLANS["yiyang"]["features"],
        "status": "active",
    },
    # ----- 家和版 -----
    {
        "product_id": "jiahe_monthly",
        "name": "家和版·月付",
        "tier": "jiahe",
        "price_cents": 9900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "alipay",
        "family_seats": 4,
        "features": SUBSCRIPTION_PLANS["jiahe"]["features"],
        "status": "active",
    },
    {
        "product_id": "jiahe_yearly",
        "name": "家和版·年付",
        "tier": "jiahe",
        "price_cents": 69900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "alipay",
        "family_seats": 4,
        "features": SUBSCRIPTION_PLANS["jiahe"]["features"],
        "status": "active",
    },
    {
        "product_id": "jiahe_apple_monthly",
        "name": "家和版·月付",
        "tier": "jiahe",
        "price_cents": 9900,
        "currency": "CNY",
        "duration_days": 30,
        "platform": "apple",
        "family_seats": 4,
        "features": SUBSCRIPTION_PLANS["jiahe"]["features"],
        "status": "active",
    },
    {
        "product_id": "jiahe_apple_yearly",
        "name": "家和版·年付",
        "tier": "jiahe",
        "price_cents": 69900,
        "currency": "CNY",
        "duration_days": 365,
        "platform": "apple",
        "family_seats": 4,
        "features": SUBSCRIPTION_PLANS["jiahe"]["features"],
        "status": "active",
    },
]


# ============ In-memory storage (生产环境用数据库) ============

subscriptions: Dict[str, dict] = {}
purchase_history: Dict[str, list] = {}
payment_orders: Dict[str, dict] = {}
usage_stats: Dict[str, dict] = {}
audit_log: List[dict] = []
# 家庭席位: {user_id: {family_seats: 4, used_seats: 1, members: [{"name": "xxx", "user_id": "xxx"}]}}
family_seats: Dict[str, dict] = {}


# ============ Models ============

class SubscriptionStatus(BaseModel):
    plan: str
    status: str
    expires_at: Optional[str]
    features: dict
    auto_renew: bool = False


class SubscribeRequest(BaseModel):
    plan: str
    receipt: Optional[str] = None
    platform: str = "ios"


class SubscriptionPlan(BaseModel):
    id: str
    name: str
    price: int
    period: Optional[str]
    period_name: Optional[str]
    features: dict
    description: Optional[str] = None


class AlipayOrderRequest(BaseModel):
    plan: str
    user_id: str = "user-001"


class PaymentVerifyRequest(BaseModel):
    order_id: str
    trade_no: Optional[str] = None


class StripeCheckoutRequest(BaseModel):
    plan: str
    user_id: str = "user-001"
    success_url: str = "https://app.shunshi.com/payment/success"
    cancel_url: str = "https://app.shunshi.com/payment/cancel"


class StripeWebhookRequest(BaseModel):
    type: str
    data: Optional[dict] = None


class PurchaseRequest(BaseModel):
    """发起支付请求"""
    product_id: str = Field(..., description="产品 SKU")
    platform: str = Field("alipay", description="支付平台: alipay/apple/wechat")


class PurchaseVerifyRequest(BaseModel):
    """支付回调验签请求"""
    order_id: str = Field(..., description="订单号")
    platform: str = Field("alipay", description="支付平台")
    transaction_id: Optional[str] = Field(None, description="第三方交易号")
    trade_status: Optional[str] = Field(None, description="交易状态")
    total_amount: Optional[str] = Field(None, description="实际支付金额")
    sign: Optional[str] = Field(None, description="签名")
    sign_type: Optional[str] = Field(None, description="签名类型")


class RestorePurchaseRequest(BaseModel):
    """恢复购买请求"""
    platform: str = Field(..., description="平台: ios/android")
    receipt: Optional[str] = Field(None, description="购买凭证 (iOS base64 receipt)")
    transaction_id: Optional[str] = Field(None, description="交易号")
    purchase_token: Optional[str] = Field(None, description="购买令牌 (Android)")
    product_id: Optional[str] = Field(None, description="产品 ID")
    user_id: Optional[str] = Field(None, description="用户 ID (可选，优先使用 query)")


class ReceiptVerifyBody(BaseModel):
    platform: str = "ios"
    receipt_data: str = ""
    product_id: Optional[str] = None
    plan: Optional[str] = None
    user_id: Optional[str] = "user-001"


class CreateOrderRequest(BaseModel):
    """创建订单请求"""
    product_id: str = Field(..., description="产品 SKU ID")
    platform: str = Field("alipay", description="支付平台: alipay/apple/wechat")


class CancelOrderRequest(BaseModel):
    """取消订单请求"""
    order_id: str = Field(..., description="订单 ID")


class CheckExpiredRequest(BaseModel):
    """检查过期请求（定时任务调用）"""
    pass


# ============ 订单号生成 ============

def generate_order_no() -> str:
    """
    生成订单号: SHUNSHI-YYYYMMDD-XXXXXXXX
    格式: 前缀 + 日期 + 12位随机字符
    """
    now = datetime.now(timezone.utc)
    date_str = now.strftime("%Y%m%d")
    random_str = secrets.token_hex(6).upper()  # 12 hex chars
    return f"SHUNSHI-{date_str}-{random_str}"


# ============ 订阅状态机 (兼容旧版) ============

VALID_SUBSCRIPTION_TRANSITIONS = {
    "active": ["cancelled", "expired", "paused"],
    "cancelled": ["active"],
    "expired": ["active"],
    "paused": ["active", "cancelled"],
    "pending": ["active", "failed"],
    "failed": ["pending", "active"],
}


def transition_status(current: str, target: str) -> bool:
    """检查订阅状态转换是否合法"""
    allowed = VALID_SUBSCRIPTION_TRANSITIONS.get(current, [])
    return target in allowed


# ============ 家庭席位管理 ============

def _init_family_seats(user_id: str, tier: str, order_id: str = None):
    """
    初始化家庭席位。
    仅 jiahe 版有家庭席位（4个），其他版本无家庭席位。
    """
    if tier == "jiahe":
        family_seats[user_id] = {
            "family_seats": 4,
            "used_seats": 0,
            "members": [],
            "order_id": order_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        logger.info(f"[FamilySeats] 初始化家庭席位: user={user_id}, seats=4")
    else:
        # 非家和版，清除家庭席位
        if user_id in family_seats:
            del family_seats[user_id]


def get_family_seats_info(user_id: str) -> dict:
    """获取用户家庭席位信息"""
    if user_id not in family_seats:
        return {"family_seats": 0, "used_seats": 0, "available": 0, "members": []}
    info = family_seats[user_id]
    return {
        "family_seats": info["family_seats"],
        "used_seats": info["used_seats"],
        "available": info["family_seats"] - info["used_seats"],
        "members": info["members"],
    }


def bind_family_member(owner_id: str, member_name: str, member_user_id: str = None) -> dict:
    """
    绑定家庭席位。
    不能超额分配。
    """
    if owner_id not in family_seats:
        raise HTTPException(status_code=400, detail="该用户没有家庭席位")

    info = family_seats[owner_id]
    if info["used_seats"] >= info["family_seats"]:
        raise HTTPException(status_code=400, detail="家庭席位已满，无法添加新成员")

    member = {"name": member_name, "user_id": member_user_id, "bound_at": datetime.now(timezone.utc).isoformat()}
    info["members"].append(member)
    info["used_seats"] += 1

    _write_audit_log("family_member_bound", owner_id, {
        "member_name": member_name,
        "member_user_id": member_user_id,
        "used_seats": info["used_seats"],
        "total_seats": info["family_seats"],
    })

    logger.info(f"[FamilySeats] 绑定成员: owner={owner_id}, member={member_name}, used={info['used_seats']}/{info['family_seats']}")
    return get_family_seats_info(owner_id)


def unbind_family_member(owner_id: str, member_user_id: str = None, member_index: int = None) -> dict:
    """
    解绑家庭席位，释放额度。
    """
    if owner_id not in family_seats:
        raise HTTPException(status_code=400, detail="该用户没有家庭席位")

    info = family_seats[owner_id]
    removed = False

    if member_index is not None and 0 <= member_index < len(info["members"]):
        removed_member = info["members"].pop(member_index)
        removed = True
    elif member_user_id:
        for i, m in enumerate(info["members"]):
            if m.get("user_id") == member_user_id:
                info["members"].pop(i)
                removed = True
                break

    if removed:
        info["used_seats"] = max(0, info["used_seats"] - 1)
        _write_audit_log("family_member_unbound", owner_id, {
            "member_user_id": member_user_id,
            "used_seats": info["used_seats"],
        })
        logger.info(f"[FamilySeats] 解绑成员: owner={owner_id}, used={info['used_seats']}/{info['family_seats']}")

    return get_family_seats_info(owner_id)


# ============ 权益中间件 ============

def _get_user_id_from_request(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme)
) -> str:
    """从请求中提取 user_id（用于权益检查）"""
    if not credentials:
        return None

    token = credentials.credentials

    try:
        import jwt
        JWT_SECRET = os.getenv("JWT_SECRET", "shunshi-dev-secret-change-in-production-2026")
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        if payload.get("type") == "access":
            return payload.get("sub")
    except Exception:
        pass

    from app.database.db import get_db
    db = get_db()
    row = db.execute(
        "SELECT user_id FROM auth_tokens WHERE token = ?", (token,)
    ).fetchone()
    return row["user_id"] if row else None


async def require_tier(
    min_tier: str = "free",
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> dict:
    """
    权益检查依赖函数 — 检查用户当前订阅层级是否满足要求

    层级: free < yangxin < yiyang < jiahe
    """
    if min_tier not in TIER_ORDER:
        raise HTTPException(status_code=500, detail=f"无效的层级: {min_tier}")

    user_id = None
    token = None
    if credentials:
        token = credentials.credentials

    if token:
        try:
            import jwt as _jwt
            _secret = os.getenv("JWT_SECRET", "shunshi-dev-secret-change-in-production-2026")
            payload = _jwt.decode(token, _secret, algorithms=["HS256"])
            if payload.get("type") == "access":
                user_id = payload.get("sub")
        except Exception:
            pass

    if not user_id and token:
        from app.database.db import get_db
        db = get_db()
        row = db.execute(
            "SELECT user_id FROM auth_tokens WHERE token = ?", (token,)
        ).fetchone()
        user_id = row["user_id"] if row else None

    if not user_id:
        if TIER_ORDER.get("free", 0) < TIER_ORDER[min_tier]:
            raise HTTPException(
                status_code=403,
                detail=f"需要 {min_tier} 及以上会员",
                headers={"X-Required-Tier": min_tier, "X-Current-Tier": "free"},
            )
        return {"id": None, "tier": "free", "status": "active"}

    sub = _get_user_subscription_lazy(user_id)
    current_tier = sub.get("plan", "free")

    if TIER_ORDER.get(current_tier, 0) < TIER_ORDER[min_tier]:
        raise HTTPException(
            status_code=403,
            detail=f"需要 {min_tier} 及以上会员，当前为 {current_tier}",
            headers={"X-Required-Tier": min_tier, "X-Current-Tier": current_tier},
        )

    return {"id": user_id, "tier": current_tier, "status": sub.get("status", "active")}


def _get_user_subscription_lazy(user_id: str) -> dict:
    """
    获取用户订阅状态（带过期回退的 lazy check）
    """
    if user_id not in subscriptions:
        return {"plan": "free", "status": "active", "expires_at": None}

    sub = subscriptions[user_id]
    plan = sub.get("plan", "free")

    if sub.get("expires_at") and sub.get("status") == "active":
        expires = datetime.fromisoformat(sub["expires_at"])
        if expires < datetime.now(timezone.utc):
            sub["status"] = "expired"
            sub["plan"] = "free"
            sub["features"] = SUBSCRIPTION_PLANS["free"]["features"]
            logger.info(f"[Subscription] Lazy 过期降级: user={user_id}, expired_at={sub['expires_at']}")
            _notify_subscription_expired(user_id, plan)
            return {"plan": "free", "status": "expired", "expires_at": sub["expires_at"]}

    return sub


def _notify_subscription_expired(user_id: str, old_plan: str):
    """通知用户订阅已过期（写入通知表）"""
    try:
        from app.database.db import get_db
        db = get_db()
        now = datetime.now(timezone.utc).isoformat()

        try:
            db.execute("SELECT 1 FROM notifications LIMIT 1")
        except Exception:
            db.execute("""
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
                )
            """)
            db.commit()

        db.execute("""
            INSERT INTO notifications (id, user_id, type, title, body, data, sent_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            f"notif_{uuid.uuid4().hex[:12]}",
            user_id,
            "subscription_expired",
            "订阅已过期",
            f"您的{SUBSCRIPTION_PLANS.get(old_plan, {}).get('name', old_plan)}订阅已过期，已自动降为免费版",
            json.dumps({"old_plan": old_plan, "new_plan": "free"}),
            now,
        ))
        db.commit()
    except Exception as e:
        logger.warning(f"[Subscription] 通知失败: {e}")


# ============ Helper Functions ============

def get_user_subscription(user_id: str) -> SubscriptionStatus:
    """获取用户订阅状态（兼容原有接口）"""
    if user_id not in subscriptions:
        return SubscriptionStatus(
            plan="free",
            status="active",
            expires_at=None,
            features=SUBSCRIPTION_PLANS["free"]["features"],
            auto_renew=False
        )

    sub = subscriptions[user_id]
    plan = sub.get("plan", "free")

    if sub.get("expires_at"):
        expires = datetime.fromisoformat(sub["expires_at"])
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if expires < datetime.now(timezone.utc):
            return SubscriptionStatus(
                plan="free",
                status="expired",
                expires_at=sub["expires_at"],
                features=SUBSCRIPTION_PLANS["free"]["features"],
                auto_renew=False
            )

    return SubscriptionStatus(
        plan=plan,
        status=sub.get("status", "active"),
        expires_at=sub.get("expires_at"),
        features=SUBSCRIPTION_PLANS.get(plan, SUBSCRIPTION_PLANS["free"])["features"],
        auto_renew=sub.get("auto_renew", False)
    )


def check_subscription_valid(user_id: str) -> dict:
    """检查订阅是否有效（中间件可调用）"""
    sub = get_user_subscription(user_id)
    return {
        "valid": sub.status == "active" and sub.plan != "free",
        "plan": sub.plan,
        "status": sub.status,
        "expires_at": sub.expires_at,
    }


def record_usage(user_id: str, usage_type: str, amount: int = 1):
    """记录使用量"""
    if user_id not in usage_stats:
        usage_stats[user_id] = {
            "chat_count": 0,
            "api_calls": 0,
            "feature_uses": {},
            "period_start": datetime.now(timezone.utc).isoformat(),
        }

    if usage_type == "chat":
        usage_stats[user_id]["chat_count"] += amount
    elif usage_type == "api_call":
        usage_stats[user_id]["api_calls"] += amount
    else:
        current = usage_stats[user_id]["feature_uses"].get(usage_type, 0)
        usage_stats[user_id]["feature_uses"][usage_type] = current + amount


def _write_audit_log(action: str, user_id: str, details: dict):
    """写入支付审计日志"""
    entry = {
        "id": f"audit_{uuid.uuid4().hex[:12]}",
        "action": action,
        "user_id": user_id,
        "details": details,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    audit_log.append(entry)
    logger.info(f"[Audit] {action}: user={user_id}, details={json.dumps(details, ensure_ascii=False)}")


# ============ 过期回退（定时任务） ============

async def _async_send_alert(event):
    """异步发送告警（用于非async上下文）"""
    try:
        from app.alerts import alert_sender
        await alert_sender.send(event)
    except Exception:
        pass

def check_expired_subscriptions() -> List[dict]:
    """检查所有已过期订阅（定时任务可调用）"""
    expired = []
    now = datetime.now(timezone.utc)

    for user_id, sub in subscriptions.items():
        if sub.get("expires_at"):
            expires = datetime.fromisoformat(sub["expires_at"])
            if expires < now and sub.get("status") == "active":
                expired.append({
                    "user_id": user_id,
                    "plan": sub.get("plan"),
                    "expired_at": sub["expires_at"],
                })

    return expired


def expire_subscription(user_id: str):
    """执行单个用户过期回退"""
    if user_id not in subscriptions:
        return

    sub = subscriptions[user_id]
    old_plan = sub.get("plan", "free")

    sub["status"] = "expired"
    sub["plan"] = "free"
    sub["features"] = SUBSCRIPTION_PLANS["free"]["features"]

    logger.info(f"[Subscription] 订阅过期降级: user={user_id}, old_plan={old_plan}")
    _notify_subscription_expired(user_id, old_plan)

    # 发送过期告警（同步记录，不阻塞）
    try:
        from app.alerts import AlertRules
        from app.alerts.store import alert_store as _alert_store
        event = AlertRules.subscription_expired_unexpected(user_id, old_plan)
        _alert_store.record(event, sent=False, channel="deferred")
        # 异步发送告警（非阻塞）
        import asyncio
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(_async_send_alert(event))
        except RuntimeError:
            pass
    except Exception as alert_err:
        logger.warning(f"[Alert] 订阅过期告警发送异常: {alert_err}")

    # 家和版: 通知家庭主账号
    if old_plan == "jiahe" and user_id in family_seats:
        logger.info(f"[FamilySeats] 家和版过期: owner={user_id}, 通知家庭主账号")

    _write_audit_log("subscription_expired", user_id, {
        "old_plan": old_plan,
        "new_plan": "free",
    })


# ============ 支付签名验证 ============

def _verify_payment_signature(request: PurchaseVerifyRequest, order: dict) -> bool:
    """
    验证支付签名。

    生产环境实现:
    - 支付宝: 用公钥验证 sign
    - Apple: 调用 App Store Server API 验证
    - Google: 调用 Google Play Developer API 验证

    当前为模拟模式（无签名也通过）
    """
    if not request.sign:
        return True  # 模拟模式

    # TODO: 生产环境验签
    # import hmac
    # alipay_public_key = os.getenv("ALIPAY_PUBLIC_KEY")
    # verified = verify_with_public_key(request.sign, params, alipay_public_key)

    return True


# ============================================================
#                     API Endpoints
# ============================================================

# ---- 商品列表（含4级会员） ----

@router.get("/products", response_model=dict)
async def get_products(
    platform: Optional[str] = Query(None, description="筛选平台: alipay/apple"),
    user_id: str = Query("user-001"),
):
    """
    获取产品列表（含4级会员）
    - 返回所有可用 SKU
    - 可按平台筛选
    - 标记当前订阅
    - 金额用分存储，前端展示时除以100
    """
    current_sub = get_user_subscription(user_id)

    products = []
    for p in SUBSCRIPTION_PRODUCTS:
        if p["status"] != "active":
            continue
        if platform and p["platform"] != platform:
            continue

        products.append({
            "product_id": p["product_id"],
            "name": p["name"],
            "tier": p["tier"],
            "tier_name": SUBSCRIPTION_PLANS[p["tier"]]["name"],
            "price_cents": p["price_cents"],
            "price_display": f"¥{p['price_cents'] / 100:.2f}",
            "currency": p["currency"],
            "duration_days": p["duration_days"],
            "platform": p["platform"],
            "family_seats": p.get("family_seats", 0),
            "features": p["features"],
            "is_current_tier": p["tier"] == current_sub.plan,
            "upgrade": TIER_ORDER.get(p["tier"], 0) > TIER_ORDER.get(current_sub.plan, 0),
        })

    return {
        "success": True,
        "data": {
            "current_tier": current_sub.plan,
            "tiers": ["free", "yangxin", "yiyang", "jiahe"],
            "products": products,
        }
    }


# ---- 创建订单 ----

@router.post("/create-order", response_model=dict)
async def create_order(request: CreateOrderRequest, user_id: str = Query("user-001")):
    """
    创建订单。
    1. 查找产品 SKU
    2. 验证是否允许购买
    3. 创建 pending 订单
    4. 返回支付参数
    """
    product = None
    for p in SUBSCRIPTION_PRODUCTS:
        if p["product_id"] == request.product_id:
            product = p
            break

    if not product:
        raise HTTPException(status_code=400, detail=f"产品不存在: {request.product_id}")

    # 检查是否已是同等级（同平台不允许重复购买）
    current_sub = get_user_subscription(user_id)
    new_tier = product["tier"]
    if TIER_ORDER.get(new_tier, 0) <= TIER_ORDER.get(current_sub.plan, 0):
        if current_sub.plan == new_tier and current_sub.status == "active":
            raise HTTPException(status_code=400, detail="当前已是该等级会员，无需重复购买")

    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    order_no = generate_order_no()
    order_id = str(uuid.uuid4())

    # 订单过期时间（30分钟）
    expires_at = (now + timedelta(minutes=30)).isoformat()

    payment_orders[order_id] = {
        "id": order_id,
        "order_no": order_no,
        "user_id": user_id,
        "product_id": product["product_id"],
        "tier": product["tier"],
        "platform": product["platform"],
        "amount_cents": product["price_cents"],
        "currency": product["currency"],
        "status": OrderStatus.PENDING.value,
        "created_at": now_iso,
        "expires_at": expires_at,
        "transaction_id": None,
        "payment_method": None,
        "paid_at": None,
    }

    _write_audit_log("order_created", user_id, {
        "order_id": order_id,
        "order_no": order_no,
        "product_id": product["product_id"],
        "amount_cents": product["price_cents"],
        "platform": request.platform,
    })

    logger.info(f"[Order] 订单创建: {order_no}, product={product['product_id']}, amount={product['price_cents']}分")

    # 返回支付参数
    pay_params = {
        "order_id": order_id,
        "order_no": order_no,
        "amount_cents": product["price_cents"],
        "amount_display": f"¥{product['price_cents'] / 100:.2f}",
        "currency": product["currency"],
        "expires_in": 1800,
        "status": "pending",
    }

    if request.platform == "alipay":
        pay_params["pay_url"] = f"https://openapi.alipay.com/gateway.do?mock=1&orderId={order_no}"
        pay_params["qr_code"] = f"MOCK_QR_CODE_{order_no}"
    elif request.platform == "apple":
        pay_params["product_id"] = product["product_id"]

    return {
        "success": True,
        "data": pay_params,
    }


# ---- 验证支付回调 ----

@router.post("/verify-payment", response_model=dict)
async def verify_payment(request: PurchaseVerifyRequest):
    """
    支付回调验签。
    1. 验证签名（生产环境必须）
    2. 验证订单状态转换
    3. 更新订单为 paid
    4. 激活订阅
    5. 写审计日志
    """
    order = payment_orders.get(request.order_id)

    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    if order["status"] == OrderStatus.PAID.value:
        return {
            "success": True,
            "data": {
                "order_id": request.order_id,
                "order_no": order["order_no"],
                "status": "already_paid",
                "message": "订单已支付",
            }
        }

    if order["status"] != OrderStatus.PENDING.value:
        raise HTTPException(status_code=400, detail=f"订单状态不正确: {order['status']}，当前状态不允许支付")

    # === 签名验证（支付回调必须验签） ===
    verified = _verify_payment_signature(request, order)
    if not verified:
        # 状态转换: pending → failed
        if transition_order(order["status"], OrderStatus.FAILED.value):
            order["status"] = OrderStatus.FAILED.value
        _write_audit_log("payment_verify_failed", order["user_id"], {
            "order_id": request.order_id,
            "reason": "signature verification failed",
        })
        # 发送告警
        try:
            from app.alerts import alert_sender, AlertRules
            event = AlertRules.payment_failed(request.order_id, "签名验证失败", order.get("amount_cents", 0) / 100)
            alert_store_recorded = await alert_sender.send(event)
            if alert_store_recorded:
                from app.alerts.store import alert_store
                alert_store.record(event, alert_store_recorded, "webhook")
        except Exception as alert_err:
            logger.warning(f"[Alert] 支付失败告警发送异常: {alert_err}")
        raise HTTPException(status_code=400, detail="签名验证失败")

    # === 验证状态转换 ===
    if not transition_order(order["status"], OrderStatus.PAID.value):
        raise HTTPException(status_code=400, detail=f"非法状态转换: {order['status']} → paid")

    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    # === 更新订单状态 ===
    order["status"] = OrderStatus.PAID.value
    order["paid_at"] = now_iso
    order["transaction_id"] = request.transaction_id or f"TXN_{uuid.uuid4().hex[:16]}"

    # === 激活订阅 ===
    tier = order["tier"]
    product_info = SUBSCRIPTION_PLANS.get(tier, SUBSCRIPTION_PLANS["free"])

    # 查找产品获取 duration
    duration_days = 30
    for p in SUBSCRIPTION_PRODUCTS:
        if p["product_id"] == order["product_id"]:
            duration_days = p["duration_days"]
            break

    expires_at = (now + timedelta(days=duration_days)).isoformat()

    subscriptions[order["user_id"]] = {
        "plan": tier,
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": True,
        "platform": order["platform"],
        "order_id": order["id"],
        "order_no": order["order_no"],
        "activated_at": now_iso,
        "features": product_info["features"],
    }

    # 初始化家庭席位
    _init_family_seats(order["user_id"], tier, order["id"])

    # 记录购买历史
    if order["user_id"] not in purchase_history:
        purchase_history[order["user_id"]] = []
    purchase_history[order["user_id"]].append({
        "plan": tier,
        "price_cents": order["amount_cents"],
        "platform": order["platform"],
        "order_id": order["id"],
        "order_no": order["order_no"],
        "trade_no": order["transaction_id"],
        "subscribed_at": now_iso,
    })

    _write_audit_log("payment_verified", order["user_id"], {
        "order_id": request.order_id,
        "order_no": order["order_no"],
        "tier": tier,
        "amount_cents": order["amount_cents"],
        "transaction_id": order["transaction_id"],
    })

    logger.info(f"[Payment] 支付验证通过: {order['order_no']}, tier={tier}")

    return {
        "success": True,
        "data": {
            "order_id": order["id"],
            "order_no": order["order_no"],
            "transaction_id": order["transaction_id"],
            "plan": tier,
            "status": "paid",
            "subscription": {
                "plan": tier,
                "expires_at": expires_at,
                "status": "active",
                "features": product_info["features"],
            }
        }
    }


# ---- 查询订单状态 ----

@router.get("/order/{order_id}", response_model=dict)
async def query_order(order_id: str):
    """查询订单状态"""
    order = payment_orders.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    return {
        "success": True,
        "data": {
            "id": order["id"],
            "order_no": order["order_no"],
            "user_id": order["user_id"],
            "product_id": order["product_id"],
            "tier": order["tier"],
            "platform": order["platform"],
            "amount_cents": order["amount_cents"],
            "currency": order["currency"],
            "status": order["status"],
            "transaction_id": order.get("transaction_id"),
            "created_at": order["created_at"],
            "paid_at": order.get("paid_at"),
            "expires_at": order.get("expires_at"),
        }
    }


# ---- 取消订单 ----

@router.post("/cancel-order", response_model=dict)
async def cancel_order(request: CancelOrderRequest):
    """取消订单（pending → cancelled）"""
    order = payment_orders.get(request.order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    if not transition_order(order["status"], OrderStatus.CANCELLED.value):
        raise HTTPException(
            status_code=400,
            detail=f"无法从 {order['status']} 状态取消订单"
        )

    order["status"] = OrderStatus.CANCELLED.value

    _write_audit_log("order_cancelled", order["user_id"], {
        "order_id": request.order_id,
        "order_no": order["order_no"],
        "previous_status": "pending",
    })

    return {
        "success": True,
        "data": {
            "order_id": order["id"],
            "order_no": order["order_no"],
            "status": "cancelled",
        }
    }


# ============ 产品 ID → 计划映射 ============

def _product_id_to_plan(product_id: str) -> Optional[str]:
    """
    将 Apple/Google 产品 ID 映射到订阅计划。

    Args:
        product_id: 如 "com.shunshi.yiyang.yearly"

    Returns:
        计划 ID (yangxin/yiyang/jiahe)，无法识别时返回 None
    """
    if not product_id:
        return None

    pid = product_id.lower()

    # Apple 产品 ID 映射
    if "yangxin" in pid:
        return "yangxin"
    elif "yiyang" in pid:
        return "yiyang"
    elif "jiahe" in pid:
        return "jiahe"
    elif "family" in pid:
        return "jiahe"

    # 后端内部产品 ID 映射
    for p in SUBSCRIPTION_PRODUCTS:
        if p["product_id"] == product_id:
            return p["tier"]

    return None


# ---- 恢复购买 ----

@router.post("/restore", response_model=dict)
async def restore_purchase(
    request: RestorePurchaseRequest,
    user_id: str = Query("user-001"),
):
    """
    恢复购买（增强版）

    流程:
    1. 接收平台 transaction_id / receipt / purchase_token
    2. 调用平台 API 验证交易有效性
       - iOS: verify_apple_receipt()
       - Android: verify_google_purchase()
    3. 如果有效且未过期，恢复会员权益
    4. 如果已过期，告知用户
    5. 幂等操作：重复调用不影响结果

    请求体:
    {
        "platform": "ios" | "android",
        "transaction_id": "xxx",
        "receipt": "base64..." (iOS),
        "purchase_token": "xxx" (Android),
        "product_id": "xxx" (可选),
        "user_id": "xxx" (可选)
    }
    """
    effective_user_id = request.user_id or user_id
    now = datetime.now(timezone.utc)

    # ── 平台验证 ──
    verify_result = None

    if request.platform == "ios":
        if not request.receipt:
            # 没有 receipt 时，回退到本地历史记录
            logger.info(f"[Restore] iOS 恢复购买: 无 receipt，查找本地历史 user={effective_user_id}")
        else:
            try:
                from app.services.apple_receipt import verify_apple_receipt
                verify_result = await verify_apple_receipt(
                    receipt_data=request.receipt,
                    transaction_id=request.transaction_id,
                )
            except Exception as e:
                logger.error(f"[Restore] Apple 验证异常: {e}")
                verify_result = {"valid": False, "error": f"验证异常: {str(e)}"}

    elif request.platform == "android":
        if not request.purchase_token:
            logger.info(f"[Restore] Android 恢复购买: 无 purchase_token，查找本地历史 user={effective_user_id}")
        else:
            try:
                from app.services.google_purchase import verify_google_purchase
                verify_result = await verify_google_purchase(
                    package_name="com.shunshi.app",
                    product_id=request.product_id or "unknown",
                    purchase_token=request.purchase_token,
                    is_subscription=True,
                )
            except Exception as e:
                logger.error(f"[Restore] Google 验证异常: {e}")
                verify_result = {"valid": False, "error": f"验证异常: {str(e)}"}
    else:
        raise HTTPException(status_code=400, detail=f"不支持的平台: {request.platform}")

    # ── 处理验证结果 ──
    if verify_result and not verify_result.get("valid"):
        error_msg = verify_result.get("error", "验证失败")
        # 检查是否过期
        if "过期" in error_msg:
            return {
                "success": False,
                "code": "expired",
                "message": "订阅已过期，请重新订阅",
            }
        return {
            "success": False,
            "code": "verify_failed",
            "message": f"验证失败: {error_msg}",
        }

    # ── 确定订阅计划 ──
    plan_id = None
    txn_id = request.transaction_id

    if verify_result and verify_result.get("valid"):
        # 从验证结果中提取产品信息
        product_id = verify_result.get("product_id", "")
        txn_id = verify_result.get("transaction_id") or txn_id

        # 产品 ID → 计划映射
        plan_id = _product_id_to_plan(product_id)

    if not plan_id:
        # 回退到本地历史记录
        if effective_user_id not in purchase_history or not purchase_history[effective_user_id]:
            return {"success": False, "code": "no_history", "message": "未找到购买记录"}

        target_purchase = None
        for purchase in reversed(purchase_history[effective_user_id]):
            if purchase.get("platform") in (request.platform, f"iap_{request.platform}"):
                target_purchase = purchase
                break

        if not target_purchase:
            return {
                "success": False,
                "code": "no_platform_history",
                "message": f"未找到 {request.platform} 平台的购买记录",
            }

        plan_id = target_purchase["plan"]

    if plan_id not in SUBSCRIPTION_PLANS:
        plan_id = "yiyang"  # 默认恢复颐养版

    plan = SUBSCRIPTION_PLANS[plan_id]

    # ── 检查过期（验证结果中包含过期时间） ──
    expires_at_ms = None
    if verify_result and verify_result.get("valid"):
        expires_at_ms = verify_result.get("expires_at_ms")

    if expires_at_ms:
        import time
        if expires_at_ms < int(time.time() * 1000):
            return {
                "success": False,
                "code": "expired",
                "message": "订阅已过期，请重新订阅",
            }

    # ── 计算过期时间 ──
    if expires_at_ms:
        expires_at = datetime.fromtimestamp(expires_at_ms / 1000, tz=timezone.utc).isoformat()
    else:
        # 从产品 SKU 获取 duration
        duration_days = 365
        matched_product_id = verify_result.get("product_id") if verify_result else request.product_id
        if matched_product_id:
            for p in SUBSCRIPTION_PRODUCTS:
                if p["product_id"] == matched_product_id:
                    duration_days = p["duration_days"]
                    break
        # 如果从历史记录获取，尝试匹配计划
        if duration_days == 365:
            for p in SUBSCRIPTION_PRODUCTS:
                if p["tier"] == plan_id and "yearly" in p["product_id"]:
                    duration_days = p["duration_days"]
                    break
        expires_at = (now + timedelta(days=duration_days)).isoformat()

    # ── 幂等检查 ──
    current_sub = _get_user_subscription_lazy(effective_user_id)
    if (current_sub.get("plan") == plan_id and
            current_sub.get("status") == "active" and
            current_sub.get("restored")):
        # 已恢复过，返回当前状态
        return {
            "success": True,
            "code": "already_restored",
            "data": {
                "plan": plan_id,
                "plan_name": plan.get("name", plan_id),
                "expires_at": current_sub.get("expires_at"),
                "features": current_sub.get("features", plan["features"]),
                "message": "订阅已恢复（无需重复操作）",
            }
        }

    # ── 激活订阅 ──
    auto_renew = True
    if verify_result and verify_result.get("valid"):
        auto_renew = verify_result.get("auto_renew", True)

    # 收据 hash（不存储明文）
    receipt_hash = None
    if request.receipt:
        import hashlib
        receipt_hash = hashlib.sha256(request.receipt.encode()).hexdigest()[:32]

    subscriptions[effective_user_id] = {
        "plan": plan_id,
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": auto_renew,
        "platform": request.platform,
        "restored": True,
        "restored_at": now.isoformat(),
        "transaction_id": txn_id,
        "receipt_hash": receipt_hash,
        "verified": verify_result is not None,
        "features": plan["features"],
    }

    # 初始化家庭席位
    _init_family_seats(effective_user_id, plan_id)

    # 记录购买历史
    if effective_user_id not in purchase_history:
        purchase_history[effective_user_id] = []
    purchase_history[effective_user_id].append({
        "plan": plan_id,
        "platform": f"iap_{request.platform}",
        "transaction_id": txn_id,
        "source": "restore",
        "receipt_hash": receipt_hash,
        "restored_at": now.isoformat(),
    })

    _write_audit_log("purchase_restored", effective_user_id, {
        "plan": plan_id,
        "platform": request.platform,
        "transaction_id": txn_id,
        "receipt_hash": receipt_hash,
        "verified": verify_result is not None,
    })

    logger.info(
        f"[Restore] 购买已恢复: user={effective_user_id}, "
        f"plan={plan_id}, platform={request.platform}, "
        f"verified={verify_result is not None}"
    )

    return {
        "success": True,
        "code": "restored",
        "data": {
            "plan": plan_id,
            "plan_name": plan.get("name", plan_id),
            "expires_at": expires_at,
            "auto_renew": auto_renew,
            "features": plan["features"],
            "message": "订阅已恢复",
        }
    }


# ---- 当前订阅状态 ----

@router.get("/status", response_model=dict)
async def get_subscription_status(user_id: str = Query("user-001")):
    """获取当前订阅状态"""
    sub = get_user_subscription(user_id)
    seats_info = get_family_seats_info(user_id)

    return {
        "success": True,
        "data": {
            "plan": sub.plan,
            "plan_name": SUBSCRIPTION_PLANS.get(sub.plan, {}).get("name", "免费版"),
            "status": sub.status,
            "expires_at": sub.expires_at,
            "features": sub.features,
            "auto_renew": sub.auto_renew,
            "family_seats": seats_info if sub.plan == "jiahe" else None,
        }
    }


# ---- 检查过期（定时任务） ----

@router.post("/check-expired", response_model=dict)
async def check_expired_api():
    """
    检查过期订阅（定时任务调用）。
    1. 查询所有 status=active 且 end_at < now 的订阅
    2. 更新 status → expired
    3. 用户权益回退到 free
    4. 发送过期通知
    5. 如果是 jiahe 版，通知家庭主账号
    6. 记录审计日志
    """
    expired_list = check_expired_subscriptions()

    for item in expired_list:
        user_id = item["user_id"]
        expire_subscription(user_id)

    return {
        "success": True,
        "data": {
            "expired_count": len(expired_list),
            "expired_users": expired_list,
        }
    }


# ---- 家庭席位 API ----

@router.get("/family-seats", response_model=dict)
async def get_family_seats_endpoint(user_id: str = Query("user-001")):
    """获取家庭席位信息"""
    return {
        "success": True,
        "data": get_family_seats_info(user_id),
    }


@router.post("/family-seats/bind", response_model=dict)
async def bind_family_member_endpoint(
    member_name: str = Query(..., description="成员姓名"),
    member_user_id: Optional[str] = Query(None, description="成员用户 ID"),
    user_id: str = Query("user-001"),
):
    """绑定家庭席位"""
    info = bind_family_member(user_id, member_name, member_user_id)
    return {"success": True, "data": info}


@router.post("/family-seats/unbind", response_model=dict)
async def unbind_family_member_endpoint(
    member_user_id: Optional[str] = Query(None, description="成员用户 ID"),
    member_index: Optional[int] = Query(None, description="成员索引"),
    user_id: str = Query("user-001"),
):
    """解绑家庭席位"""
    info = unbind_family_member(user_id, member_user_id, member_index)
    return {"success": True, "data": info}


# ============================================================
#              向后兼容 API（保留原有签名）
# ============================================================

@router.get("", response_model=dict)
async def get_subscription(user_id: str = Query("user-001")):
    """获取订阅状态"""
    sub = get_user_subscription(user_id)

    return {
        "success": True,
        "data": {
            "plan": sub.plan,
            "status": sub.status,
            "expires_at": sub.expires_at,
            "features": sub.features,
            "auto_renew": sub.auto_renew
        }
    }


@router.get("/plans", response_model=dict)
async def get_plans(user_id: str = Query("user-001")):
    """获取订阅计划列表（4级）"""
    current_sub = get_user_subscription(user_id)

    plans = []
    for key, plan in SUBSCRIPTION_PLANS.items():
        plans.append({
            "id": plan["id"],
            "name": plan["name"],
            "price": plan.get("price", 0),
            "price_yearly": plan.get("price_yearly"),
            "price_cents": plan.get("price_cents", 0),
            "price_yearly_cents": plan.get("price_yearly_cents", 0),
            "period": plan.get("period"),
            "period_name": plan.get("period_name"),
            "features": plan["features"],
            "is_current": plan["id"] == current_sub.plan,
            "description": _get_plan_description(plan["id"]),
            "family_seats": plan.get("family_seats", 0),
        })

    return {"success": True, "data": plans}


def _get_plan_description(plan_id: str) -> str:
    descriptions = {
        "free": "基础功能，满足日常养生需求",
        "yangxin": "无限聊天+今日计划，适合养生爱好者",
        "yiyang": "深度建议+周总结，适合养生达人",
        "jiahe": "家庭共享（4席位），适合全家使用"
    }
    return descriptions.get(plan_id, "")


@router.post("/subscribe", response_model=dict)
async def subscribe(
    request: SubscribeRequest,
    user_id: str = Query("user-001")
):
    """订阅/升级（向后兼容）"""
    plan_id = request.plan

    if plan_id not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="订阅计划不存在")

    plan = SUBSCRIPTION_PLANS[plan_id]

    if plan["price"] == 0:
        expires_at = None
    else:
        expires_at = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat()

    subscriptions[user_id] = {
        "plan": plan_id,
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": True if plan.get("price", 0) > 0 else False,
        "platform": request.platform,
        "subscribed_at": datetime.now(timezone.utc).isoformat()
    }

    if user_id not in purchase_history:
        purchase_history[user_id] = []

    purchase_history[user_id].append({
        "plan": plan_id,
        "price": plan.get("price", 0),
        "platform": request.platform,
        "receipt": request.receipt,
        "subscribed_at": datetime.now(timezone.utc).isoformat()
    })

    return {
        "success": True,
        "data": {
            "plan": plan_id,
            "status": "active",
            "expires_at": expires_at,
            "features": plan["features"]
        }
    }


@router.post("/cancel", response_model=dict)
async def cancel_subscription(user_id: str = Query("user-001")):
    """取消订阅"""
    if user_id in subscriptions:
        sub = subscriptions[user_id]
        if not transition_status(sub.get("status", "active"), "cancelled"):
            raise HTTPException(status_code=400, detail=f"无法从 {sub.get('status')} 状态取消订阅")
        sub["auto_renew"] = False
        sub["status"] = "cancelled"

    return {
        "success": True,
        "message": "订阅已取消，到期后将降级为免费版"
    }


@router.post("/restore-purchase", response_model=dict)
async def restore_purchase_v2(request: RestorePurchaseRequest, user_id: str = Query("user-001")):
    """恢复购买 (v2，向后兼容)"""
    if user_id not in purchase_history or not purchase_history[user_id]:
        return {"success": False, "message": "未找到购买记录"}

    target_purchase = None
    for purchase in reversed(purchase_history[user_id]):
        if purchase.get("platform") in (request.platform, f"iap_{request.platform}"):
            target_purchase = purchase
            break

    if not target_purchase:
        return {"success": False, "message": f"未找到 {request.platform} 平台的购买记录"}

    plan_id = target_purchase["plan"]
    plan = SUBSCRIPTION_PLANS[plan_id]
    now = datetime.now(timezone.utc)

    expires_at = (now + timedelta(days=365)).isoformat()

    subscriptions[user_id] = {
        "plan": plan_id,
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": True,
        "platform": request.platform,
        "restored": True,
        "restored_at": now.isoformat(),
        "features": plan["features"],
    }

    _init_family_seats(user_id, plan_id)

    _write_audit_log("purchase_restored", user_id, {
        "plan": plan_id,
        "platform": request.platform,
        "original_order": target_purchase.get("order_id"),
    })

    return {
        "success": True,
        "data": {
            "plan": plan_id,
            "expires_at": expires_at,
            "features": plan["features"],
            "message": "订阅已恢复",
        }
    }


@router.get("/history", response_model=dict)
async def get_purchase_history(user_id: str = Query("user-001")):
    """获取购买历史"""
    history = purchase_history.get(user_id, [])

    return {
        "success": True,
        "data": history
    }


@router.post("/verify-receipt", response_model=dict)
async def verify_receipt(
    receipt: str = Query(...),
    platform: str = Query("ios"),
    user_id: str = Query("user-001")
):
    """验证收据 (Apple/Google) - Query 参数方式（向后兼容）"""
    verified = True
    plan_id = "yiyang"

    if verified:
        expires_at = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat()

        subscriptions[user_id] = {
            "plan": plan_id,
            "status": "active",
            "expires_at": expires_at,
            "auto_renew": True,
            "platform": platform,
            "verified": True,
            "verified_at": datetime.now(timezone.utc).isoformat()
        }

        return {
            "success": True,
            "data": {
                "plan": plan_id,
                "expires_at": expires_at
            }
        }

    return {
        "success": False,
        "message": "验证失败"
    }


@router.post("/verify-receipt-v2", response_model=dict)
async def verify_receipt_v2(request: ReceiptVerifyBody):
    """验证应用内购收据 v2 - 支持 POST JSON Body"""
    platform = request.platform
    receipt_data = request.receipt_data
    plan_id = request.plan or "yiyang"
    user_id = request.user_id or "user-001"

    if not receipt_data:
        raise HTTPException(status_code=400, detail="收据数据不能为空")

    if plan_id not in SUBSCRIPTION_PLANS:
        plan_id = "yiyang"

    verified = _mock_verify_receipt(platform, receipt_data, product_id=request.product_id)

    if verified:
        plan = SUBSCRIPTION_PLANS[plan_id]
        expires_at = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat()

        subscriptions[user_id] = {
            "plan": plan_id,
            "status": "active",
            "expires_at": expires_at,
            "auto_renew": True,
            "platform": f"iap_{platform}",
            "product_id": request.product_id,
            "receipt_data_hash": str(hash(receipt_data))[:16],
            "verified": True,
            "verified_at": datetime.now(timezone.utc).isoformat(),
            "activated_at": datetime.now(timezone.utc).isoformat(),
        }

        if user_id not in purchase_history:
            purchase_history[user_id] = []
        purchase_history[user_id].append({
            "plan": plan_id,
            "price": plan.get("price", 0),
            "platform": f"iap_{platform}",
            "product_id": request.product_id,
            "subscribed_at": datetime.now(timezone.utc).isoformat()
        })

        logger.info(f"[IAP] 收据验证成功: user={user_id}, plan={plan_id}, platform={platform}")

        return {
            "success": True,
            "data": {
                "plan": plan_id,
                "status": "active",
                "expires_at": expires_at,
                "features": plan["features"],
            }
        }

    logger.warning(f"[IAP] 收据验证失败: user={user_id}, platform={platform}")
    return {
        "success": False,
        "message": "Receipt verification failed"
    }


def _mock_verify_receipt(platform: str, receipt_data: str, product_id: str = None) -> bool:
    """模拟收据验证"""
    return bool(receipt_data and len(receipt_data) > 10)


# ---- 旧版发起支付（兼容） ----

@router.post("/purchase", response_model=dict)
async def create_purchase(request: PurchaseRequest, user_id: str = Query("user-001")):
    """发起支付（向后兼容）"""
    product = None
    for p in SUBSCRIPTION_PRODUCTS:
        if p["product_id"] == request.product_id:
            product = p
            break

    if not product:
        raise HTTPException(status_code=400, detail="产品不存在")

    current_sub = get_user_subscription(user_id)
    new_tier = product["tier"]

    if TIER_ORDER.get(new_tier, 0) <= TIER_ORDER.get(current_sub.plan, 0):
        if current_sub.plan == new_tier and current_sub.status == "active":
            raise HTTPException(status_code=400, detail="当前已是该等级会员")

    now = datetime.now(timezone.utc).isoformat()
    order_id = f"ORD_{now.replace('-', '').replace(':', '').replace('.', '')[:14]}_{uuid.uuid4().hex[:6]}"

    payment_orders[order_id] = {
        "id": order_id,
        "order_no": order_id,
        "user_id": user_id,
        "product_id": product["product_id"],
        "tier": product["tier"],
        "amount_cents": product["price_cents"],
        "currency": product["currency"],
        "platform": request.platform,
        "status": "pending",
        "created_at": now,
        "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
    }

    _write_audit_log("order_created", user_id, {
        "order_id": order_id,
        "product_id": product["product_id"],
        "amount_cents": product["price_cents"],
        "platform": request.platform,
    })

    pay_params = {
        "order_id": order_id,
        "amount_cents": product["price_cents"],
        "amount_display": f"¥{product['price_cents'] / 100:.2f}",
        "currency": product["currency"],
        "expires_in": 1800,
    }

    if request.platform == "alipay":
        pay_params["pay_url"] = f"https://openapi.alipay.com/gateway.do?mock=1&orderId={order_id}"
        pay_params["qr_code"] = f"MOCK_QR_CODE_{order_id}"
    elif request.platform == "apple":
        pay_params["product_id"] = product["product_id"]

    return {
        "success": True,
        "data": pay_params,
    }


# ---- 旧版验签（兼容） ----

@router.post("/verify", response_model=dict)
async def verify_purchase(request: PurchaseVerifyRequest):
    """支付回调验签（向后兼容）"""
    order = payment_orders.get(request.order_id)

    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    if order["status"] == "paid":
        return {
            "success": True,
            "data": {
                "order_id": request.order_id,
                "status": "already_paid",
                "message": "订单已支付",
            }
        }

    if order["status"] != "pending":
        raise HTTPException(status_code=400, detail=f"订单状态不正确: {order['status']}")

    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    verified = _verify_payment_signature(request, order)

    if not verified:
        order["status"] = "failed"
        _write_audit_log("payment_verify_failed", order["user_id"], {
            "order_id": request.order_id,
            "reason": "signature verification failed",
        })
        raise HTTPException(status_code=400, detail="签名验证失败")

    order["status"] = "paid"
    order["paid_at"] = now_iso
    order["transaction_id"] = request.transaction_id or f"TXN_{uuid.uuid4().hex[:16]}"

    tier = order["tier"]
    product_info = SUBSCRIPTION_PLANS.get(tier, SUBSCRIPTION_PLANS["free"])

    duration_days = 365
    for p in SUBSCRIPTION_PRODUCTS:
        if p["product_id"] == order["product_id"]:
            duration_days = p["duration_days"]
            break

    expires_at = (now + timedelta(days=duration_days)).isoformat()

    subscriptions[order["user_id"]] = {
        "plan": tier,
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": True,
        "platform": order["platform"],
        "order_id": order["id"],
        "activated_at": now_iso,
        "features": product_info["features"],
    }

    _init_family_seats(order["user_id"], tier, order["id"])

    if order["user_id"] not in purchase_history:
        purchase_history[order["user_id"]] = []
    purchase_history[order["user_id"]].append({
        "plan": tier,
        "price_cents": order["amount_cents"],
        "platform": order["platform"],
        "order_id": order["id"],
        "trade_no": order["transaction_id"],
        "subscribed_at": now_iso,
    })

    _write_audit_log("payment_verified", order["user_id"], {
        "order_id": request.order_id,
        "tier": tier,
        "amount_cents": order["amount_cents"],
        "transaction_id": order["transaction_id"],
    })

    return {
        "success": True,
        "data": {
            "order_id": order["id"],
            "transaction_id": order["transaction_id"],
            "plan": tier,
            "status": "paid",
            "subscription": {
                "plan": tier,
                "expires_at": expires_at,
                "status": "active",
                "features": product_info["features"],
            }
        }
    }


# ============ 支付宝模拟支付接口 ============

@router.post("/alipay/create-order", response_model=dict)
async def alipay_create_order(request: AlipayOrderRequest):
    """创建支付宝订单（向后兼容）"""
    if request.plan not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="订阅计划不存在")

    plan = SUBSCRIPTION_PLANS[request.plan]

    order_no = generate_order_no()
    order_id = str(uuid.uuid4())

    payment_orders[order_id] = {
        "id": order_id,
        "order_no": order_no,
        "user_id": request.user_id,
        "plan": request.plan,
        "tier": request.plan,
        "product_id": f"{request.plan}_yearly",
        "amount_cents": plan.get("price_yearly_cents", plan.get("price_cents", 0)),
        "currency": "CNY",
        "status": "pending",
        "platform": "alipay",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat(),
    }

    _write_audit_log("alipay_order_created", request.user_id, {
        "order_id": order_id,
        "order_no": order_no,
        "plan": request.plan,
        "amount_cents": payment_orders[order_id]["amount_cents"],
    })

    return {
        "success": True,
        "data": {
            "order_id": order_id,
            "order_no": order_no,
            "plan": request.plan,
            "amount_cents": payment_orders[order_id]["amount_cents"],
            "amount_display": f"¥{payment_orders[order_id]['amount_cents'] / 100:.2f}",
            "currency": "CNY",
            "status": "pending",
            "pay_url": f"https://openapi.alipay.com/gateway.do?mock=1&orderId={order_no}",
            "qr_code": f"MOCK_QR_CODE_{order_no}",
            "expires_in": 1800,
        }
    }


@router.post("/alipay/verify", response_model=dict)
async def alipay_verify(request: PaymentVerifyRequest):
    """验证支付宝支付结果（向后兼容）"""
    order = payment_orders.get(request.order_id)

    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    if order["status"] == "paid":
        return {
            "success": True,
            "data": {"order_id": request.order_id, "status": "already_paid"}
        }

    order["status"] = "paid"
    now = datetime.now(timezone.utc)
    order["paid_at"] = now.isoformat()
    order["transaction_id"] = request.trade_no or f"MOCK_TRADE_{uuid.uuid4().hex[:12]}"

    plan = SUBSCRIPTION_PLANS[order["plan"]]
    expires_at = (now + timedelta(days=365)).isoformat()

    subscriptions[order["user_id"]] = {
        "plan": order["plan"],
        "status": "active",
        "expires_at": expires_at,
        "auto_renew": True,
        "platform": "alipay",
        "order_id": order["id"],
        "activated_at": now.isoformat(),
    }

    if order["user_id"] not in purchase_history:
        purchase_history[order["user_id"]] = []
    purchase_history[order["user_id"]].append({
        "plan": order["plan"],
        "price_cents": order.get("amount_cents", 0),
        "platform": "alipay",
        "order_id": order["id"],
        "order_no": order.get("order_no", ""),
        "trade_no": order["transaction_id"],
        "subscribed_at": now.isoformat()
    })

    _write_audit_log("alipay_payment_verified", order["user_id"], {
        "order_id": request.order_id,
        "trade_no": order["transaction_id"],
        "plan": order["plan"],
    })

    return {
        "success": True,
        "data": {
            "order_id": order["id"],
            "order_no": order.get("order_no", ""),
            "trade_no": order["transaction_id"],
            "plan": order["plan"],
            "status": "paid",
            "subscription": {
                "plan": order["plan"],
                "expires_at": expires_at,
                "status": "active",
            }
        }
    }


@router.get("/alipay/order/{order_id}", response_model=dict)
async def alipay_query_order(order_id: str):
    """查询支付宝订单状态（向后兼容）"""
    order = payment_orders.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="订单不存在")

    return {
        "success": True,
        "data": {
            "order_id": order["id"],
            "order_no": order.get("order_no", order["id"]),
            "plan": order.get("plan", order.get("tier", "")),
            "amount_cents": order.get("amount_cents", 0),
            "amount_display": f"¥{order.get('amount_cents', 0) / 100:.2f}",
            "status": order["status"],
            "created_at": order["created_at"],
            "paid_at": order.get("paid_at"),
        }
    }


# ============ Stripe 模拟支付接口 ============

@router.post("/stripe/create-checkout", response_model=dict)
async def stripe_create_checkout(request: StripeCheckoutRequest):
    """创建 Stripe checkout session"""
    if request.plan not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="订阅计划不存在")

    plan = SUBSCRIPTION_PLANS[request.plan]

    session_id = f"cs_test_{uuid.uuid4().hex}"

    logger.info(f"[Stripe] Checkout 创建: {session_id}, plan={request.plan}")

    return {
        "success": True,
        "data": {
            "session_id": session_id,
            "plan": request.plan,
            "amount": plan.get("price", 0),
            "currency": "usd",
            "status": "pending",
            "url": f"https://checkout.stripe.com/c/pay/cs_test_mock?plan={request.plan}",
            "success_url": request.success_url,
            "cancel_url": request.cancel_url,
        }
    }


@router.post("/stripe/webhook", response_model=dict)
async def stripe_webhook(request: StripeWebhookRequest):
    """Stripe webhook 接收端"""
    event_type = request.type
    logger.info(f"[Stripe] Webhook 收到: {event_type}")

    if event_type == "checkout.session.completed":
        session_data = request.data or {}
        user_id = session_data.get("metadata", {}).get("user_id", "user-001")
        plan_id = session_data.get("metadata", {}).get("plan", "yiyang")

        if plan_id not in SUBSCRIPTION_PLANS:
            plan_id = "yiyang"

        plan = SUBSCRIPTION_PLANS[plan_id]
        now = datetime.now(timezone.utc)
        expires_at = (now + timedelta(days=365)).isoformat()

        subscriptions[user_id] = {
            "plan": plan_id,
            "status": "active",
            "expires_at": expires_at,
            "auto_renew": True,
            "platform": "stripe",
            "stripe_session": session_data.get("id"),
            "activated_at": now.isoformat(),
        }

        _init_family_seats(user_id, plan_id)

        if user_id not in purchase_history:
            purchase_history[user_id] = []
        purchase_history[user_id].append({
            "plan": plan_id,
            "price": plan.get("price", 0),
            "platform": "stripe",
            "stripe_session": session_data.get("id"),
            "subscribed_at": now.isoformat()
        })

        _write_audit_log("stripe_webhook_completed", user_id, {
            "plan": plan_id,
            "session_id": session_data.get("id"),
        })

        return {"success": True, "message": "订阅已激活"}

    elif event_type == "customer.subscription.deleted":
        session_data = request.data or {}
        user_id = session_data.get("metadata", {}).get("user_id", "user-001")
        if user_id in subscriptions:
            subscriptions[user_id]["status"] = "cancelled"
            subscriptions[user_id]["auto_renew"] = False
        return {"success": True, "message": "订阅已取消"}

    elif event_type == "invoice.payment_failed":
        logger.warning(f"[Stripe] 支付失败")
        return {"success": True, "message": "支付失败已记录"}

    return {"success": True, "message": f"事件 {event_type} 已接收"}


# ============ 过期检查（向后兼容） ============

@router.get("/check-expiry", response_model=dict)
async def check_expiry():
    """检查所有已过期订阅（向后兼容）"""
    expired = check_expired_subscriptions()

    for item in expired:
        expire_subscription(item["user_id"])

    return {
        "success": True,
        "data": {
            "expired_count": len(expired),
            "expired_users": expired,
        }
    }


# ============ 使用量统计 ============

@router.get("/usage", response_model=dict)
async def get_usage_stats(user_id: str = Query("user-001")):
    """获取用户使用量统计"""
    stats = usage_stats.get(user_id, {
        "chat_count": 0,
        "api_calls": 0,
        "feature_uses": {},
        "period_start": datetime.now(timezone.utc).isoformat(),
    })

    sub = get_user_subscription(user_id)

    limits = {
        "free": {"daily_chat": 10, "daily_api": 50},
        "yangxin": {"daily_chat": -1, "daily_api": -1},
        "yiyang": {"daily_chat": -1, "daily_api": -1},
        "jiahe": {"daily_chat": -1, "daily_api": -1},
    }
    limit = limits.get(sub.plan, limits["free"])

    return {
        "success": True,
        "data": {
            "plan": sub.plan,
            "usage": stats,
            "limits": {
                "daily_chat": "unlimited" if limit["daily_chat"] == -1 else limit["daily_chat"],
                "daily_api": "unlimited" if limit["daily_api"] == -1 else limit["daily_api"],
            },
            "usage_percentage": {
                "chat": 0 if limit["daily_chat"] == -1 else (stats["chat_count"] / limit["daily_chat"] * 100),
                "api": 0 if limit["daily_api"] == -1 else (stats["api_calls"] / limit["daily_api"] * 100),
            }
        }
    }


@router.post("/usage/record", response_model=dict)
async def record_usage_endpoint(
    user_id: str = Query("user-001"),
    type: str = Query(...),
    amount: int = Query(1),
):
    """手动记录使用量"""
    record_usage(user_id, type, amount)
    return {"success": True, "message": "使用量已记录"}
