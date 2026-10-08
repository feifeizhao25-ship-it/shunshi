"""会员档位只有一套：价格以 SUBSCRIPTION_PLANS（实际收费 SKU）为准，额度/家庭人数以权益注册表为准。

以前后端同时有：membership.py 的「基础 18 / 高级 38 / 家庭 58 元、每天 3 次 / 无限问答、AI 伴侣」，
subscription.py 的「养心 29 / 颐养 59 / 家和 99、无限对话」，/usage 的「免费每天 10 次、付费无限」，
而真正执行的是注册表的免费 20 次、付费 200 次。
"""

from app.entitlements import (
    daily_chat_limit_for_plan,
    family_seats_for_plan,
    get_registry,
    registry_tier_for_plan,
    tier_for_product,
)
from app.router.membership import MEMBERSHIP_TIERS
from app.router.subscription import SUBSCRIPTION_PLANS, SUBSCRIPTION_PRODUCTS
from app.services.alipay_service import ALIPAY_PRODUCTS

PAID = ("yangxin", "yiyang", "jiahe")


def test_registry_numbers_used_for_quota_and_seats():
    registry = get_registry()
    assert daily_chat_limit_for_plan("free") == registry["tiers"]["free"]["quotas"]["ai_daily_messages"]
    for plan_id in PAID:
        assert daily_chat_limit_for_plan(plan_id) == registry["tiers"][registry_tier_for_plan(plan_id)]["quotas"]["ai_daily_messages"]
    # 注册表 family 档 5 人（含购买人）= 家和 4 个家人席位
    assert family_seats_for_plan("jiahe") == registry["tiers"]["family"]["collaboration"]["family_members"] - 1


def test_subscription_plans_do_not_claim_more_than_registry():
    for plan_id, plan in SUBSCRIPTION_PLANS.items():
        limit = daily_chat_limit_for_plan(plan_id)
        assert plan["daily_chat_limit"] == limit
        assert plan["features"]["unlimited_chat"] is (limit == -1), plan_id
    assert SUBSCRIPTION_PLANS["jiahe"]["family_seats"] == family_seats_for_plan("jiahe")


def test_every_sku_price_matches_its_plan():
    for sku in SUBSCRIPTION_PRODUCTS:
        plan = SUBSCRIPTION_PLANS[sku["tier"]]
        yearly = sku["duration_days"] >= 365
        expected = plan["price_yearly_cents"] if yearly else plan["price_cents"]
        assert sku["price_cents"] == expected, sku["product_id"]
        if sku["tier"] == "jiahe":
            assert sku["family_seats"] == SUBSCRIPTION_PLANS["jiahe"]["family_seats"]


def test_alipay_products_match_plans_and_registry():
    for key, product in ALIPAY_PRODUCTS.items():
        plan = SUBSCRIPTION_PLANS[product["tier"]]
        yearly = product["duration_days"] >= 365
        expected = plan["price_yearly"] if yearly else plan["price"]
        assert product["price"] == expected, key
        assert product["max_family_seats"] == plan.get("family_seats", 0), key
        # 付款后按 product_id 查注册表得到的档位，必须就是这个价格对应的档位
        assert tier_for_product(product["product_id"]) == registry_tier_for_plan(product["tier"]), key


def test_membership_catalogue_is_derived_not_a_second_price_list():
    assert set(MEMBERSHIP_TIERS) == set(SUBSCRIPTION_PLANS)
    for plan_id, tier in MEMBERSHIP_TIERS.items():
        assert tier["price_monthly"] == SUBSCRIPTION_PLANS[plan_id]["price"]
        limit = daily_chat_limit_for_plan(plan_id)
        assert tier["features"]["ai_questions_per_day"] == ("unlimited" if limit == -1 else limit)
        assert "companion" not in tier["features"]
