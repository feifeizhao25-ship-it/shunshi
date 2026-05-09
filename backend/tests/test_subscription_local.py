"""
国际化订阅本地化管理 - 单元测试
覆盖多货币定价、含税计算、不支持货币处理、退款政策查询及礼品卡信息。
"""

import pytest
from fastapi.testclient import TestClient


# 假设 FastAPI app 已正确导入
from app.main import app

client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 货币定价查询测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPricingByCurrency:
    """GET /api/v1/subscription-local/pricing/{currency_code} 端点测试"""

    def test_pricing_usd(self):
        """查询 USD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/USD")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["currency_code"] == "USD"
        assert data["data"]["symbol"] == "$"
        assert "plans" in data["data"]
        assert "basic" in data["data"]["plans"]
        assert "premium" in data["data"]["plans"]
        assert "family" in data["data"]["plans"]

    def test_pricing_eur(self):
        """查询 EUR 定价"""
        response = client.get("/api/v1/subscription-local/pricing/EUR")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "EUR"
        assert data["data"]["symbol"] == "€"

    def test_pricing_gbp(self):
        """查询 GBP 定价"""
        response = client.get("/api/v1/subscription-local/pricing/GBP")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "GBP"
        assert data["data"]["symbol"] == "£"

    def test_pricing_aud(self):
        """查询 AUD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/AUD")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "AUD"
        assert data["data"]["symbol"] == "A$"

    def test_pricing_sgd(self):
        """查询 SGD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/SGD")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "SGD"

    def test_pricing_cad(self):
        """查询 CAD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/CAD")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "CAD"

    def test_pricing_jpy(self):
        """查询 JPY 定价"""
        response = client.get("/api/v1/subscription-local/pricing/JPY")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "JPY"
        assert data["data"]["symbol"] == "¥"

    def test_pricing_krw(self):
        """查询 KRW 定价"""
        response = client.get("/api/v1/subscription-local/pricing/KRW")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "KRW"

    def test_pricing_hkd(self):
        """查询 HKD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/HKD")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "HKD"

    def test_pricing_twd(self):
        """查询 TWD 定价"""
        response = client.get("/api/v1/subscription-local/pricing/TWD")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "TWD"

    def test_pricing_myr(self):
        """查询 MYR 定价"""
        response = client.get("/api/v1/subscription-local/pricing/MYR")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "MYR"

    def test_pricing_thb(self):
        """查询 THB 定价"""
        response = client.get("/api/v1/subscription-local/pricing/THB")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["currency_code"] == "THB"

    def test_pricing_unsupported_currency(self):
        """不支持的货币返回 404"""
        response = client.get("/api/v1/subscription-local/pricing/CNY")
        assert response.status_code == 404
        data = response.json()
        assert "不支持的货币" in data["detail"]

    def test_pricing_case_insensitive(self):
        """货币代码大小写不敏感"""
        response_upper = client.get("/api/v1/subscription-local/pricing/USD")
        response_lower = client.get("/api/v1/subscription-local/pricing/usd")
        assert response_upper.status_code == 200
        assert response_lower.status_code == 200

    def test_pricing_plans_structure(self):
        """验证价格计划结构"""
        response = client.get("/api/v1/subscription-local/pricing/USD")
        data = response.json()
        for tier in ["basic", "premium", "family"]:
            plan = data["data"]["plans"][tier]
            assert "name" in plan
            assert "monthly_price" in plan
            assert "currency" in plan
            assert "features" in plan
            assert isinstance(plan["features"], list)


# ─────────────────────────────────────────────────────────────────────────────
# 支持货币列表测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSupportedCurrencies:
    """GET /api/v1/subscription-local/currencies 端点测试"""

    def test_currencies_list_exists(self):
        """获取支持的货币列表"""
        response = client.get("/api/v1/subscription-local/currencies")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "supported_currencies" in data["data"]

    def test_currencies_list_count(self):
        """验证支持的货币数量"""
        response = client.get("/api/v1/subscription-local/currencies")
        data = response.json()
        assert data["data"]["total_count"] >= 12

    def test_currencies_contain_major(self):
        """验证包含主要货币"""
        response = client.get("/api/v1/subscription-local/currencies")
        data = response.json()
        codes = [c["code"] for c in data["data"]["supported_currencies"]]
        assert "USD" in codes
        assert "EUR" in codes
        assert "GBP" in codes

    def test_currencies_structure(self):
        """验证每个货币的结构"""
        response = client.get("/api/v1/subscription-local/currencies")
        data = response.json()
        for currency in data["data"]["supported_currencies"]:
            assert "code" in currency
            assert "symbol" in currency
            assert "name" in currency


# ─────────────────────────────────────────────────────────────────────────────
# 区域合规要求测试
# ─────────────────────────────────────────────────────────────────────────────

class TestComplianceRequirements:
    """GET /api/v1/subscription-local/compliance/{region_code} 端点测试"""

    def test_compliance_eu_gdpr(self):
        """EU 区域的 GDPR 合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/EU")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["gdpr_required"] is True
        assert data["data"]["requires_explicit_consent"] is True
        assert data["data"]["vat_rate_percent"] == 21
        assert data["data"]["refund_policy_days"] == 14

    def test_compliance_uk(self):
        """UK 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/UK")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["gdpr_required"] is True
        assert data["data"]["vat_rate_percent"] == 20

    def test_compliance_us(self):
        """US 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/US")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["gdpr_required"] is False
        assert data["data"]["vat_rate_percent"] == 0
        assert data["data"]["refund_policy_days"] == 7

    def test_compliance_au(self):
        """AU 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/AU")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["vat_rate_percent"] == 10

    def test_compliance_sg(self):
        """SG 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/SG")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["requires_explicit_consent"] is True

    def test_compliance_jp(self):
        """JP 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/JP")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["vat_rate_percent"] == 10

    def test_compliance_kr(self):
        """KR 区域的合规要求"""
        response = client.get("/api/v1/subscription-local/compliance/KR")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["gdpr_required"] is False

    def test_compliance_invalid_region(self):
        """无效区域代码返回 404"""
        response = client.get("/api/v1/subscription-local/compliance/XX")
        assert response.status_code == 404

    def test_compliance_case_insensitive(self):
        """区域代码大小写不敏感"""
        response_upper = client.get("/api/v1/subscription-local/compliance/EU")
        response_lower = client.get("/api/v1/subscription-local/compliance/eu")
        assert response_upper.status_code == 200
        assert response_lower.status_code == 200


# ─────────────────────────────────────────────────────────────────────────────
# 含税价格计算测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPriceCalculation:
    """POST /api/v1/subscription-local/calculate 端点测试"""

    def test_calculate_basic_usd_1month(self):
        """计算基础版 USD 1 个月的价格"""
        payload = {
            "tier": "basic",
            "currency": "USD",
            "region": "US",
            "duration_months": 1,
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["tier"] == "basic"
        assert data["data"]["currency"] == "USD"
        assert data["data"]["subtotal"] == 9.99
        assert data["data"]["vat_amount"] == 0  # US 无 VAT
        assert data["data"]["total_price"] == 9.99

    def test_calculate_basic_eur_1month(self):
        """计算基础版 EUR 1 个月的价格（带 VAT）"""
        payload = {
            "tier": "basic",
            "currency": "EUR",
            "region": "EU",
            "duration_months": 1,
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["vat_rate_percent"] == 21
        assert data["data"]["vat_amount"] > 0
        assert data["data"]["total_price"] > data["data"]["subtotal"]

    def test_calculate_premium_gbp_3months(self):
        """计算高级版 GBP 3 个月的价格"""
        payload = {
            "tier": "premium",
            "currency": "GBP",
            "region": "UK",
            "duration_months": 3,
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tier"] == "premium"
        assert data["data"]["duration_months"] == 3
        # 高级版 GBP 定价
        expected_monthly = 13.49
        expected_subtotal = expected_monthly * 3
        assert data["data"]["subtotal"] == expected_subtotal

    def test_calculate_family_aud_12months(self):
        """计算家庭版 AUD 12 个月的价格"""
        payload = {
            "tier": "family",
            "currency": "AUD",
            "region": "AU",
            "duration_months": 12,
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tier"] == "family"
        assert data["data"]["duration_months"] == 12

    def test_calculate_vat_rates_vary_by_region(self):
        """验证不同区域的 VAT 税率"""
        currencies_and_regions = [
            ("EUR", "EU", 21),
            ("GBP", "UK", 20),
            ("AUD", "AU", 10),
            ("SGD", "SG", 8),
            ("JPY", "JP", 10),
        ]
        for currency, region, expected_vat in currencies_and_regions:
            payload = {
                "tier": "basic",
                "currency": currency,
                "region": region,
                "duration_months": 1,
            }
            response = client.post("/api/v1/subscription-local/calculate", json=payload)
            assert response.status_code == 200
            data = response.json()
            assert data["data"]["vat_rate_percent"] == expected_vat

    def test_calculate_invalid_tier(self):
        """无效的档位返回 422"""
        payload = {
            "tier": "invalid",
            "currency": "USD",
            "region": "US",
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 422

    def test_calculate_unsupported_currency(self):
        """不支持的货币返回 404"""
        payload = {
            "tier": "basic",
            "currency": "CNY",
            "region": "US",
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 404

    def test_calculate_invalid_region(self):
        """无效的区域返回 404"""
        payload = {
            "tier": "basic",
            "currency": "USD",
            "region": "XX",
        }
        response = client.post("/api/v1/subscription-local/calculate", json=payload)
        assert response.status_code == 404

    def test_calculate_case_insensitive_tier(self):
        """档位名称大小写不敏感"""
        payload_upper = {
            "tier": "BASIC",
            "currency": "USD",
            "region": "US",
        }
        payload_lower = {
            "tier": "basic",
            "currency": "USD",
            "region": "US",
        }
        response_upper = client.post("/api/v1/subscription-local/calculate", json=payload_upper)
        response_lower = client.post("/api/v1/subscription-local/calculate", json=payload_lower)
        assert response_upper.status_code == 200
        assert response_lower.status_code == 200


# ─────────────────────────────────────────────────────────────────────────────
# 退款政策查询测试
# ─────────────────────────────────────────────────────────────────────────────

class TestRefundPolicy:
    """GET /api/v1/subscription-local/refund-policy/{tier}/{region} 端点测试"""

    def test_refund_policy_basic_eu(self):
        """基础版 EU 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/basic/EU")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["tier"] == "basic"
        assert data["data"]["region"] == "EU"
        assert "14" in data["data"]["policy"] or "14 天" in data["data"]["policy"]
        assert data["data"]["refund_days"] == 14

    def test_refund_policy_premium_uk(self):
        """高级版 UK 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/premium/UK")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tier"] == "premium"
        assert data["data"]["region"] == "UK"
        assert data["data"]["refund_days"] == 14

    def test_refund_policy_family_us(self):
        """家庭版 US 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/family/US")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tier"] == "family"
        assert data["data"]["region"] == "US"
        assert data["data"]["refund_days"] == 7

    def test_refund_policy_basic_au(self):
        """基础版 AU 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/basic/AU")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["refund_days"] == 7

    def test_refund_policy_basic_jp(self):
        """基础版 JP 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/basic/JP")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["refund_days"] == 8

    def test_refund_policy_family_kr(self):
        """家庭版 KR 地区的退款政策"""
        response = client.get("/api/v1/subscription-local/refund-policy/family/KR")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["refund_days"] == 7

    def test_refund_policy_invalid_tier(self):
        """无效的档位返回 404"""
        response = client.get("/api/v1/subscription-local/refund-policy/invalid/EU")
        assert response.status_code == 404

    def test_refund_policy_invalid_region(self):
        """无效的区域返回 404"""
        response = client.get("/api/v1/subscription-local/refund-policy/basic/XX")
        assert response.status_code == 404

    def test_refund_policy_regional_variation(self):
        """验证不同区域的退款政策差异"""
        eu_response = client.get("/api/v1/subscription-local/refund-policy/basic/EU")
        us_response = client.get("/api/v1/subscription-local/refund-policy/basic/US")

        eu_days = eu_response.json()["data"]["refund_days"]
        us_days = us_response.json()["data"]["refund_days"]

        assert eu_days == 14
        assert us_days == 7


