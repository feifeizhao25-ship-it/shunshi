# Stripe 支付 API 路由
# 国际版 SEASONS 专用 - 使用 Stripe Checkout 处理订阅支付
# 注意: 当前使用 Stripe 测试模式 (sk_test_)
import stripe
import os
import logging
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Request, Query
from pydantic import BaseModel

from app.database.db import get_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/stripe", tags=["Stripe支付"])

# ============ 配置 ============

STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "sk_test_placeholder")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_placeholder")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_placeholder")

# Stripe 价格 ID (需要在 Stripe Dashboard 中创建)
# 测试模式下创建 Price Objects 后填入
STRIPE_PRICE_IDS = {
    "serenity": os.getenv("STRIPE_PRICE_SERENITY", "price_serenity_monthly"),
    "harmony": os.getenv("STRIPE_PRICE_HARMONY", "price_harmony_monthly"),
    "family": os.getenv("STRIPE_PRICE_FAMILY", "price_family_monthly"),
}

# 初始化 Stripe SDK (仅在配置了有效 key 时)
_stripe_configured = False
if STRIPE_SECRET_KEY and not STRIPE_SECRET_KEY.startswith("sk_test_placeholder"):
    stripe.api_key = STRIPE_SECRET_KEY
    _stripe_configured = True
    logger.info("[Stripe] SDK 初始化完成 (测试模式)")
else:
    logger.warning("[Stripe] 未配置有效密钥，运行在模拟模式")

# ============ 英文版订阅计划 (USD) ============

SUBSCRIPTION_PLANS_EN = {
    "free": {
        "id": "free",
        "name": "Free",
        "price": 0,
        "currency": "usd",
        "period": None,
        "features": [
            "5 messages per day",
            "Basic content library",
            "Limited reflections",
            "Daily suggestions",
        ],
        "description": "Start your wellness journey",
    },
    "serenity": {
        "id": "serenity",
        "name": "Serenity",
        "price": 9.99,
        "currency": "usd",
        "period": "month",
        "features": [
            "Unlimited AI companion",
            "All content library",
            "Seasonal insights",
            "Unlimited reflections",
            "Sleep audio & stories",
        ],
        "description": "Perfect for personal wellness",
    },
    "harmony": {
        "id": "harmony",
        "name": "Harmony",
        "price": 19.99,
        "currency": "usd",
        "period": "month",
        "features": [
            "Everything in Serenity",
            "Family features",
            "Priority support",
            "Weekly AI insights",
            "Advanced seasonal programs",
        ],
        "description": "Enhanced wellness with family care",
    },
    "family": {
        "id": "family",
        "name": "Family",
        "price": 29.99,
        "currency": "usd",
        "period": "month",
        "features": [
            "Everything in Harmony",
            "Up to 5 family members",
            "Shared family insights",
            "Family wellness plans",
            "Dedicated support",
        ],
        "description": "Wellness for the whole family",
    },
}

# ============ Models ============

class CreateCheckoutRequest(BaseModel):
    plan_id: str
    user_id: str = "user-001"
    locale: str = "en-US"
    success_url: Optional[str] = "https://app.seasons.care/payment/success"
    cancel_url: Optional[str] = "https://app.seasons.care/payment/cancel"


# ============ Helper ============

def _get_plan_or_404(plan_id: str) -> dict:
    """获取英文版计划，不存在则 404"""
    plan = SUBSCRIPTION_PLANS_EN.get(plan_id)
    if not plan:
        raise HTTPException(status_code=400, detail=f"Plan '{plan_id}' not found")
    return plan


