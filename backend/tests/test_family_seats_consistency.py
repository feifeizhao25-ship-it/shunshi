"""批2: 家庭席位单一口径 — 注册表 family=5人(含购买人) => 可绑定4位; 在售年付档无家庭席位."""
from app.entitlements import family_seats_for_plan, get_registry
from app.router.subscription import SUBSCRIPTION_PLANS

def test_seats_from_registry_only():
    assert get_registry()["tiers"]["family"]["collaboration"]["family_members"] == 5
    assert family_seats_for_plan("jiahe") == 4
    assert SUBSCRIPTION_PLANS["jiahe"]["family_seats"] == 4
    # 在售年付档 (内容订阅/会员) 无家庭权益
    assert family_seats_for_plan("yangxin") == 0
    assert family_seats_for_plan("yiyang") == 0
    assert SUBSCRIPTION_PLANS["jiahe"]["on_sale"] is False
    assert SUBSCRIPTION_PLANS["yangxin"]["price_yearly"] == 399
    assert SUBSCRIPTION_PLANS["yiyang"]["price_yearly"] == 888