# ─────────────────────────────────────────────────────────────────────────────
# 礼品卡信息测试
# ─────────────────────────────────────────────────────────────────────────────

class TestGiftCardInfo:
    """GET /api/v1/subscription-local/gift 端点测试"""

    def test_gift_card_available(self):
        """查询礼品卡可用性"""
        response = client.get("/api/v1/subscription-local/gift")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["gift_card_available"] is True

    def test_gift_card_denominations(self):
        """查询礼品卡可用面值"""
        response = client.get("/api/v1/subscription-local/gift")
        data = response.json()
        assert "available_denominations" in data["data"]
        assert len(data["data"]["available_denominations"]) >= 3

    def test_gift_card_structure(self):
        """验证礼品卡面值的结构"""
        response = client.get("/api/v1/subscription-local/gift")
        data = response.json()
        for denomination in data["data"]["available_denominations"]:
            assert "value_usd" in denomination
            assert "tier_eligible" in denomination
            assert "months_coverage" in denomination

    def test_gift_card_usage_instructions(self):
        """查询礼品卡使用说明"""
        response = client.get("/api/v1/subscription-local/gift")
        data = response.json()
        assert "usage_instructions" in data["data"]
        assert len(data["data"]["usage_instructions"]) > 0

    def test_gift_card_promotions(self):
        """查询礼品卡促销信息"""
        response = client.get("/api/v1/subscription-local/gift")
        data = response.json()
        assert "promotions" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """端点间的集成测试"""

    def test_currency_price_calculation_flow(self):
        """货币查询 → 价格计算的完整流程"""
        # 1. 查询 EUR 的定价
        pricing = client.get("/api/v1/subscription-local/pricing/EUR")
        monthly_price = pricing.json()["data"]["plans"]["basic"]["monthly_price"]

        # 2. 计算 EUR 3 个月的含税价格
        calculation = client.post("/api/v1/subscription-local/calculate", json={
            "tier": "basic",
            "currency": "EUR",
            "region": "EU",
            "duration_months": 3,
        })

        calc_data = calculation.json()["data"]
        # 验证计算的正确性
        assert calc_data["subtotal"] == monthly_price * 3

    def test_region_compliance_refund_consistency(self):
        """区域合规要求与退款政策的一致性"""
        # 1. 查询 EU 的合规要求
        compliance = client.get("/api/v1/subscription-local/compliance/EU")
        compliance_refund_days = compliance.json()["data"]["refund_policy_days"]

        # 2. 查询 EU 的退款政策
        refund = client.get("/api/v1/subscription-local/refund-policy/basic/EU")
        policy_refund_days = refund.json()["data"]["refund_days"]

        # 验证一致性
        assert compliance_refund_days == policy_refund_days

    def test_multi_currency_pricing_consistency(self):
        """验证多货币定价的结构一致性"""
        currencies = ["USD", "EUR", "GBP", "JPY"]
        for currency in currencies:
            response = client.get(f"/api/v1/subscription-local/pricing/{currency}")
            data = response.json()
            # 验证每个货币都有完整的三个档位
            assert len(data["data"]["plans"]) == 3
            for tier in ["basic", "premium", "family"]:
                assert tier in data["data"]["plans"]
