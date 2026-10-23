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


def test_alipay_public_catalogue_lists_only_yearly_on_sale(client):
    response = client.get("/api/v1/payments/alipay/products")
    assert response.status_code == 200
    rows = response.json()["data"]
    assert {(row["sku"], row["price"], row["period"]) for row in rows} == {
        ("content_yearly", "399.00", "year"),
        ("member_yearly", "888.00", "year"),
    }
    assert all(row["on_sale"] is True and row["max_family_seats"] == 0 for row in rows)


def test_discontinued_alipay_sku_cannot_open_a_new_order():
    from decimal import Decimal
    import pytest
    from app.services.alipay_service import purchasable_alipay_product
    for sku in ("yangxin_monthly", "family_monthly", "family_yearly", "jiahe"):
        with pytest.raises(ValueError, match="停售"):
            purchasable_alipay_product(sku)
    assert purchasable_alipay_product("content_yearly")["price"] == Decimal("399.00")


def test_subscription_products_are_yearly_and_do_not_offer_jiahe(client, auth_headers):
    response = client.get("/api/v1/subscription/products", headers=auth_headers, params={"platform": "alipay"})
    assert response.status_code == 200
    body = response.json()["data"]
    assert body["tiers"] == ["free", "yangxin", "yiyang"]
    products = body["products"]
    assert {item["product_id"] for item in products} == {"content_yearly", "member_yearly"}
    by_id = {item["product_id"]: item for item in products}
    assert by_id["content_yearly"]["price_cents"] == 39900
    assert by_id["member_yearly"]["price_cents"] == 88800
    for item in products:
        assert item["period_name"] == "年" and item["on_sale"] is True
        assert "无限" not in item["description"]
        assert "家庭" not in item["description"]
        assert "深度" not in item["description"]


def test_plan_list_marks_jiahe_off_sale(client, auth_headers):
    response = client.get("/api/v1/subscription/plans", headers=auth_headers)
    assert response.status_code == 200
    plans = {item["id"]: item for item in response.json()["data"]}
    assert plans["jiahe"]["on_sale"] is False
    assert plans["yangxin"]["on_sale"] is True and plans["yangxin"]["price_yearly"] == 399
    assert plans["yiyang"]["price_yearly"] == 888
