"""X3：SEASONS 年付唯一 + Free/Premium/Family；三处原先互相矛盾的档位表现在只有一个定义。"""
import asyncio

import pytest
from fastapi import HTTPException

from app import seasons_plans as sp
from app.entitlements import get_registry
from app.router import seasons_family, seasons_subscription as ss, stripe as stripe_router
from app.services import stripe_service


def test_one_definition_free_premium_family_yearly_usd():
    assert list(sp.PLANS) == ["free", "premium", "family"]
    assert sp.PLANS["premium"]["yearly_price"] == 79.99
    assert sp.PLANS["family"]["yearly_price"] == 159.99
    for pid in sp.PAID_PLAN_IDS:
        plan = sp.PLANS[pid]
        assert plan["period"] == "year" and plan["currency"] == "usd"
        assert "monthly_price" not in plan
    assert not [k for k in sp.PLANS if k in ("enterprise", "serenity", "harmony")]


def test_all_three_modules_share_the_same_table():
    assert stripe_router.SUBSCRIPTION_PLANS_EN is sp.PLANS
    assert stripe_service.STRIPE_PRODUCTS is sp.PLANS
    assert set(ss.SUBSCRIPTION_PLANS) == set(sp.PAID_PLAN_IDS)


def test_legacy_names_map_to_premium_and_unknown_is_rejected():
    assert sp.canonical_plan_id("Serenity") == "premium"
    assert sp.canonical_plan_id("harmony") == "premium"
    assert sp.canonical_plan_id("family") == "family"
    assert sp.canonical_plan_id("enterprise") is None


def test_monthly_checkout_is_refused_and_unknown_product_400():
    for billing in ("monthly", "weekly"):
        with pytest.raises(HTTPException) as e:
            asyncio.run(ss.create_checkout(ss.CheckoutRequest(product_id="premium", billing=billing), user_id="u1"))
        assert e.value.status_code == 400
    with pytest.raises(HTTPException) as e:
        asyncio.run(ss.create_checkout(ss.CheckoutRequest(product_id="enterprise", billing="yearly"), user_id="u1"))
    assert e.value.status_code == 400


def test_products_endpoint_lists_yearly_only():
    products = asyncio.run(ss.get_products())
    assert [p["id"] for p in products] == ["premium", "family"]
    for p in products:
        assert "monthly_price" not in p and p["billing"] == "yearly"
        assert p["has_intro_offer"] is False


def test_status_maps_legacy_tier_to_premium():
    ss.subscriptions_db["legacy-user"] = {"tier": "harmony", "status": "active"}
    try:
        assert asyncio.run(ss.get_subscription_status(user_id="legacy-user"))["tier"] == "premium"
    finally:
        ss.subscriptions_db.pop("legacy-user", None)


def test_family_seat_definition_is_the_same_as_the_cn_registry():
    reg_members = get_registry()["tiers"]["family"]["collaboration"]["family_members"]
    assert sp.FAMILY_MEMBERS == sp.PLANS["family"]["family_members"] == reg_members == seasons_family.MAX_FAMILY_MEMBERS == 3
