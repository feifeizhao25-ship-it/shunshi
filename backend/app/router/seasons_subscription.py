"""
SEASONS Global Version - Subscription Management API
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

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
async def restore_purchases(user_id: str = Query(...)):
    """Restore purchases from app stores"""
    # In production, this would verify receipts with Apple/Google
    # For now, just acknowledge the request
    return {
        "success": True,
        "restored": False,
        "message": "No active subscriptions found to restore.",
    }


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