def _activate_subscription(user_id: str, plan_id: str, stripe_customer_id: Optional[str] = None,
                           stripe_subscription_id: Optional[str] = None) -> dict:
    """在数据库中激活用户订阅"""
    db = get_db()
    now = datetime.now().isoformat()
    expires_at = (datetime.now() + timedelta(days=30)).isoformat()  # 一个月

    # 更新 users 表的订阅状态
    db.execute("""
        UPDATE users SET
            subscription_plan = ?,
            is_premium = 1,
            subscription_expires_at = ?,
            updated_at = ?
        WHERE id = ?
    """, (plan_id, expires_at, now, user_id))

    # 写入 subscriptions 表
    sub_id = f"sub_{datetime.now().strftime('%Y%m%d%H%M%S')}_{user_id}"
    db.execute("""
        INSERT OR REPLACE INTO subscriptions (id, user_id, plan, status, started_at, expires_at, auto_renew, platform, subscribed_at)
        VALUES (?, ?, ?, 'active', ?, ?, 1, 'stripe', ?)
    """, (sub_id, user_id, plan_id, now, expires_at, now))

    # 写入购买历史
    plan = SUBSCRIPTION_PLANS_EN.get(plan_id, SUBSCRIPTION_PLANS_EN["serenity"])
    db.execute("""
        INSERT INTO purchase_history (id, user_id, plan, price, platform, receipt, subscribed_at)
        VALUES (?, ?, ?, ?, 'stripe', ?, ?)
    """, (f"ph_{sub_id}", user_id, plan_id, int(plan["price"] * 100), stripe_subscription_id or "", now))

    db.commit()
    logger.info(f"[Stripe] 订阅激活: user={user_id}, plan={plan_id}, expires={expires_at}")

    return {
        "user_id": user_id,
        "plan": plan_id,
        "status": "active",
        "expires_at": expires_at,
        "stripe_customer_id": stripe_customer_id,
        "stripe_subscription_id": stripe_subscription_id,
    }


# ============ API Endpoints ============

@router.get("/plans", response_model=dict)
async def get_plans(locale: str = Query("en-US")):
    """
    获取订阅计划列表
    - locale=en-US → 返回英文计划名和 USD 价格
    - locale=zh-CN → 返回中文计划名和 ¥ 价格 (向后兼容)
    """
    plans = []
    for key, plan in SUBSCRIPTION_PLANS_EN.items():
        plans.append({
            "id": plan["id"],
            "name": plan["name"],
            "price": plan["price"],
            "currency": plan["currency"],
            "period": plan.get("period"),
            "features": plan["features"],
            "description": plan["description"],
        })

    return {"success": True, "data": plans}


@router.get("/config", response_model=dict)
async def get_stripe_config():
    """返回前端需要的 Stripe 配置 (publishable key)"""
    return {
        "success": True,
        "data": {
            "publishable_key": STRIPE_PUBLISHABLE_KEY,
        }
    }


@router.post("/create-checkout-session", response_model=dict)
async def create_checkout_session(request: CreateCheckoutRequest):
    """
    创建 Stripe Checkout Session
    前端拿到 checkout_url 后跳转到 Stripe 支付页面
    """
    plan = _get_plan_or_404(request.plan_id)

    if plan["price"] == 0:
        raise HTTPException(status_code=400, detail="Free plan does not require checkout")

    price_id = STRIPE_PRICE_IDS.get(request.plan_id)
    if not price_id:
        logger.warning(f"[Stripe] 未配置价格 ID: {request.plan_id}")

    if _stripe_configured and price_id:
        # 真实 Stripe 调用
        try:
            session = stripe.checkout.Session.create(
                payment_method_types=["card"],
                mode="subscription",
                line_items=[{"price": price_id, "quantity": 1}],
                success_url=request.success_url,
                cancel_url=request.cancel_url,
                metadata={
                    "user_id": request.user_id,
                    "plan_id": request.plan_id,
                    "locale": request.locale,
                },
                subscription_data={
                    "metadata": {
                        "user_id": request.user_id,
                        "plan_id": request.plan_id,
                    },
                    "trial_period_days": 7,  # 7 天免费试用
                },
                locale=request.locale.split("-")[0],  # Stripe locale: "en"
            )

            return {
                "success": True,
                "data": {
                    "checkout_url": session.url,
                    "session_id": session.id,
                }
            }
        except stripe.error.StripeError as e:
            logger.error(f"[Stripe] 创建 checkout 失败: {e}")
            raise HTTPException(status_code=500, detail=f"Stripe error: {str(e)}")

    else:
        # 模拟模式: 返回 mock URL
        import uuid
        session_id = f"cs_test_{uuid.uuid4().hex[:24]}"
        mock_url = f"https://checkout.stripe.com/c/pay/{session_id}?mock=1"

        logger.info(f"[Stripe] 模拟模式 - Checkout 创建: {session_id}, plan={request.plan_id}")

        return {
            "success": True,
            "data": {
                "checkout_url": mock_url,
                "session_id": session_id,
                "mode": "test",
            }
        }


