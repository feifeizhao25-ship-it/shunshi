"""
SEASONS Global Version - Subscription Management API
"""

import os
import logging
import stripe
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Any
from fastapi import APIRouter, Query, HTTPException, Header, Request
from pydantic import BaseModel
from pydantic import Field

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/seasons/subscription", tags=["seasons-subscription"])

# In-memory subscription state
subscriptions_db: dict = {}

TRIAL_DAYS = {"serenity": 7, "harmony": 14, "family": 14}

SUBSCRIPTION_PLANS = {
    "serenity": {
        "name": "Serenity",
        "monthly_price": 9.99,
        "yearly_price": 79.99,
        "trial_days": 7,
        "features": [
            "Unlimited AI conversations",
            "Full content library",
            "Audio guides & soundscapes",
            "Weekly reflection summaries",
        ],
    },
    "harmony": {
        "name": "Harmony",
        "monthly_price": 14.99,
        "yearly_price": 119.99,
        "trial_days": 14,
        "intro_offer_price": 0.99,
        "intro_offer_days": 7,
        "features": [
            "Everything in Serenity",
            "Exclusive Harmony content",
            "Advanced weekly summaries",
            "Custom rituals builder",
        ],
    },
    "family": {
        "name": "Family",
        "monthly_price": 19.99,
        "yearly_price": 159.99,
        "trial_days": 14,
        "intro_offer_price": 1.99,
        "intro_offer_days": 7,
        "features": [
            "Everything in Harmony",
            "Up to 4 family members",
            "Shared family dashboard",
            "Individual profiles",
        ],
    },
}


class CheckoutRequest(BaseModel):
    product_id: str
    billing: str  # "monthly" or "yearly"
    offer_code: Optional[str] = None


class TrialRequest(BaseModel):
    product_id: str


class ValidateCodeRequest(BaseModel):
    code: str


class RestoreRequest(BaseModel):
    """Restore purchases request — accepts iOS receipt_data or Android purchase_token."""
    user_id: str
    receipt_data: Optional[str] = Field(None, description="iOS base64 App Store receipt")
    purchase_token: Optional[str] = Field(None, description="Android purchase token")
    platform: Optional[str] = Field("ios", description="ios or android")


class StripeWebhookRequest(BaseModel):
    """Stripe webhook event payload."""
    type: str
    data: Optional[dict] = None
    livemode: Optional[bool] = False


@router.get("/status")
async def get_subscription_status(user_id: str = Query(...)):
    """Get current subscription status for a user"""
    sub = subscriptions_db.get(user_id, {})
    
    now = datetime.now()
    tier = sub.get("tier", "free")
    expires_at = sub.get("expires_at")
    trial_ends_at = sub.get("trial_ends_at")
    
    is_in_trial = False
    if trial_ends_at:
        try:
            trial_end = datetime.fromisoformat(trial_ends_at)
            is_in_trial = trial_end > now
        except Exception as e:            pass
    
    return {
        "tier": tier,
        "product_id": sub.get("product_id"),
        "status": sub.get("status", "active"),
        "expires_at": expires_at,
        "trial_ends_at": trial_ends_at,
        "is_in_trial": is_in_trial,
        "is_in_intro_offer": sub.get("is_in_intro_offer", False),
        "billing": sub.get("billing"),
    }


@router.post("/trial")
async def start_trial(body: TrialRequest, user_id: str = Query(...)):
    """Legacy client-granted trials are retired; Stripe owns trial eligibility."""
    raise HTTPException(status_code=410, detail="Start trials through Stripe Checkout")


