"""
顺时 — 儿童青少年 TCM 养护 API 测试
包含年龄段指南、常见问题、季节养护、推拿手法、个性化建议等测试。
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# ─────────────────────────────────────────────────────────────────────────────
# 年龄段指南测试
# ─────────────────────────────────────────────────────────────────────────────

class TestAgeGuide:
    """年龄段养护指南测试"""

    def test_age_guide_6_to_9(self):
        """测试6-9岁年龄段指南"""
        response = client.get("/api/v1/youth/age-guide/6-9")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age_range"] == "6-9岁"
        assert "growth_focus" in data["data"]
        assert "tcm_organ_priority" in data["data"]
        assert "sleep_requirements" in data["data"]

    def test_age_guide_10_to_13(self):
        """测试10-13岁年龄段指南"""
        response = client.get("/api/v1/youth/age-guide/10-13")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age_range"] == "10-13岁"
        assert "stage_name" in data["data"]
        assert "生长突增期" in data["data"]["stage_name"]

    def test_age_guide_14_to_18(self):
        """测试14-18岁年龄段指南"""
        response = client.get("/api/v1/youth/age-guide/14-18")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age_range"] == "14-18岁"
        assert "青春期" in data["data"]["stage_name"]

    def test_age_guide_invalid_age(self):
        """测试无效年龄段返回404"""
        response = client.get("/api/v1/youth/age-guide/20-25")
        assert response.status_code == 404

    def test_age_guide_structure(self):
        """测试年龄段指南结构完整性"""
        response = client.get("/api/v1/youth/age-guide/6-9")
        data = response.json()
        age_guide = data["data"]
        assert "age_range" in age_guide
        assert "stage_name" in age_guide
        assert "tcm_organ_priority" in age_guide
        assert "dietary_needs" in age_guide
        assert "exercise_minutes_daily" in age_guide
        assert "seasonal_focus" in age_guide

    def test_age_guide_seasonal_focus(self):
        """测试年龄段的季节性重点"""
        response = client.get("/api/v1/youth/age-guide/10-13")
        data = response.json()
        seasonal = data["data"]["seasonal_focus"]
        seasons = ["spring", "summer", "autumn", "winter"]
        for season in seasons:
            assert season in seasonal


# ─────────────────────────────────────────────────────────────────────────────
# 常见问题列表测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditions:
    """常见问题列表测试"""

    def test_conditions_list(self):
        """测试获取常见问题列表"""
        response = client.get("/api/v1/youth/conditions")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert isinstance(data["data"], list)
        assert len(data["data"]) >= 10

    def test_conditions_item_structure(self):
        """测试列表项结构"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition = data["data"][0]
        assert "condition_id" in condition
        assert "name" in condition
        assert "tcm_cause" in condition
        assert "age_applicable" in condition

    def test_conditions_contains_myopia(self):
        """测试列表包含近视防控"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition_names = [c["name"] for c in data["data"]]
        assert "近视防控" in condition_names

    def test_conditions_contains_attention_deficit(self):
        """测试列表包含注意力不足"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition_names = [c["name"] for c in data["data"]]
        assert "注意力不足" in condition_names

    def test_conditions_contains_poor_appetite(self):
        """测试列表包含厌食/偏食"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition_names = [c["name"] for c in data["data"]]
        assert "厌食/偏食" in condition_names

    def test_conditions_contains_recurrent_cold(self):
        """测试列表包含反复感冒"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition_names = [c["name"] for c in data["data"]]
        assert "反复感冒" in condition_names

    def test_conditions_contains_acne(self):
        """测试列表包含青春期痘痘"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        condition_names = [c["name"] for c in data["data"]]
        assert "青春期痘痘" in condition_names


# ─────────────────────────────────────────────────────────────────────────────
# 问题详情测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditionDetail:
    """问题详情测试"""

    def test_condition_detail_myopia(self):
        """测试近视防控详情"""
        response = client.get("/api/v1/youth/conditions/myopia")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "近视防控"
        assert "prevention_measures" in data["data"]
        assert "diet" in data["data"]
        assert "eye_exercises" in data["data"]

    def test_condition_detail_attention_deficit(self):
        """测试注意力不足详情"""
        response = client.get("/api/v1/youth/conditions/attention_deficit")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "注意力不足"
        assert "diet" in data["data"]
        assert "brain_boosting_foods" in data["data"]

    def test_condition_detail_poor_appetite(self):
        """测试厌食详情"""
        response = client.get("/api/v1/youth/conditions/poor_appetite")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "厌食/偏食"
        assert "diet" in data["data"]
        assert "home_massage" in data["data"]

    def test_condition_detail_acne(self):
        """测试痘痘详情"""
        response = client.get("/api/v1/youth/conditions/acne")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "青春期痘痘"
        assert "avoid_foods" in data["data"]
        assert "skincare" in data["data"]

    def test_condition_detail_invalid_id(self):
        """测试无效条件ID返回404"""
        response = client.get("/api/v1/youth/conditions/invalid_condition")
        assert response.status_code == 404

    def test_condition_detail_diet_info(self):
        """测试条件详情包含食疗信息"""
        response = client.get("/api/v1/youth/conditions/myopia")
        data = response.json()
        diet = data["data"]["diet"]
        assert isinstance(diet, list)
        assert len(diet) > 0
        assert "ingredient" in diet[0]
        assert "benefit" in diet[0]


# ─────────────────────────────────────────────────────────────────────────────
# 季节性养护测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSeasonalCare:
    """季节性儿童养护测试"""

    def test_seasonal_care_spring(self):
        """测试春季养护"""
        response = client.get("/api/v1/youth/seasonal/spring")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["season"] == "春季"
        assert "key_points" in data["data"]
        assert "recommended_diet" in data["data"]

    def test_seasonal_care_summer(self):
        """测试夏季养护"""
        response = client.get("/api/v1/youth/seasonal/summer")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["season"] == "夏季"
        assert "tcm_principle" in data["data"]

    def test_seasonal_care_autumn(self):
        """测试秋季养护"""
        response = client.get("/api/v1/youth/seasonal/autumn")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["season"] == "秋季"
        # 秋季应强调长高
        assert "长高" in data["data"]["tcm_principle"] or "长高" in str(data["data"])

    def test_seasonal_care_winter(self):
        """测试冬季养护"""
        response = client.get("/api/v1/youth/seasonal/winter")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["season"] == "冬季"

    def test_seasonal_care_invalid_season(self):
        """测试无效季节返回404"""
        response = client.get("/api/v1/youth/seasonal/invalid_season")
        assert response.status_code == 404

    def test_seasonal_care_structure(self):
        """测试季节养护结构完整性"""
        response = client.get("/api/v1/youth/seasonal/spring")
        data = response.json()
        seasonal = data["data"]
        assert "season" in seasonal
        assert "tcm_principle" in seasonal
        assert "key_points" in seasonal
        assert "recommended_diet" in seasonal
        assert "avoid" in seasonal

    def test_seasonal_care_all_seasons(self):
        """测试所有四季都支持"""
        seasons = ["spring", "summer", "autumn", "winter"]
        for season in seasons:
            response = client.get(f"/api/v1/youth/seasonal/{season}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True


# ─────────────────────────────────────────────────────────────────────────────
# 推拿手法指南测试
# ─────────────────────────────────────────────────────────────────────────────

class TestMassageGuide:
    """推拿手法指南测试"""

    def test_massage_guide_basic(self):
        """测试推拿指南基本信息"""
        response = client.get("/api/v1/youth/massage-guide")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "techniques" in data["data"]
        assert "important_notes" in data["data"]

    def test_massage_guide_techniques(self):
        """测试推拿手法列表"""
        response = client.get("/api/v1/youth/massage-guide")
        data = response.json()
        techniques = data["data"]["techniques"]
        assert len(techniques) >= 5

    def test_massage_guide_technique_structure(self):
        """测试单个手法结构完整性"""
        response = client.get("/api/v1/youth/massage-guide")
        data = response.json()
        technique = data["data"]["techniques"][0]
        assert "name" in technique
        assert "body_part" in technique
        assert "technique" in technique
        assert "duration_minutes" in technique
        assert "benefit" in technique
        assert "when_to_use" in technique

    def test_massage_guide_includes_push_technique(self):
        """测试包含推法"""
        response = client.get("/api/v1/youth/massage-guide")
        data = response.json()
        technique_names = [t["name"] for t in data["data"]["techniques"]]
        assert "推法" in technique_names

    def test_massage_guide_includes_abdomen_technique(self):
        """测试包含摩腹法"""
        response = client.get("/api/v1/youth/massage-guide")
        data = response.json()
        technique_names = [t["name"] for t in data["data"]["techniques"]]
        assert "摩腹法" in technique_names

    def test_massage_guide_important_notes(self):
        """测试重要注意事项"""
        response = client.get("/api/v1/youth/massage-guide")
        data = response.json()
        notes = data["data"]["important_notes"]
        assert isinstance(notes, list)
        assert len(notes) >= 6
        assert any("力度" in note for note in notes)


# ─────────────────────────────────────────────────────────────────────────────
# 个性化建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPersonalizedAdvice:
    """个性化建议测试"""

    def test_advice_age_7(self):
        """测试7岁儿童建议"""
        response = client.post("/api/v1/youth/advice", json={"age": 7, "symptoms": ["近视"]})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age"] == 7
        assert data["data"]["age_group"] == "6-9"

    def test_advice_age_12(self):
        """测试12岁儿童建议"""
        response = client.post("/api/v1/youth/advice", json={"age": 12, "symptoms": ["注意力不足"]})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age_group"] == "10-13"

    def test_advice_age_16(self):
        """测试16岁青少年建议"""
        response = client.post("/api/v1/youth/advice", json={"age": 16, "symptoms": ["考试焦虑"]})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age_group"] == "14-18"

    def test_advice_multiple_symptoms(self):
        """测试多症状建议"""
        response = client.post("/api/v1/youth/advice", json={
            "age": 10,
            "symptoms": ["近视", "厌食", "反复感冒"]
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]["condition_advices"]) > 0

    def test_advice_with_season(self):
        """测试包含季节建议"""
        response = client.post("/api/v1/youth/advice", json={
            "age": 9,
            "symptoms": ["近视"],
            "season": "autumn"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["seasonal_tips"]["season"] == "秋季"

    def test_advice_invalid_age_too_young(self):
        """测试年龄过小（<6）"""
        response = client.post("/api/v1/youth/advice", json={"age": 5, "symptoms": ["近视"]})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_advice_invalid_age_too_old(self):
        """测试年龄过大（>18）"""
        response = client.post("/api/v1/youth/advice", json={"age": 19, "symptoms": ["近视"]})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_advice_structure(self):
        """测试建议结构完整性"""
        response = client.post("/api/v1/youth/advice", json={
            "age": 11,
            "symptoms": ["注意力不足"],
            "season": "spring"
        })
        data = response.json()
        assert "age" in data["data"]
        assert "age_group" in data["data"]
        assert "age_guide_summary" in data["data"]
        assert "condition_advices" in data["data"]
        assert "seasonal_tips" in data["data"]

    def test_advice_age_guide_summary(self):
        """测试年龄段摘要信息"""
        response = client.post("/api/v1/youth/advice", json={"age": 8, "symptoms": []})
        data = response.json()
        summary = data["data"]["age_guide_summary"]
        assert "stage_name" in summary
        assert "growth_focus" in summary
        assert "sleep_requirements" in summary
        assert "exercise_minutes_daily" in summary

    def test_advice_empty_symptoms(self):
        """测试空症状列表"""
        response = client.post("/api/v1/youth/advice", json={"age": 9, "symptoms": []})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_advice_all_valid_ages(self):
        """测试所有有效年龄（6-18）"""
        for age in [6, 9, 10, 13, 14, 18]:
            response = client.post("/api/v1/youth/advice", json={"age": age, "symptoms": []})
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """综合功能测试"""

    def test_all_endpoints_response_format(self):
        """测试所有端点的响应格式一致"""
        endpoints = [
            ("/api/v1/youth/age-guide/6-9", "GET"),
            ("/api/v1/youth/conditions", "GET"),
            ("/api/v1/youth/conditions/myopia", "GET"),
            ("/api/v1/youth/seasonal/spring", "GET"),
            ("/api/v1/youth/massage-guide", "GET"),
        ]

        for endpoint, method in endpoints:
            if method == "GET":
                response = client.get(endpoint)
            data = response.json()
            assert "success" in data
            assert "data" in data

    def test_age_groups_all_supported(self):
        """测试所有年龄段都支持"""
        age_groups = ["6-9", "10-13", "14-18"]
        for age_group in age_groups:
            response = client.get(f"/api/v1/youth/age-guide/{age_group}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_seasons_all_supported(self):
        """测试所有季节都支持"""
        seasons = ["spring", "summer", "autumn", "winter"]
        for season in seasons:
            response = client.get(f"/api/v1/youth/seasonal/{season}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_conditions_minimum_count(self):
        """测试至少10种问题被覆盖"""
        response = client.get("/api/v1/youth/conditions")
        data = response.json()
        assert len(data["data"]) >= 10

    def test_myopia_condition_coverage(self):
        """测试近视防控被正确实现"""
        response = client.get("/api/v1/youth/conditions/myopia")
        data = response.json()
        assert data["success"] is True
        assert "prevention_measures" in data["data"]
        assert "diet" in data["data"]
        assert "eye_exercises" in data["data"]

    def test_acne_condition_age_coverage(self):
        """测试痘痘问题仅针对青少年"""
        response = client.get("/api/v1/youth/conditions/acne")
        data = response.json()
        age_applicable = data["data"]["age_applicable"]
        assert "14-18" in age_applicable

    def test_delayed_growth_age_coverage(self):
        """测试生长发育迟缓针对特定年龄"""
        response = client.get("/api/v1/youth/conditions/delayed_growth")
        data = response.json()
        age_applicable = data["data"]["age_applicable"]
        assert "10-13" in age_applicable
