"""
顺时 ShunShi - Stripe 支付服务 (GL版/国际版)
支持: 创建 Checkout / Portal / Webhook 处理 / 订阅管理
Mock 模式: STRIPE_MODE=mock 或无有效密钥时自动降级

产品:
  serenity  ($9.99/月)  - 个人基础版
  harmony   ($19.99/月) - 个人增强版
  family    ($29.99/月) - 家庭版
"""
import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

STRIPE_MODE = os.getenv("STRIPE_MODE", "mock")  # mock / test / live

STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "pk_test_placeholder")

STRIPE_PRICE_IDS: dict[str, str] = {
    "serenity": os.getenv("STRIPE_PRICE_SERENITY", "price_serenity_monthly"),
    "harmony": os.getenv("STRIPE_PRICE_HARMONY", "price_harmony_monthly"),
    "family": os.getenv("STRIPE_PRICE_FAMILY", "price_family_monthly"),
}

# ==================== 产品定义 ====================

STRIPE_PRODUCTS: dict[str, dict] = {
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
    },
}


# ==================== 数据模型 ====================

class CheckoutResult(BaseModel):
    """Checkout Session 创建结果"""
    checkout_url: str
    session_id: str
    mode: str = "test"


class PortalResult(BaseModel):
    """Customer Portal 结果"""
    portal_url: str
    mode: str = "test"


class WebhookResult(BaseModel):
    """Webhook 处理结果"""
    event_type: str
    user_id: str = ""
    plan_id: str = ""
    success: bool = True
    error: str = ""


# ==================== 服务实现 ====================

