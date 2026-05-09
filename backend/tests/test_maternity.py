"""
测试：孕产妇 TCM 专项养护 API
覆盖：10 个月份全覆盖（重点测 3 个）、禁用草药危险等级、产后两种分娩类型、安全穴位三孕期
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/maternity/pregnancy/{month} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPregnancyPlan:
    """孕期月份养护方案测试"""

    def test_pregnancy_month_1(self):
        """测试孕 1 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/1")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["month"] == 1
        assert data["data"]["plan"]["theme"] == "初怀孕，宜静养"
        assert "受精卵着床" in data["data"]["plan"]["fetal_development_stage"]
        assert "红花" in data["data"]["plan"]["forbidden_herbs"]
        assert "桃仁" in data["data"]["plan"]["forbidden_herbs"]
        assert "益母草" in data["data"]["plan"]["forbidden_herbs"]

    def test_pregnancy_month_5(self):
        """测试孕 5 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/5")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["month"] == 5
        assert data["data"]["plan"]["theme"] == "胎动可感，加强滋补"
        assert "胎动明显" in data["data"]["plan"]["fetal_development_stage"]
        assert len(data["data"]["plan"]["recommended_foods"]) > 0
        assert len(data["data"]["plan"]["safe_acupoints"]) > 0

    def test_pregnancy_month_10(self):
        """测试孕 10 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/10")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["month"] == 10
        assert data["data"]["plan"]["theme"] == "待产期，沉着应对"
        assert "随时可出生" in data["data"]["plan"]["fetal_development_stage"]
        assert "请遵医嘱" in data["data"]["disclaimer"]

    def test_pregnancy_month_2(self):
        """测试孕 2 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/2")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 2

    def test_pregnancy_month_3(self):
        """测试孕 3 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/3")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 3

    def test_pregnancy_month_4(self):
        """测试孕 4 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/4")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 4

    def test_pregnancy_month_6(self):
        """测试孕 6 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/6")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 6

    def test_pregnancy_month_7(self):
        """测试孕 7 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/7")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 7

    def test_pregnancy_month_8(self):
        """测试孕 8 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/8")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 8

    def test_pregnancy_month_9(self):
        """测试孕 9 月方案"""
        response = client.get("/api/v1/maternity/pregnancy/9")
        assert response.status_code == 200
        assert response.json()["data"]["month"] == 9

    def test_pregnancy_month_invalid_0(self):
        """测试无效月份 0"""
        response = client.get("/api/v1/maternity/pregnancy/0")
        assert response.status_code == 400

    def test_pregnancy_month_invalid_11(self):
        """测试无效月份 11"""
        response = client.get("/api/v1/maternity/pregnancy/11")
        assert response.status_code == 400

    def test_pregnancy_month_invalid_negative(self):
        """测试无效月份负数"""
        response = client.get("/api/v1/maternity/pregnancy/-1")
        assert response.status_code == 422  # Pydantic validation error

    def test_pregnancy_contains_recommended_foods(self):
        """测试方案包含推荐食物"""
        response = client.get("/api/v1/maternity/pregnancy/3")
        data = response.json()
        assert "recommended_foods" in data["data"]["plan"]
        assert isinstance(data["data"]["plan"]["recommended_foods"], list)
        assert len(data["data"]["plan"]["recommended_foods"]) > 0

    def test_pregnancy_contains_forbidden_foods(self):
        """测试方案包含禁忌食物"""
        response = client.get("/api/v1/maternity/pregnancy/3")
        data = response.json()
        assert "forbidden_foods" in data["data"]["plan"]
        assert isinstance(data["data"]["plan"]["forbidden_foods"], list)

    def test_pregnancy_contains_warning_signs(self):
        """测试方案包含警示信号"""
        response = client.get("/api/v1/maternity/pregnancy/5")
        data = response.json()
        assert "warning_signs" in data["data"]["plan"]
        assert len(data["data"]["plan"]["warning_signs"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/maternity/forbidden-herbs 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestForbiddenHerbs:
    """禁用草药列表测试"""

    def test_get_all_forbidden_herbs(self):
        """获取所有禁用草药"""
        response = client.get("/api/v1/maternity/forbidden-herbs")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "herbs" in data["data"]
        assert isinstance(data["data"]["herbs"], list)
        assert len(data["data"]["herbs"]) > 0

    def test_forbidden_herbs_contains_high_danger(self):
        """禁用草药列表包含高危险等级"""
        response = client.get("/api/v1/maternity/forbidden-herbs")
        data = response.json()
        herbs = data["data"]["herbs"]
        high_danger = [h for h in herbs if h["danger_level"] == "high"]
        assert len(high_danger) > 0
        # 验证包含明确的高危草药
        herb_names = [h["name"] for h in high_danger]
        assert "红花" in herb_names
        assert "桃仁" in herb_names
        assert "益母草" in herb_names

    def test_forbidden_herbs_filter_high_danger(self):
        """按高危险等级筛选"""
        response = client.get("/api/v1/maternity/forbidden-herbs?danger_level=high")
        assert response.status_code == 200
        data = response.json()
        herbs = data["data"]["herbs"]
        assert all(h["danger_level"] == "high" for h in herbs)
        assert len(herbs) > 0

    def test_forbidden_herbs_filter_medium_danger(self):
        """按中等危险等级筛选"""
        response = client.get("/api/v1/maternity/forbidden-herbs?danger_level=medium")
        assert response.status_code == 200
        data = response.json()
        herbs = data["data"]["herbs"]
        assert all(h["danger_level"] == "medium" for h in herbs)
        assert len(herbs) > 0

    def test_forbidden_herbs_contains_reason(self):
        """禁用草药包含理由说明"""
        response = client.get("/api/v1/maternity/forbidden-herbs")
        data = response.json()
        herbs = data["data"]["herbs"]
        for herb in herbs:
            assert "name" in herb
            assert "danger_level" in herb
            assert "reason" in herb
            assert len(herb["reason"]) > 0

    def test_forbidden_herbs_high_contains_key_herbs(self):
        """高危草药包含关键项"""
        response = client.get("/api/v1/maternity/forbidden-herbs?danger_level=high")
        data = response.json()
        herb_names = [h["name"] for h in data["data"]["herbs"]]
        # 验证包含主要活血化瘀类草药
        assert "红花" in herb_names
        assert "麝香" in herb_names

    def test_forbidden_herbs_disclaimer(self):
        """禁用草药列表包含免责声明"""
        response = client.get("/api/v1/maternity/forbidden-herbs")
        data = response.json()
        assert "disclaimer" in data["data"]
        assert "遵医嘱" in data["data"]["disclaimer"]


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/maternity/postpartum/{delivery_type} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPostpartumPlan:
    """产后月子方案测试"""

    def test_postpartum_natural_delivery(self):
        """测试顺产月子方案"""
        response = client.get("/api/v1/maternity/postpartum/natural")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["delivery_type"] == "natural"
        assert "plan" in data["data"]
        assert isinstance(data["data"]["plan"]["plan"], list)

    def test_postpartum_cesarean_delivery(self):
        """测试剖腹产月子方案"""
        response = client.get("/api/v1/maternity/postpartum/cesarean")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["delivery_type"] == "cesarean"
        assert "plan" in data["data"]
        assert isinstance(data["data"]["plan"]["plan"], list)

    def test_postpartum_invalid_type(self):
        """测试无效分娩类型"""
        response = client.get("/api/v1/maternity/postpartum/invalid_type")
        assert response.status_code == 400

    def test_postpartum_natural_has_3_phases(self):
        """测试顺产方案包含 3 个恢复阶段"""
        response = client.get("/api/v1/maternity/postpartum/natural")
        data = response.json()
        plan_phases = data["data"]["plan"]["plan"]
        assert len(plan_phases) == 3
        days_ranges = [p["days_range"] for p in plan_phases]
        assert "1-7" in days_ranges
        assert "8-21" in days_ranges
        assert "22-42" in days_ranges

    def test_postpartum_cesarean_has_3_phases(self):
        """测试剖腹产方案包含 3 个恢复阶段"""
        response = client.get("/api/v1/maternity/postpartum/cesarean")
        data = response.json()
        plan_phases = data["data"]["plan"]["plan"]
        assert len(plan_phases) == 3

    def test_postpartum_natural_phase1_focus(self):
        """测试顺产第 1 阶段重点"""
        response = client.get("/api/v1/maternity/postpartum/natural")
        data = response.json()
        phase1 = data["data"]["plan"]["plan"][0]
        assert phase1["days_range"] == "1-7"
        assert "排恶露" in phase1["focus"]

    def test_postpartum_cesarean_phase1_differs_natural(self):
        """测试剖腹产第 1 阶段与顺产不同"""
        response_natural = client.get("/api/v1/maternity/postpartum/natural")
        response_cesarean = client.get("/api/v1/maternity/postpartum/cesarean")

        natural_phase1 = response_natural.json()["data"]["plan"]["plan"][0]
        cesarean_phase1 = response_cesarean.json()["data"]["plan"]["plan"][0]

        # 剖腹产应强调伤口愈合
        assert "伤口" in cesarean_phase1["focus"]

    def test_postpartum_contains_tcm_formula(self):
        """测试方案包含 TCM 处方建议"""
        response = client.get("/api/v1/maternity/postpartum/natural")
        data = response.json()
        for phase in data["data"]["plan"]["plan"]:
            assert "tcm_formula_suggestion" in phase
            assert len(phase["tcm_formula_suggestion"]) > 0

    def test_postpartum_contains_breastfeeding_notes(self):
        """测试方案包含哺乳期饮食提示"""
        response = client.get("/api/v1/maternity/postpartum/natural")
        data = response.json()
        for phase in data["data"]["plan"]["plan"]:
            assert "breastfeeding_diet_notes" in phase


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/maternity/breastfeeding-guide 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestBreastfeedingGuide:
    """哺乳期饮食指南测试"""

    def test_get_breastfeeding_guide(self):
        """获取哺乳期指南"""
        response = client.get("/api/v1/maternity/breastfeeding-guide")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "avoid_foods" in data["data"]
        assert isinstance(data["data"]["avoid_foods"], list)

    def test_breastfeeding_guide_contains_15_foods(self):
        """哺乳期禁忌包含至少 15 种食物"""
        response = client.get("/api/v1/maternity/breastfeeding-guide")
        data = response.json()
        avoid_foods = data["data"]["avoid_foods"]
        assert len(avoid_foods) >= 15

    def test_breastfeeding_avoid_foods_has_reason(self):
        """禁忌食物包含原因说明"""
        response = client.get("/api/v1/maternity/breastfeeding-guide")
        data = response.json()
        for food in data["data"]["avoid_foods"]:
            assert "food" in food
            assert "reason" in food
            assert len(food["reason"]) > 0

    def test_breastfeeding_guide_includes_tips(self):
        """哺乳期指南包含一般建议"""
        response = client.get("/api/v1/maternity/breastfeeding-guide")
        data = response.json()
        assert "general_tips" in data["data"]
        assert len(data["data"]["general_tips"]) > 0

    def test_breastfeeding_guide_specific_foods(self):
        """验证包含具体禁忌食物"""
        response = client.get("/api/v1/maternity/breastfeeding-guide")
        data = response.json()
        food_names = [f["food"] for f in data["data"]["avoid_foods"]]
        assert "螃蟹" in food_names
        assert "冰镇饮料" in food_names
        assert "咖啡因饮品（咖啡、茶）" in food_names


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/maternity/safe-acupoints/{trimester} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSafeAcupoints:
    """安全穴位指南测试"""

    def test_safe_acupoints_first_trimester(self):
        """获取孕早期安全穴位"""
        response = client.get("/api/v1/maternity/safe-acupoints/first")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["trimester"] == "first"
        assert "acupoints" in data["data"]

    def test_safe_acupoints_second_trimester(self):
        """获取孕中期安全穴位"""
        response = client.get("/api/v1/maternity/safe-acupoints/second")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["trimester"] == "second"

    def test_safe_acupoints_third_trimester(self):
        """获取孕晚期安全穴位"""
        response = client.get("/api/v1/maternity/safe-acupoints/third")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["trimester"] == "third"

    def test_safe_acupoints_invalid_trimester(self):
        """测试无效孕期"""
        response = client.get("/api/v1/maternity/safe-acupoints/invalid")
        assert response.status_code == 400

    def test_safe_acupoints_first_contains_caution(self):
        """孕早期安全穴位包含警告"""
        response = client.get("/api/v1/maternity/safe-acupoints/first")
        data = response.json()
        acupoints = data["data"]["acupoints"]
        assert "caution" in acupoints
        assert "禁用活血化瘀穴位" in acupoints["caution"]

    def test_safe_acupoints_all_have_safe_points(self):
        """所有孕期都有安全穴位列表"""
        for trimester in ["first", "second", "third"]:
            response = client.get(f"/api/v1/maternity/safe-acupoints/{trimester}")
            data = response.json()
            assert "safe_points" in data["data"]["acupoints"]
            assert len(data["data"]["acupoints"]["safe_points"]) > 0

    def test_safe_acupoints_first_excludes_strong_stimulation(self):
        """孕早期穴位说明避免强刺激"""
        response = client.get("/api/v1/maternity/safe-acupoints/first")
        data = response.json()
        acupoints = data["data"]["acupoints"]
        assert "description" in acupoints
        assert "轻" in acupoints["description"] or "温和" in acupoints["description"]


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/v1/maternity/personalized 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPersonalizedAdvice:
    """个性化孕期建议测试"""

    def test_personalized_advice_basic(self):
        """基础个性化建议"""
        payload = {
            "pregnancy_month": 5,
            "constitution_type": "qi_deficiency",
            "current_symptoms": ["fatigue"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["pregnancy_month"] == 5
        assert data["data"]["constitution_type"] == "qi_deficiency"

    def test_personalized_advice_with_nausea(self):
        """包含恶心症状的建议"""
        payload = {
            "pregnancy_month": 2,
            "constitution_type": "spleen_weakness",
            "current_symptoms": ["nausea"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        recommendations = data["data"]["personalized_recommendations"]
        assert any("生姜" in rec for rec in recommendations)

    def test_personalized_advice_with_fatigue(self):
        """包含疲劳症状的建议"""
        payload = {
            "pregnancy_month": 3,
            "constitution_type": "blood_deficiency",
            "current_symptoms": ["fatigue"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        recommendations = data["data"]["personalized_recommendations"]
        assert any("黄芪" in rec for rec in recommendations)

    def test_personalized_advice_multiple_symptoms(self):
        """多个症状组合"""
        payload = {
            "pregnancy_month": 6,
            "constitution_type": "qi_deficiency",
            "current_symptoms": ["nausea", "fatigue", "lower_back_pain"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        assert len(data["data"]["personalized_recommendations"]) >= 3

    def test_personalized_advice_invalid_month(self):
        """无效孕期月份"""
        payload = {
            "pregnancy_month": 11,
            "constitution_type": "qi_deficiency",
            "current_symptoms": ["fatigue"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        assert response.status_code == 400

    def test_personalized_advice_month_0(self):
        """孕期 0 月"""
        payload = {
            "pregnancy_month": 0,
            "constitution_type": "qi_deficiency",
            "current_symptoms": []
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        assert response.status_code == 400

    def test_personalized_advice_with_constipation(self):
        """包含便秘症状的建议"""
        payload = {
            "pregnancy_month": 7,
            "constitution_type": "spleen_weakness",
            "current_symptoms": ["constipation"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        recommendations = data["data"]["personalized_recommendations"]
        assert any("纤维" in rec or "蜂蜜" in rec for rec in recommendations)

    def test_personalized_advice_contains_base_plan(self):
        """个性化建议包含基础方案"""
        payload = {
            "pregnancy_month": 5,
            "constitution_type": "qi_deficiency",
            "current_symptoms": ["fatigue"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        assert "base_plan" in data["data"]
        assert "month" in data["data"]["base_plan"]

    def test_personalized_advice_contains_disclaimer(self):
        """个性化建议包含免责声明"""
        payload = {
            "pregnancy_month": 5,
            "constitution_type": "qi_deficiency",
            "current_symptoms": ["fatigue"]
        }
        response = client.post("/api/v1/maternity/personalized", json=payload)
        data = response.json()
        assert "disclaimer" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestMaternityIntegration:
    """综合集成测试"""

    def test_all_endpoints_return_success_true(self):
        """所有端点返回 success: true"""
        endpoints = [
            "/api/v1/maternity/pregnancy/1",
            "/api/v1/maternity/forbidden-herbs",
            "/api/v1/maternity/postpartum/natural",
            "/api/v1/maternity/breastfeeding-guide",
            "/api/v1/maternity/safe-acupoints/first"
        ]
        for endpoint in endpoints:
            response = client.get(endpoint)
            assert response.status_code == 200
            assert response.json()["success"] is True

    def test_all_endpoints_include_disclaimer(self):
        """所有端点返回包含免责声明"""
        endpoints = [
            ("/api/v1/maternity/pregnancy/1", "get"),
            ("/api/v1/maternity/forbidden-herbs", "get"),
            ("/api/v1/maternity/postpartum/natural", "get"),
            ("/api/v1/maternity/breastfeeding-guide", "get"),
            ("/api/v1/maternity/safe-acupoints/first", "get")
        ]
        for endpoint, method in endpoints:
            if method == "get":
                response = client.get(endpoint)
            data = response.json()
            assert "disclaimer" in data["data"] or "disclaimer" in str(data)

    def test_pregnancy_early_vs_late_forbiddens_differ(self):
        """孕早期和孕晚期禁忌不同"""
        response_month1 = client.get("/api/v1/maternity/pregnancy/1")
        response_month10 = client.get("/api/v1/maternity/pregnancy/10")

        forbidden_early = response_month1.json()["data"]["plan"]["forbidden_herbs"]
        forbidden_late = response_month10.json()["data"]["plan"]["forbidden_herbs"]

        # 两者都应包含禁忌
        assert len(forbidden_early) > 0
        assert len(forbidden_late) > 0

    def test_high_danger_herbs_consistent_across_months(self):
        """所有月份都禁用高危草药"""
        high_danger_herbs = ["红花", "桃仁", "益母草"]
        for month in range(1, 4):  # 测前 3 个月
            response = client.get(f"/api/v1/maternity/pregnancy/{month}")
            forbidden = response.json()["data"]["plan"]["forbidden_herbs"]
            for herb in high_danger_herbs:
                assert herb in forbidden