@router.post("/checkout")
async def create_checkout(body: CheckoutRequest, user_id: str = Query(...)):
    """Create a Stripe checkout session URL"""
    product_id = body.product_id
    billing = body.billing
    
    if product_id not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="Invalid product")
    
    if billing not in {"monthly", "yearly"}:
        raise HTTPException(status_code=400, detail="Invalid billing period")
    secret_key = os.getenv("STRIPE_SECRET_KEY", "").strip()
    price_id = os.getenv(f"STRIPE_PRICE_{product_id.upper()}_{billing.upper()}", "").strip()
    success_url = os.getenv("SEASONS_CHECKOUT_SUCCESS_URL", "").strip()
    cancel_url = os.getenv("SEASONS_CHECKOUT_CANCEL_URL", "").strip()
    if not all((secret_key, price_id, success_url, cancel_url)):
        raise HTTPException(status_code=503, detail="Stripe checkout is not configured")
    stripe.api_key = secret_key
    try:
        session = stripe.checkout.Session.create(
            mode="subscription",
            line_items=[{"price": price_id, "quantity": 1}],
            success_url=success_url,
            cancel_url=cancel_url,
            metadata={"user_id": user_id, "plan_id": product_id},
            subscription_data={
                "metadata": {"user_id": user_id, "plan": product_id},
                "trial_period_days": TRIAL_DAYS[product_id],
            },
        )
    except stripe.error.StripeError as exc:
        logger.exception("[SEASONS Stripe] checkout creation failed")
        raise HTTPException(status_code=502, detail="Stripe checkout failed") from exc
    return {
        "checkout_url": session.url,
        "session_id": session.id,
    }


@router.post("/restore")
async def restore_purchases(body: Optional[RestoreRequest] = None, user_id: Optional[str] = Query(None)):
    """Retired because this route cannot verify App Store or Play receipts."""
    raise HTTPException(status_code=410, detail="Use the verified App Store or Google Play receipt endpoint")


# Global purchase history for SEASONS Global (separate from CN version)
_seasons_purchase_history: dict = {}


@router.post("/validate-code")
async def validate_offer_code(body: ValidateCodeRequest, user_id: str = Query(...)):
    """Legacy hard-coded offer codes are retired; use Stripe Promotion Codes."""
    raise HTTPException(status_code=410, detail="Validate promotion codes during Stripe Checkout")


@router.get("/products")
async def get_products():
    """Get all available subscription products"""
    products = []
    for pid, plan in SUBSCRIPTION_PLANS.items():
        products.append({
            "id": pid,
            "name": plan["name"],
            "monthly_price": plan["monthly_price"],
            "yearly_price": plan["yearly_price"],
            "trial_days": plan.get("trial_days", 0),
            "has_intro_offer": "intro_offer_price" in plan,
            "intro_offer_price": plan.get("intro_offer_price"),
            "features": plan["features"],
        })
    return products


# ── Stripe Webhook ─────────────────────────────────────────────

@router.post("/webhook/stripe")
async def stripe_webhook(request: Request):
    """
    Handle Stripe webhook events.

    Handles:
    - customer.subscription.updated
    - customer.subscription.deleted
    - invoice.paid

    Returns 200 OK for all handled events (required by Stripe).
    """
    body = await request.body()
    signature = request.headers.get("stripe-signature", "")
    secret_key = os.getenv("STRIPE_SECRET_KEY", "").strip()
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "").strip()
    if not secret_key or not webhook_secret:
        raise HTTPException(status_code=503, detail="Stripe webhook is not configured")
    if not signature:
        raise HTTPException(status_code=400, detail="Missing Stripe signature")
    stripe.api_key = secret_key
    try:
        event = stripe.Webhook.construct_event(body, signature, webhook_secret)
        event_type = event.get("type", "")
        data_object = event.get("data", {}).get("object", {})

        logger.info(f"[Stripe Webhook] Received event: {event_type}")

        if event_type == "customer.subscription.updated":
            _handle_subscription_updated(data_object)
        elif event_type == "customer.subscription.deleted":
            _handle_subscription_deleted(data_object)
        elif event_type == "invoice.paid":
            _handle_invoice_paid(data_object)
        else:
            logger.info(f"[Stripe Webhook] Unhandled event type: {event_type}")

    except (stripe.error.SignatureVerificationError, ValueError) as exc:
        raise HTTPException(status_code=400, detail="Invalid Stripe signature") from exc
    except Exception as exc:
        logger.exception("[Stripe Webhook] Error processing webhook")
        raise HTTPException(status_code=500, detail="Webhook processing failed") from exc

    return {"received": True}