class StripeService:
    """Stripe 支付服务"""

    def __init__(self) -> None:
        self.mode = STRIPE_MODE
        self._configured = False
        self._init_sdk()

    def _init_sdk(self) -> None:
        """初始化 Stripe SDK"""
        if self.mode == "mock":
            return

        if STRIPE_SECRET_KEY and not STRIPE_SECRET_KEY.startswith("sk_test_placeholder"):
            try:
                import stripe
                stripe.api_key = STRIPE_SECRET_KEY
                self._configured = True
                logger.info(f"[Stripe] SDK 初始化完成 (mode={self.mode})")
            except ImportError:
                logger.warning("[Stripe] stripe 包未安装，降级到 mock 模式")
                self.mode = "mock"
        else:
            logger.warning("[Stripe] 无有效密钥，运行 mock 模式")
            self.mode = "mock"

    def create_checkout_session(
        self,
        plan_id: str,
        user_id: str,
        locale: str = "en-US",
        success_url: Optional[str] = None,
        cancel_url: Optional[str] = None,
    ) -> CheckoutResult:
        """创建 Stripe Checkout Session"""
        plan = STRIPE_PRODUCTS.get(plan_id)
        if not plan:
            raise ValueError(f"未知计划: {plan_id}")
        if plan["price"] == 0:
            raise ValueError("免费计划无需支付")

        price_id = STRIPE_PRICE_IDS.get(plan_id)

        if self._configured and price_id:
            import stripe
            session = stripe.checkout.Session.create(
                payment_method_types=["card"],
                mode="subscription",
                line_items=[{"price": price_id, "quantity": 1}],
                success_url=success_url or "https://app.seasons.care/payment/success",
                cancel_url=cancel_url or "https://app.seasons.care/payment/cancel",
                metadata={"user_id": user_id, "plan_id": plan_id, "locale": locale},
                subscription_data={
                    "metadata": {"user_id": user_id, "plan_id": plan_id},
                    "trial_period_days": 7,
                },
                locale=locale.split("-")[0],
            )
            return CheckoutResult(
                checkout_url=session.url,
                session_id=session.id,
                mode=self.mode,
            )
        else:
            session_id = f"cs_test_{uuid.uuid4().hex[:24]}"
            return CheckoutResult(
                checkout_url=f"https://checkout.stripe.com/c/pay/{session_id}?mock=1",
                session_id=session_id,
                mode="test",
            )

    def create_portal_session(
        self,
        customer_id: str,
        return_url: str = "https://app.seasons.care/profile",
    ) -> PortalResult:
        """创建 Customer Portal Session"""
        if self._configured:
            import stripe
            session = stripe.billing_portal.Session.create(
                customer=customer_id,
                return_url=return_url,
            )
            return PortalResult(portal_url=session.url, mode=self.mode)
        else:
            return PortalResult(
                portal_url="https://billing.stripe.com/p/mock_portal",
                mode="test",
            )

    def verify_webhook(
        self,
        payload: bytes,
        sig_header: str,
    ) -> dict:
        """验证 Webhook 签名并返回事件"""
        if self._configured and STRIPE_WEBHOOK_SECRET:
            import stripe
            event = stripe.Webhook.construct_event(
                payload, sig_header, STRIPE_WEBHOOK_SECRET
            )
            return event
        else:
            try:
                return json.loads(payload)
            except json.JSONDecodeError:
                raise ValueError("Invalid webhook payload")

    def handle_webhook_event(self, event: dict) -> WebhookResult:
        """
        处理 Stripe Webhook 事件
        支持事件:
          - checkout.session.completed
          - customer.subscription.updated
          - customer.subscription.deleted
        """
        event_type: str = event.get("type", "")
        data: dict = event.get("data", {}).get("object", {})
        metadata: dict = data.get("metadata", {})

        user_id: str = metadata.get("user_id", "")
        plan_id: str = metadata.get("plan_id", "")

        try:
            if event_type == "checkout.session.completed":
                return self._handle_checkout_completed(data, user_id, plan_id)

            elif event_type == "customer.subscription.updated":
                return self._handle_subscription_updated(data, user_id, plan_id)

            elif event_type == "customer.subscription.deleted":
                return self._handle_subscription_deleted(data, user_id)

            elif event_type == "invoice.payment_failed":
                logger.warning(f"[Stripe] 支付失败: {data.get('id')}")
                return WebhookResult(event_type=event_type, success=True)

            else:
                logger.debug(f"[Stripe] 忽略事件: {event_type}")
                return WebhookResult(event_type=event_type, success=True)

        except Exception as e:
            logger.error(f"[Stripe] Webhook 处理异常: {e}", exc_info=True)
            return WebhookResult(
                event_type=event_type,
                success=False,
                error=str(e),
            )

    def _handle_checkout_completed(
        self, data: dict, user_id: str, plan_id: str
    ) -> WebhookResult:
        """处理 checkout.session.completed"""
        if not user_id:
            logger.warning("[Stripe] checkout.session.completed 缺少 user_id")
            return WebhookResult(
                event_type="checkout.session.completed",
                success=False,
                error="missing user_id in metadata",
            )

        # 在数据库中激活订阅
        from app.database.db import get_db
        db = get_db()
        now = datetime.now().isoformat()
        expires_at = (datetime.now() + timedelta(days=30)).isoformat()
        customer_id = data.get("customer")
        subscription_id = data.get("subscription")

        if customer_id:
            db.execute(
                "UPDATE users SET stripe_customer_id = ?, updated_at = ? WHERE id = ?",
                (customer_id, now, user_id),
            )

        db.execute(
            """INSERT OR REPLACE INTO subscriptions
               (id, user_id, plan, status, started_at, expires_at, auto_renew, platform, subscribed_at)
               VALUES (?, ?, ?, 'active', ?, ?, 1, 'stripe', ?)""",
            (f"sub_stripe_{uuid.uuid4().hex[:12]}", user_id, plan_id, now, expires_at, now),
        )
        db.commit()

        logger.info(f"[Stripe] 订阅激活: user={user_id}, plan={plan_id}")
        return WebhookResult(
            event_type="checkout.session.completed",
            user_id=user_id,
            plan_id=plan_id,
        )

    def _handle_subscription_updated(
        self, data: dict, user_id: str, plan_id: str
    ) -> WebhookResult:
        """处理 customer.subscription.updated"""
        status: str = data.get("status", "")
        if user_id and plan_id and status == "active":
            from app.database.db import get_db
            db = get_db()
            db.execute(
                "UPDATE users SET subscription_plan = ?, updated_at = ? WHERE id = ?",
                (plan_id, datetime.now().isoformat(), user_id),
            )
            db.commit()
            logger.info(f"[Stripe] 订阅更新: user={user_id}, plan={plan_id}")
        return WebhookResult(
            event_type="customer.subscription.updated",
            user_id=user_id,
            plan_id=plan_id,
        )

    def _handle_subscription_deleted(
        self, data: dict, user_id: str
    ) -> WebhookResult:
        """处理 customer.subscription.deleted"""
        if user_id:
            from app.database.db import get_db
            db = get_db()
            now = datetime.now().isoformat()
            db.execute(
                """UPDATE users SET
                   subscription_plan = 'free', is_premium = 0,
                   subscription_expires_at = NULL, updated_at = ?
                   WHERE id = ?""",
                (now, user_id),
            )
            db.commit()
            logger.info(f"[Stripe] 订阅取消: user={user_id}")
        return WebhookResult(
            event_type="customer.subscription.deleted",
            user_id=user_id,
        )

    def get_plans(self) -> list[dict]:
        """获取所有计划列表"""
        return [
            {
                "id": plan["id"],
                "name": plan["name"],
                "price": plan["price"],
                "currency": plan["currency"],
                "period": plan.get("period"),
                "features": plan["features"],
            }
            for plan in STRIPE_PRODUCTS.values()
        ]


# ==================== 单例 ====================

stripe_service = StripeService()
