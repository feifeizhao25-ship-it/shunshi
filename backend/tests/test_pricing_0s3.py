"""0S3 定价（2026-10-15）：免费 / 内容订阅 ¥399 / 会员 ¥888，年付唯一；陪伴档不在售；旧 SKU 停售但老用户权益保留。"""
from app.entitlements import tier_for_product
from app.router.subscription import SUBSCRIPTION_PLANS, SUBSCRIPTION_PRODUCTS, _product_id_to_plan
from app.services.alipay_service import ALIPAY_PRODUCTS
from app.services.membership_status import _PRODUCT_PLANS


def test_only_two_yearly_paid_products_on_sale():
    on_sale = {(p["product_id"], p["platform"], p["price_cents"], p["duration_days"])
               for p in SUBSCRIPTION_PRODUCTS if p["status"] == "active"}
    assert on_sale == {
        ("content_yearly", "alipay", 39900, 365), ("content_yearly", "wechat", 39900, 365),
        ("content_apple_yearly", "apple", 39900, 365),
        ("member_yearly", "alipay", 88800, 365), ("member_yearly", "wechat", 88800, 365),
        ("member_apple_yearly", "apple", 88800, 365),
    }


def test_plan_names_and_no_companion_tier():
    assert SUBSCRIPTION_PLANS["yangxin"]["name"] == "内容订阅"
    assert SUBSCRIPTION_PLANS["yiyang"]["name"] == "会员"
    assert SUBSCRIPTION_PLANS["jiahe"]["on_sale"] is False
    assert not any("陪伴" in p["name"] for p in SUBSCRIPTION_PRODUCTS)
    assert not any("1988" in str(p["price_cents"]) or p["price_cents"] == 198800 for p in SUBSCRIPTION_PRODUCTS)


def test_alipay_catalogue_has_new_prices():
    assert str(ALIPAY_PRODUCTS["content_yearly"]["price"]) == "399.00"
    assert str(ALIPAY_PRODUCTS["member_yearly"]["price"]) == "888.00"


def test_legacy_purchasers_keep_entitlements():
    for sku, tier in (("shunshi_yangxin_monthly", "plus"), ("shunshi_yiyang_yearly", "pro"),
                      ("shunshi_family_yearly", "family"), ("jiahe_monthly", "family")):
        assert tier_for_product(sku) == tier
    assert _product_id_to_plan("com.shunshi.jiahe.monthly") == "jiahe"


def test_new_products_map_to_paid_tiers_everywhere():
    for sku in ("shunshi_content_yearly", "content_yearly", "content_apple_yearly", "com.shunshi.content.yearly"):
        assert tier_for_product(sku) == "plus" and _PRODUCT_PLANS[sku] == "yangxin"
    for sku in ("shunshi_member_yearly", "member_yearly", "member_apple_yearly", "com.shunshi.member.yearly"):
        assert tier_for_product(sku) == "pro" and _PRODUCT_PLANS[sku] == "yiyang"
    assert _product_id_to_plan("com.shunshi.member.yearly") == "yiyang"


def test_legacy_sku_cannot_be_ordered(client, auth_headers):
    r = client.post("/api/v1/subscription/create-order", headers=auth_headers,
                    json={"product_id": "yangxin_monthly", "platform": "alipay"})
    assert r.status_code == 410 and "停售" in r.json()["detail"]