def _handle_subscription_updated(data: dict):
    """Handle customer.subscription.updated event."""
    customer_id = data.get("customer", "")
    subscription_id = data.get("id", "")
    status = data.get("status", "")
    metadata = data.get("metadata", {})
    user_id = metadata.get("user_id", customer_id)

    plan_id = metadata.get("plan", "serenity")
    if plan_id not in SUBSCRIPTION_PLANS:
        plan_id = "serenity"

    now = datetime.now(timezone.utc)

    if status == "active":
        # Get current period end
        current_period_end = data.get("current_period_end")
        if current_period_end:
            try:
                from datetime import datetime as dt
                expires_at = dt.fromtimestamp(current_period_end, tz=timezone.utc).isoformat()
            except Exception:
                expires_at = (now + timedelta(days=30)).isoformat()
        else:
            expires_at = (now + timedelta(days=30)).isoformat()

        subscriptions_db[user_id] = {
            "tier": plan_id,
            "product_id": plan_id,
            "status": "active",
            "expires_at": expires_at,
            "subscription_id": subscription_id,
            "platform": "stripe",
            "auto_renew": True,
        }

        # Record in purchase history
        global _seasons_purchase_history
        if user_id not in _seasons_purchase_history:
            _seasons_purchase_history[user_id] = []
        _seasons_purchase_history[user_id].append({
            "tier": plan_id,
            "platform": "stripe",
            "subscription_id": subscription_id,
            "expires_at": expires_at,
            "renewed_at": now.isoformat(),
        })

        logger.info(f"[Stripe Webhook] Subscription updated to active: user={user_id}, plan={plan_id}")

    elif status in ("canceled", "unpaid", "past_due"):
        if user_id in subscriptions_db:
            subscriptions_db[user_id]["status"] = "cancelled"
            subscriptions_db[user_id]["auto_renew"] = False
        logger.info(f"[Stripe Webhook] Subscription cancelled: user={user_id}, status={status}")


def _handle_subscription_deleted(data: dict):
    """Handle customer.subscription.deleted event."""
    customer_id = data.get("customer", "")
    metadata = data.get("metadata", {})
    user_id = metadata.get("user_id", customer_id)

    if user_id in subscriptions_db:
        subscriptions_db[user_id]["status"] = "cancelled"
        subscriptions_db[user_id]["tier"] = "free"
        subscriptions_db[user_id]["auto_renew"] = False

    logger.info(f"[Stripe Webhook] Subscription deleted: user={user_id}")


def _handle_invoice_paid(data: dict):
    """Handle invoice.paid event — renewal payment successful."""
    customer_id = data.get("customer", "")
    subscription_id = data.get("subscription", "")
    metadata = data.get("metadata", {})
    user_id = metadata.get("user_id", customer_id)

    # Extend subscription
    now = datetime.now(timezone.utc)
    period_end = data.get("period_end")
    if period_end:
        try:
            from datetime import datetime as dt
            expires_at = dt.fromtimestamp(period_end, tz=timezone.utc).isoformat()
        except Exception:
            expires_at = (now + timedelta(days=30)).isoformat()
    else:
        expires_at = (now + timedelta(days=30)).isoformat()

    if user_id in subscriptions_db:
        subscriptions_db[user_id]["expires_at"] = expires_at
        subscriptions_db[user_id]["status"] = "active"

    logger.info(f"[Stripe Webhook] Invoice paid — subscription renewed: user={user_id}, expires={expires_at}")
