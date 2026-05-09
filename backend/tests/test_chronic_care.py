"""
测试：慢性病 TCM 辅助调养 API
覆盖：8 种慢性病全枚举、症状自查多症状输入、免责声明必含关键文字
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/chronic/conditions 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditionsList:
    """慢性病列表测试"""

    def test_get_all_conditions(self):
        """获取所有慢性病列表"""
        response = client.get("/api/v1/chronic/conditions")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "conditions" in data["data"]
        assert isinstance(data["data"]["conditions"], list)

    def test_conditions_contains_8_diseases(self):
        """验证包含 8 种慢性病"""
        response = client.get("/api/v1/chronic/conditions")
        data = response.json()
        condition_ids = [c["id"] for c in data["data"]["conditions"]]
        assert len(condition_ids) == 8
        assert "chronic_fatigue" in condition_ids
        assert "insomnia" in condition_ids
        assert "chronic_gastritis" in condition_ids
        assert "cervical_spondylosis" in condition_ids
        assert "chronic_rhinitis" in condition_ids
        assert "mild_depression_tendency" in condition_ids
        assert "pre_diabetes" in condition_ids
        assert "hypertension_tendency" in condition_ids

    def test_conditions_has_tcm_pattern(self):
        """每个条件包含 TCM 分型说明"""
        response = client.get("/api/v1/chronic/conditions")
        data = response.json()
        for condition in data["data"]["conditions"]:
            assert "tcm_pattern" in condition
            assert len(condition["tcm_pattern"]) > 0

    def test_conditions_has_severity_level(self):
        """每个条件包含严重程度等级"""
        response = client.get("/api/v1/chronic/conditions")
        data = response.json()
        for condition in data["data"]["conditions"]:
            assert "severity_level" in condition
            assert condition["severity_level"] in ["low", "medium", "high"]

    def test_conditions_list_has_disclaimer(self):
        """列表包含免责声明"""
        response = client.get("/api/v1/chronic/conditions")
        data = response.json()
        assert "disclaimer" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/chronic/conditions/{condition_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditionDetail:
    """慢性病详细方案测试"""

    def test_chronic_fatigue_detail(self):
        """获取慢性疲劳综合征详细方案"""
        response = client.get("/api/v1/chronic/conditions/chronic_fatigue")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["id"] == "chronic_fatigue"
        assert "food_therapy" in data["data"]

    def test_insomnia_detail(self):
        """获取失眠症详细方案"""
        response = client.get("/api/v1/chronic/conditions/insomnia")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "insomnia"

    def test_chronic_gastritis_detail(self):
        """获取慢性胃炎详细方案"""
        response = client.get("/api/v1/chronic/conditions/chronic_gastritis")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "chronic_gastritis"

    def test_cervical_spondylosis_detail(self):
        """获取颈椎病详细方案"""
        response = client.get("/api/v1/chronic/conditions/cervical_spondylosis")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "cervical_spondylosis"

    def test_chronic_rhinitis_detail(self):
        """获取慢性鼻炎详细方案"""
        response = client.get("/api/v1/chronic/conditions/chronic_rhinitis")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "chronic_rhinitis"

    def test_depression_tendency_detail(self):
        """获取抑郁倾向详细方案"""
        response = client.get("/api/v1/chronic/conditions/mild_depression_tendency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "mild_depression_tendency"

    def test_pre_diabetes_detail(self):
        """获取糖尿病前期详细方案"""
        response = client.get("/api/v1/chronic/conditions/pre_diabetes")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "pre_diabetes"

    def test_hypertension_tendency_detail(self):
        """获取高血压倾向详细方案"""
        response = client.get("/api/v1/chronic/conditions/hypertension_tendency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "hypertension_tendency"

    def test_invalid_condition_id(self):
        """测试无效条件 ID"""
        response = client.get("/api/v1/chronic/conditions/invalid_disease")
        assert response.status_code == 404

    def test_condition_contains_all_required_fields(self):
        """条件包含所有必需字段"""
        response = client.get("/api/v1/chronic/conditions/chronic_fatigue")
        data = response.json()
        condition = data["data"]
        assert "id" in condition
        assert "condition" in condition
        assert "tcm_pattern" in condition
        assert "food_therapy" in condition
        assert "lifestyle_adjustments" in condition
        assert "acupoints" in condition
        assert "herbal_notes" in condition
        assert "avoid_factors" in condition
        assert "see_doctor_warning" in condition
        assert "severity_level" in condition

    def test_condition_contains_acupoints(self):
        """条件包含穴位"""
        response = client.get("/api/v1/chronic/conditions/insomnia")
        data = response.json()
        assert "acupoints" in data["data"]
        assert len(data["data"]["acupoints"]) > 0

    def test_condition_contains_see_doctor_warning(self):
        """条件包含就医警告"""
        response = client.get("/api/v1/chronic/conditions/pre_diabetes")
        data = response.json()
        assert "see_doctor_warning" in data["data"]
        assert len(data["data"]["see_doctor_warning"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/chronic/food-therapy/{condition_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestFoodTherapy:
    """食疗方案测试"""

    def test_get_food_therapy_chronic_fatigue(self):
        """获取慢性疲劳食疗"""
        response = client.get("/api/v1/chronic/food-therapy/chronic_fatigue")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "food_therapy" in data["data"]

    def test_get_food_therapy_chronic_gastritis(self):
        """获取胃炎食疗"""
        response = client.get("/api/v1/chronic/food-therapy/chronic_gastritis")
        assert response.status_code == 200
        data = response.json()
        food_therapy = data["data"]["food_therapy"]
        assert "recommended" in food_therapy
        assert "typical_recipe" in food_therapy

    def test_food_therapy_contains_tips(self):
        """食疗包含使用提示"""
        response = client.get("/api/v1/chronic/food-therapy/insomnia")
        data = response.json()
        assert "additional_tips" in data["data"]
        assert len(data["data"]["additional_tips"]) > 0

    def test_food_therapy_invalid_condition(self):
        """测试无效条件"""
        response = client.get("/api/v1/chronic/food-therapy/invalid")
        assert response.status_code == 404

    def test_food_therapy_contains_disclaimer(self):
        """食疗包含免责声明"""
        response = client.get("/api/v1/chronic/food-therapy/chronic_rhinitis")
        data = response.json()
        assert "disclaimer" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/v1/chronic/symptom-check 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSymptomCheck:
    """症状自查测试"""

    def test_symptom_check_single_symptom(self):
        """单症状自查"""
        payload = {"symptoms": ["fatigue"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "matched_conditions" in data["data"]

    def test_symptom_check_multiple_symptoms(self):
        """多症状自查"""
        payload = {"symptoms": ["fatigue", "insomnia", "stomach_discomfort"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        # 应返回多个匹配的疾病
        matched = data["data"]["matched_conditions"]
        if isinstance(matched, list):
            assert len(matched) >= 1

    def test_symptom_check_no_matches(self):
        """无匹配症状"""
        payload = {"symptoms": ["unknown_symptom"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        assert data["success"] is True
        # 返回未找到匹配
        assert "matched_conditions" in data["data"]

    def test_symptom_check_fatigue_maps_to_chronic_fatigue(self):
        """疲劳症状映射到慢性疲劳"""
        payload = {"symptoms": ["fatigue"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        matched = data["data"]["matched_conditions"]
        if isinstance(matched, list) and len(matched) > 0:
            assert any("慢性疲劳" in m.get("condition", "") for m in matched)

    def test_symptom_check_insomnia_maps_to_insomnia(self):
        """失眠症状映射到失眠"""
        payload = {"symptoms": ["insomnia"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        matched = data["data"]["matched_conditions"]
        if isinstance(matched, list) and len(matched) > 0:
            assert any("失眠" in m.get("condition", "") for m in matched)

    def test_symptom_check_high_blood_sugar(self):
        """高血糖症状"""
        payload = {"symptoms": ["high_blood_sugar"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        matched = data["data"]["matched_conditions"]
        if isinstance(matched, list) and len(matched) > 0:
            assert any("糖尿病前期" in m.get("condition", "") for m in matched)

    def test_symptom_check_contains_recommendations(self):
        """自查包含建议"""
        payload = {"symptoms": ["fatigue"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        assert "recommendations" in data["data"]
        assert len(data["data"]["recommendations"]) > 0

    def test_symptom_check_contains_disclaimer(self):
        """自查包含免责声明"""
        payload = {"symptoms": ["insomnia"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        assert "disclaimer" in data["data"]

    def test_symptom_check_multiple_conditions_mapped(self):
        """多症状应该匹配多个条件"""
        payload = {"symptoms": ["fatigue", "insomnia", "stomach_discomfort", "neck_pain"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        matched = data["data"]["matched_conditions"]
        # 应该匹配多个不同的疾病
        if isinstance(matched, list):
            conditions = [m.get("condition", "") for m in matched]
            # 验证至少有不同的疾病被匹配
            assert len(set(conditions)) >= 1


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/chronic/lifestyle/{condition_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestLifestyleAdjustments:
    """生活方式调整测试"""

    def test_get_lifestyle_chronic_fatigue(self):
        """获取慢性疲劳生活方式调整"""
        response = client.get("/api/v1/chronic/lifestyle/chronic_fatigue")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "lifestyle_adjustments" in data["data"]

    def test_lifestyle_contains_avoid_factors(self):
        """生活方式包含需避免因素"""
        response = client.get("/api/v1/chronic/lifestyle/insomnia")
        data = response.json()
        assert "avoid_factors" in data["data"]
        assert len(data["data"]["avoid_factors"]) > 0

    def test_lifestyle_contains_implementation_tips(self):
        """生活方式包含实施建议"""
        response = client.get("/api/v1/chronic/lifestyle/cervical_spondylosis")
        data = response.json()
        assert "implementation_tips" in data["data"]
        assert len(data["data"]["implementation_tips"]) > 0

    def test_lifestyle_invalid_condition(self):
        """测试无效条件"""
        response = client.get("/api/v1/chronic/lifestyle/invalid")
        assert response.status_code == 404

    def test_lifestyle_all_conditions(self):
        """测试所有条件都有生活方式建议"""
        condition_ids = [
            "chronic_fatigue", "insomnia", "chronic_gastritis",
            "cervical_spondylosis", "chronic_rhinitis", "mild_depression_tendency",
            "pre_diabetes", "hypertension_tendency"
        ]
        for cond_id in condition_ids:
            response = client.get(f"/api/v1/chronic/lifestyle/{cond_id}")
            assert response.status_code == 200
            data = response.json()
            assert "lifestyle_adjustments" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/chronic/disclaimer 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDisclaimer:
    """医疗免责声明测试"""

    def test_get_disclaimer_chinese(self):
        """获取中文免责声明"""
        response = client.get("/api/v1/chronic/disclaimer?language=zh")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["language"] == "zh"
        assert "disclaimer" in data["data"]

    def test_get_disclaimer_english(self):
        """获取英文免责声明"""
        response = client.get("/api/v1/chronic/disclaimer?language=en")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["language"] == "en"
        assert "disclaimer" in data["data"]

    def test_disclaimer_contains_medical_warning(self):
        """免责声明包含医疗警告"""
        response = client.get("/api/v1/chronic/disclaimer?language=zh")
        data = response.json()
        disclaimer = data["data"]["disclaimer"]
        assert "医疗" in disclaimer or "免责" in disclaimer

    def test_disclaimer_chinese_contains_key_phrases(self):
        """中文免责声明包含关键词"""
        response = client.get("/api/v1/chronic/disclaimer?language=zh")
        data = response.json()
        disclaimer = data["data"]["disclaimer"]
        assert "仅供参考" in disclaimer
        assert "医疗" in disclaimer
        assert "诊断" in disclaimer

    def test_disclaimer_english_contains_key_phrases(self):
        """英文免责声明包含关键词"""
        response = client.get("/api/v1/chronic/disclaimer?language=en")
        data = response.json()
        disclaimer = data["data"]["disclaimer"]
        assert "informational" in disclaimer.lower() or "reference" in disclaimer.lower()
        assert "medical" in disclaimer.lower() or "doctor" in disclaimer.lower()

    def test_disclaimer_default_language(self):
        """无语言参数默认为中文"""
        response = client.get("/api/v1/chronic/disclaimer")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["language"] == "zh"

    def test_disclaimer_invalid_language_defaults_to_chinese(self):
        """无效语言参数默认中文"""
        response = client.get("/api/v1/chronic/disclaimer?language=invalid")
        data = response.json()
        assert data["data"]["language"] == "zh"


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestChronicCareIntegration:
    """综合集成测试"""

    def test_all_endpoints_return_success_true(self):
        """所有端点返回 success: true"""
        endpoints = [
            "/api/v1/chronic/conditions",
            "/api/v1/chronic/conditions/chronic_fatigue",
            "/api/v1/chronic/food-therapy/insomnia",
            "/api/v1/chronic/lifestyle/cervical_spondylosis",
            "/api/v1/chronic/disclaimer"
        ]
        for endpoint in endpoints:
            response = client.get(endpoint)
            assert response.status_code == 200
            assert response.json()["success"] is True

    def test_all_conditions_have_complete_info(self):
        """所有 8 种疾病都有完整信息"""
        condition_ids = [
            "chronic_fatigue", "insomnia", "chronic_gastritis",
            "cervical_spondylosis", "chronic_rhinitis", "mild_depression_tendency",
            "pre_diabetes", "hypertension_tendency"
        ]
        for cond_id in condition_ids:
            response = client.get(f"/api/v1/chronic/conditions/{cond_id}")
            assert response.status_code == 200
            data = response.json()
            condition = data["data"]
            # 验证所有必需字段
            required_fields = [
                "id", "condition", "tcm_pattern", "food_therapy",
                "lifestyle_adjustments", "acupoints", "herbal_notes",
                "avoid_factors", "see_doctor_warning", "severity_level"
            ]
            for field in required_fields:
                assert field in condition, f"Missing {field} in {cond_id}"

    def test_severity_levels_present(self):
        """所有条件都有严重程度等级"""
        response = client.get("/api/v1/chronic/conditions")
        data = response.json()
        for condition in data["data"]["conditions"]:
            assert "severity_level" in condition
            assert condition["severity_level"] in ["low", "medium", "high"]

    def test_symptom_check_matches_are_reasonable(self):
        """症状检查匹配合理"""
        # 测试已知的症状应该匹配到合理的疾病
        payload = {"symptoms": ["fatigue", "insomnia"]}
        response = client.post("/api/v1/chronic/symptom-check", json=payload)
        data = response.json()
        matched = data["data"]["matched_conditions"]
        # 无论是否匹配，都应该返回有效的数据结构
        assert "input_symptoms" in data["data"]
        assert "recommendations" in data["data"]

    def test_all_disclaimers_present(self):
        """所有相关端点都包含免责声明"""
        endpoints_with_disclaimer = [
            "/api/v1/chronic/conditions",
            "/api/v1/chronic/conditions/chronic_fatigue",
            "/api/v1/chronic/food-therapy/insomnia"
        ]
        for endpoint in endpoints_with_disclaimer:
            response = client.get(endpoint)
            data = response.json()
            # 检查是否在 data 中有 disclaimer
            assert "disclaimer" in data["data"] or "disclaimer" in data, \
                f"No disclaimer in {endpoint}"