@router.post("/create-portal-session", response_model=dict)
async def create_portal_session(user_id: str = Query("user-001")):
    """
    创建 Stripe Customer Portal Session
    用户可在此管理订阅: 升级、降级、取消
    """
    db = get_db()
    row = db.execute("SELECT stripe_customer_id FROM users WHERE id = ?", (user_id,)).fetchone()
    customer_id = row["stripe_customer_id"] if row else None

    if not customer_id:
        raise HTTPException(status_code=404, detail="No Stripe customer found for this user")

    if _stripe_configured:
        try:
            session = stripe.billing_portal.Session.create(
                customer=customer_id,
                return_url="https://app.seasons.care/profile",
            )
            return {
                "success": True,
                "data": {"portal_url": session.url}
            }
        except stripe.error.StripeError as e:
            raise HTTPException(status_code=500, detail=f"Stripe error: {str(e)}")
    else:
        return {
            "success": True,
            "data": {
                "portal_url": "https://billing.stripe.com/p/mock_portal",
                "mode": "test",
            }
        }


@router.post("/webhook", response_model=dict)
async def stripe_webhook(request: Request):
    """
    Stripe Webhook 端点
    处理: checkout.session.completed, customer.subscription.updated, customer.subscription.deleted
    需要验证 stripe-signature
    """
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    if _stripe_configured and STRIPE_WEBHOOK_SECRET:
        # 真实验签
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, STRIPE_WEBHOOK_SECRET
            )
        except (stripe.error.SignatureVerificationError, ValueError) as e:
            logger.error(f"[Stripe] Webhook 验签失败: {e}")
            raise HTTPException(status_code=400, detail="Invalid signature")
    else:
        # 模拟模式: 直接解析 JSON
        import json
        try:
            event = json.loads(payload)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid payload")

    event_type = event.get("type", "")
    data = event.get("data", {}).get("object", {})
    logger.info(f"[Stripe] Webhook 事件: {event_type}")

    try:
        if event_type == "checkout.session.completed":
            # 支付成功 - 激活订阅
            user_id = data.get("metadata", {}).get("user_id", "")
            plan_id = data.get("metadata", {}).get("plan_id", "serenity")
            customer_id = data.get("customer")
            subscription_id = data.get("subscription")

            if not user_id:
                logger.warning("[Stripe] checkout.session.completed 缺少 user_id")
                return {"success": False, "error": "missing user_id in metadata"}

            # 保存 stripe_customer_id 到用户表
            if customer_id:
                db = get_db()
                db.execute("""
                    UPDATE users SET stripe_customer_id = ? WHERE id = ?
                """, (customer_id, user_id))
                db.commit()

            result = _activate_subscription(user_id, plan_id, customer_id, subscription_id)
            logger.info(f"[Stripe] 订阅已激活: user={user_id}, plan={plan_id}")

        elif event_type == "customer.subscription.updated":
            # 订阅变更 (升级/降级)
            user_id = data.get("metadata", {}).get("user_id", "")
            new_plan_id = data.get("metadata", {}).get("plan_id", "")
            status = data.get("status")

            if user_id and new_plan_id and status == "active":
                db = get_db()
                db.execute("""
                    UPDATE users SET subscription_plan = ?, updated_at = ?
                    WHERE id = ?
                """, (new_plan_id, datetime.now().isoformat(), user_id))
                db.commit()
                logger.info(f"[Stripe] 订阅更新: user={user_id}, plan={new_plan_id}")

        elif event_type == "customer.subscription.deleted":
            # 订阅取消/过期
            user_id = data.get("metadata", {}).get("user_id", "")
            if user_id:
                db = get_db()
                db.execute("""
                    UPDATE users SET
                        subscription_plan = 'free',
                        is_premium = 0,
                        subscription_expires_at = NULL,
                        updated_at = ?
                    WHERE id = ?
                """, (datetime.now().isoformat(), user_id))
                db.commit()
                logger.info(f"[Stripe] 订阅已取消: user={user_id}")

        elif event_type == "invoice.payment_failed":
            logger.warning(f"[Stripe] 支付失败: {data.get('id')}")

        else:
            logger.debug(f"[Stripe] 忽略事件: {event_type}")

    except Exception as e:
        logger.error(f"[Stripe] Webhook 处理异常: {e}", exc_info=True)
        # 不抛异常，返回 200 避免 Stripe 重试导致问题
        return {"success": False, "error": str(e)}

    return {"success": True, "received": True}
