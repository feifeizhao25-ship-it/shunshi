"""
顺时 ShunShi - Stripe 支付服务 (GL版/国际版)
支持: 创建 Checkout / Portal / Webhook 处理 / 订阅管理
缺少 Stripe 配置时所有支付写操作失败关闭。

产品:
  serenity  ($9.99/月)  - 个人基础版
  harmony   ($19.99/月) - 个人增强版
  family    ($29.99/月) - 家庭版
"""
from __future__ import annotations
import os
import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional

from pydantic import BaseModel

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

STRIPE_MODE = os.getenv("STRIPE_MODE", "live")

STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")
STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY", "").strip()

STRIPE_PRICE_IDS: dict[str, str] = {
    "serenity": os.getenv("STRIPE_PRICE_SERENITY", "").strip(),
    "harmony": os.getenv("STRIPE_PRICE_HARMONY", "").strip(),
    "family": os.getenv("STRIPE_PRICE_FAMILY", "").strip(),
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
        if STRIPE_SECRET_KEY:
            try:
                import stripe
                stripe.api_key = STRIPE_SECRET_KEY
                self._configured = True
                logger.info(f"[Stripe] SDK 初始化完成 (mode={self.mode})")
            except ImportError:
                logger.error("[Stripe] stripe 包未安装，支付服务不可用")
        else:
            logger.warning("[Stripe] 无有效密钥，支付服务不可用")

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
            logger.warning("Stripe key not configured, payment disabled")
            raise RuntimeError("支付服务未配置，请联系管理员")

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
            logger.warning("Stripe key not configured, billing portal disabled")
            raise RuntimeError("支付服务未配置，请联系管理员")

    def verify_webhook(
        self,
        payload: bytes,
        sig_header: str,
    ) -> dict:
        """验证 Webhook 签名并返回事件"""
        if not self._configured or not STRIPE_WEBHOOK_SECRET:
            raise RuntimeError("Stripe Webhook 未配置")
        if not sig_header:
            raise ValueError("Stripe-Signature 请求头缺失")
        import stripe
        return stripe.Webhook.construct_event(payload, sig_header, STRIPE_WEBHOOK_SECRET)

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


# ==================== PaymentGateway 适配器 ====================


class StripeGateway:
    """Stripe PaymentGateway 适配器 — 委托给 StripeService 单例"""

    def __init__(self) -> None:
        self._svc = stripe_service

    async def create_order(self, user_id: str, amount: float, currency: str,
                           description: str, metadata: dict = None) -> "PaymentResult":  # noqa: F821
        """创建支付订单（Stripe Checkout Session）"""
        try:
            # metadata 中传递 plan_id 以复用现有 checkout 逻辑
            plan_id = (metadata or {}).get("plan_id", "serenity")
            result = self._svc.create_checkout_session(
                plan_id=plan_id, user_id=user_id,
            )
            from .payment_gateway import PaymentResult
            return PaymentResult(
                success=True,
                order_id=result.session_id,
                transaction_id=result.session_id,
                amount=amount,
                currency=currency,
                message="Checkout session created",
                raw_response={"checkout_url": result.checkout_url, "mode": result.mode},
            )
        except Exception as e:
            from .payment_gateway import PaymentResult
            return PaymentResult(
                success=False, order_id="", amount=amount, currency=currency,
                message=str(e),
            )

    async def verify_callback(self, request_data: dict) -> "PaymentResult":  # noqa: F821
        """字典回调无法携带可验证原始载荷，必须拒绝。"""
        from .payment_gateway import PaymentResult
        return PaymentResult(
            success=False,
            order_id="",
            message="Stripe 回调必须通过带原始请求体和签名的 verify_webhook 入口",
        )

    async def query_order(self, order_id: str) -> "PaymentResult":  # noqa: F821
        """此适配器尚未实现可靠的 Stripe Session 查询。"""
        from .payment_gateway import PaymentResult
        return PaymentResult(
            success=False, order_id=order_id,
            message="请通过已验签 Stripe Webhook 更新订单状态",
        )

    async def refund(self, order_id: str, amount: float, reason: str = "") -> "RefundResult":  # noqa: F821
        """发起退款 — Stripe refund 需 SDK，stub 实现"""
        from .payment_gateway import RefundResult
        if self._svc._configured:
            try:
                import stripe as _stripe
                session = _stripe.checkout.Session.retrieve(order_id)
                payment_intent = session.payment_intent
                refund_obj = _stripe.Refund.create(
                    payment_intent=payment_intent,
                    amount=int(amount * 100),  # Stripe uses cents
                    reason="requested_by_customer",
                    metadata={"reason": reason},
                )
                return RefundResult(
                    success=True, refund_id=refund_obj.id,
                    amount=amount, message="Refund issued",
                )
            except Exception as e:
                return RefundResult(success=False, amount=amount, message=str(e))
        return RefundResult(success=False, amount=amount, message="Stripe not configured")

    async def verify_webhook(self, headers: dict, body: bytes) -> "PaymentResult":  # noqa: F821
        """验证 Webhook 签名"""
        from .payment_gateway import PaymentResult
        try:
            sig = headers.get("stripe-signature", headers.get("Stripe-Signature", ""))
            event = self._svc.verify_webhook(payload=body, sig_header=sig)
            return PaymentResult(
                success=True, order_id="",
                message="Webhook verified",
                raw_response=event,
            )
        except Exception as e:
            return PaymentResult(success=False, order_id="", message=str(e))


# ==================== 单例 ====================

stripe_service = StripeService()
