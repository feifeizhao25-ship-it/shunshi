"""批2: 家庭席位单一口径 — 注册表 family=3人(含购买人, D4 20261015) => 可绑定2位; 在售年付档无家庭席位."""
from app.entitlements import family_seats_for_plan, get_registry
from app.router.subscription import SUBSCRIPTION_PLANS

def test_seats_from_registry_only():
    assert get_registry()["tiers"]["family"]["collaboration"]["family_members"] == 3
    assert family_seats_for_plan("jiahe") == 2
    assert SUBSCRIPTION_PLANS["jiahe"]["family_seats"] == 2
    # 在售年付档 (内容订阅/会员) 无家庭权益
    assert family_seats_for_plan("yangxin") == 0
    assert family_seats_for_plan("yiyang") == 0
    assert SUBSCRIPTION_PLANS["jiahe"]["on_sale"] is False
    assert SUBSCRIPTION_PLANS["yangxin"]["price_yearly"] == 399
    assert SUBSCRIPTION_PLANS["yiyang"]["price_yearly"] == 888


def test_registry_is_annual_only_and_has_no_enterprise_or_withdrawn_features():
    """X1：年付唯一；在售映射不含月付 SKU，月付只在 legacy 映射；无 enterprise；趋势/CSV 已撤下不再宣称。"""
    reg = get_registry()
    assert "enterprise" not in reg["tiers"]
    assert not [k for k in reg["product_tier_map"] if k.endswith("_monthly")]
    assert reg["legacy_product_tier_map"] and all(k.endswith("_monthly") for k in reg["legacy_product_tier_map"])
    for name, tier in reg["tiers"].items():
        assert tier["knowledge"]["long_term_trends"] is False, name
        assert tier["export"]["formats"] == ["json"], name


def test_seasons_family_router_uses_the_same_seat_definition():
    from app.router import seasons_family
    assert seasons_family.MAX_FAMILY_MEMBERS == get_registry()["tiers"]["family"]["collaboration"]["family_members"] == 3
