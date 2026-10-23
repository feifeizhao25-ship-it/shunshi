"""养心与颐养付钱不同、额度却一样（2026-10-13 用户让 Claude 代为决定）：
养心（29 元）每天 100 次对话，颐养（59 元）每天 200 次；不再宣称没有执行点的「深度建议、周总结」。"""
from app.entitlements import daily_chat_limit_for_plan, get_registry, tier_for_product
from app.router.subscription import SUBSCRIPTION_PLANS, _get_plan_description
from app.services import membership_status as ms


def test_registry_quotas_by_plan():
    tiers = get_registry()["tiers"]
    assert tiers["plus"]["quotas"]["ai_daily_messages"] == 100
    assert tiers["pro"]["quotas"]["ai_daily_messages"] == 200
    for sku in ("shunshi_yangxin_monthly", "shunshi_yangxin_yearly", "yangxin_monthly", "yangxin_yearly", "shunshi_healing_monthly"):
        assert tier_for_product(sku) == "plus", sku
    for sku in ("shunshi_yiyang_monthly", "yiyang_yearly"):
        assert tier_for_product(sku) == "pro", sku
    assert [daily_chat_limit_for_plan(p) for p in ("free", "yangxin", "yiyang", "jiahe")] == [20, 100, 200, 200]


def test_no_unimplemented_perks_are_advertised():
    for plan in SUBSCRIPTION_PLANS.values():
        assert plan["features"]["deep_suggestions"] is False
        assert plan["features"]["weekly_summary"] is False
    for features in ms._DOMESTIC_FEATURES.values():
        assert "deep_suggestions" not in features and "weekly_summary" not in features
    assert ms._DOMESTIC_FEATURES["yangxin"]["daily_chat_limit"] == 100
    assert ms._DOMESTIC_FEATURES["yiyang"]["daily_chat_limit"] == 200
    text = _get_plan_description("yiyang")
    assert "深度建议" not in text and "周总结" not in text
    assert "每天 200 次对话" in text and "每天 100 次对话" in _get_plan_description("yangxin")
