"""
SEASONS Global Version - Subscription Management API
"""

import uuid
import json
import logging
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
        except:
            pass
    
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
    """Start a free trial"""
    product_id = body.product_id
    
    if product_id not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="Invalid product")
    
    plan = SUBSCRIPTION_PLANS[product_id]
    trial_days = plan.get("trial_days", 7)
    trial_end = datetime.now() + timedelta(days=trial_days)
    
    subscriptions_db[user_id] = {
        "tier": product_id,
        "product_id": product_id,
        "status": "trial",
        "trial_ends_at": trial_end.isoformat(),
        "started_at": datetime.now().isoformat(),
    }
    
    return {
        "success": True,
        "tier": product_id,
        "trial_ends_at": trial_end.isoformat(),
        "trial_days": trial_days,
    }


@router.post("/checkout")
async def create_checkout(body: CheckoutRequest, user_id: str = Query(...)):
    """Create a Stripe checkout session URL"""
    product_id = body.product_id
    billing = body.billing
    
    if product_id not in SUBSCRIPTION_PLANS:
        raise HTTPException(status_code=400, detail="Invalid product")
    
    plan = SUBSCRIPTION_PLANS[product_id]
    
    # In production, this would create a real Stripe checkout session
    # For now, return a mock URL
    price = plan["yearly_price"] if billing == "yearly" else plan["monthly_price"]
    
    return {
        "checkout_url": f"https://checkout.seasons.app/session?product={product_id}&billing={billing}&user={user_id}",
        "session_id": f"cs_{uuid.uuid4().hex[:24]}",
        "amount": price,
        "currency": "usd",
        "product_name": plan["name"],
    }


@router.post("/restore")
async def restore_purchases(body: Optional[RestoreRequest] = None, user_id: Optional[str] = Query(None)):
    """
    Restore purchases from app stores.

    Accepts either JSON body (RestoreRequest) or query params.
    For iOS: provide receipt_data (base64 App Store receipt)
    For Android: provide purchase_token (Google Play purchase token)

    Returns the restored subscription tier and status.
    """
    # Support both body and query params for backward compatibility
    if body is not None:
        uid = body.user_id or user_id or "unknown"
        receipt = body.receipt_data
        token = body.purchase_token
        platform = body.platform or "ios"
    else:
        uid = user_id or "unknown"
        receipt = None
        token = None
        platform = "ios"

    now = datetime.now(timezone.utc)

    # Check if user already has an active subscription
    if uid in subscriptions_db:
        sub = subscriptions_db[uid]
        tier = sub.get("tier", "free")
        expires_at = sub.get("expires_at")
        status = sub.get("status", "active")

        # Check if expired
        if expires_at:
            try:
                exp = datetime.fromisoformat(expires_at)
                if exp.tzinfo is None:
                    exp = exp.replace(tzinfo=timezone.utc)
                if exp < now:
                    status = "expired"
                    tier = "free"
            except Exception:
                pass

        if status == "active" and tier != "free":
            return {
                "success": True,
                "restored": True,
                "tier": tier,
                "status": status,
                "expires_at": expires_at,
                "message": "Subscription restored from existing record.",
            }

    # Try to verify with Apple/Google in production
    # For now, fall back to purchase history
    restored_tier = _find_restored_tier(uid, platform, receipt, token)

    if restored_tier:
        tier_id = restored_tier["tier"]
        expires_at = restored_tier.get("expires_at")

        subscriptions_db[uid] = {
            "tier": tier_id,
            "product_id": tier_id,
            "status": "active",
            "expires_at": expires_at,
            "restored": True,
            "restored_at": now.isoformat(),
            "platform": platform,
        }
        return {
            "success": True,
            "restored": True,
            "tier": tier_id,
            "status": "active",
            "expires_at": expires_at,
            "message": "Subscription restored successfully.",
        }

    return {
        "success": True,
        "restored": False,
        "tier": "free",
        "status": "none",
        "expires_at": None,
        "message": "No active subscriptions found to restore.",
    }


def _find_restored_tier(user_id: str, platform: str, receipt_data: Optional[str] = None, purchase_token: Optional[str] = None) -> Optional[dict]:
    """
    Find a previously purchased subscription for the user.
    In production, this would verify receipts with Apple/Google servers.
    """
    # Check in-memory purchase history
    global _seasons_purchase_history
    history = _seasons_purchase_history.get(user_id, [])

    for entry in reversed(history):
        if entry.get("platform") == platform or entry.get("platform") == f"iap_{platform}":
            return {
                "tier": entry.get("tier", "serenity"),
                "expires_at": entry.get("expires_at"),
            }

    return None


# Global purchase history for SEASONS Global (separate from CN version)
_seasons_purchase_history: dict = {}


@router.post("/validate-code")
async def validate_offer_code(body: ValidateCodeRequest, user_id: str = Query(...)):
    """Validate an offer code"""
    code = body.code.upper()
    
    # Mock offer codes
    offer_codes = {
        "WELCOME20": {"discount_percent": 20, "message": "20% off your first year"},
        "CALM10": {"discount_percent": 10, "message": "10% off any plan"},
        "LAUNCH": {"discount_percent": 30, "message": "30% off for early supporters"},
    }
    
    if code in offer_codes:
        return {
            "valid": True,
            "discount_percent": offer_codes[code]["discount_percent"],
            "message": offer_codes[code]["message"],
        }
    
    return {
        "valid": False,
        "discount_percent": None,
        "message": "Invalid or expired offer code",
    }


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
    try:
        body = await request.body()
        signature = request.headers.get("stripe-signature", "")

        # In production, verify the Stripe signature
        # stripe_event = stripe.Webhook.construct_event(
        #     body, signature, os.getenv("STRIPE_WEBHOOK_SECRET")
        # )

        import json
        event = json.loads(body)
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

    except Exception as e:
        logger.error(f"[Stripe Webhook] Error processing webhook: {e}")

    # Always return 200 to acknowledge receipt (prevents Stripe retries)
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
