"""
测试：50 岁以上老年用户 TCM 专项养护 API
覆盖：5 种疾病方案覆盖、季节全测（4 个）、运动强度过滤、自查功能
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/senior/conditions 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditionsList:
    """老年常见问题列表测试"""

    def test_get_all_conditions(self):
        """获取所有老年问题列表"""
        response = client.get("/api/v1/senior/conditions")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "conditions" in data["data"]
        assert isinstance(data["data"]["conditions"], list)
        assert len(data["data"]["conditions"]) > 0

    def test_conditions_contains_5_problems(self):
        """验证包含 5 个老年常见问题"""
        response = client.get("/api/v1/senior/conditions")
        data = response.json()
        condition_ids = [c["id"] for c in data["data"]["conditions"]]
        assert "hypertension" in condition_ids
        assert "osteoporosis" in condition_ids
        assert "memory_decline" in condition_ids
        assert "constipation" in condition_ids
        assert "insomnia" in condition_ids

    def test_conditions_has_brief_description(self):
        """每个条件包含简要说明"""
        response = client.get("/api/v1/senior/conditions")
        data = response.json()
        for condition in data["data"]["conditions"]:
            assert "id" in condition
            assert "condition" in condition
            assert "brief" in condition


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/senior/conditions/{condition_id} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestConditionDetail:
    """老年问题详细方案测试"""

    def test_hypertension_detail(self):
        """获取高血压详细方案"""
        response = client.get("/api/v1/senior/conditions/hypertension")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["id"] == "hypertension"
        assert "problems" in data["data"]

    def test_osteoporosis_detail(self):
        """获取骨质疏松详细方案"""
        response = client.get("/api/v1/senior/conditions/osteoporosis")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "osteoporosis"
        assert "tcm_understanding" in data["data"]

    def test_memory_decline_detail(self):
        """获取记忆力下降详细方案"""
        response = client.get("/api/v1/senior/conditions/memory_decline")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "memory_decline"

    def test_constipation_detail(self):
        """获取便秘详细方案"""
        response = client.get("/api/v1/senior/conditions/constipation")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "constipation"

    def test_insomnia_detail(self):
        """获取失眠详细方案"""
        response = client.get("/api/v1/senior/conditions/insomnia")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "insomnia"

    def test_invalid_condition_id(self):
        """测试无效条件 ID"""
        response = client.get("/api/v1/senior/conditions/invalid_condition")
        assert response.status_code == 404

    def test_hypertension_has_subproblems(self):
        """高血压包含三个子问题（高血压、糖尿病、高血脂）"""
        response = client.get("/api/v1/senior/conditions/hypertension")
        data = response.json()
        problems = data["data"]["problems"]
        assert "hypertension" in problems
        assert "diabetes" in problems
        assert "hyperlipidemia" in problems

    def test_condition_contains_recommended_foods(self):
        """条件方案包含推荐食物"""
        response = client.get("/api/v1/senior/conditions/osteoporosis")
        data = response.json()
        assert "recommended_foods" in data["data"]
        assert isinstance(data["data"]["recommended_foods"], list)

    def test_condition_contains_forbidden_foods(self):
        """条件方案包含禁忌食物"""
        response = client.get("/api/v1/senior/conditions/constipation")
        data = response.json()
        assert "forbidden_foods" in data["data"]

    def test_condition_contains_acupoints(self):
        """条件方案包含穴位"""
        response = client.get("/api/v1/senior/conditions/insomnia")
        data = response.json()
        assert "acupoints" in data["data"]
        assert len(data["data"]["acupoints"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/senior/exercises 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestExercises:
    """老年运动列表测试"""

    def test_get_all_exercises(self):
        """获取所有老年运动"""
        response = client.get("/api/v1/senior/exercises")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "exercises" in data["data"]
        assert isinstance(data["data"]["exercises"], list)
        assert len(data["data"]["exercises"]) >= 10

    def test_filter_very_low_intensity(self):
        """筛选极低强度运动"""
        response = client.get("/api/v1/senior/exercises?intensity=very_low")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        assert all(e["intensity"] == "very_low" for e in exercises)
        assert len(exercises) > 0

    def test_filter_low_intensity(self):
        """筛选低强度运动"""
        response = client.get("/api/v1/senior/exercises?intensity=low")
        assert response.status_code == 200
        data = response.json()
        exercises = data["data"]["exercises"]
        assert all(e["intensity"] == "low" for e in exercises)
        assert len(exercises) > 0

    def test_invalid_intensity_filter(self):
        """测试无效强度筛选"""
        response = client.get("/api/v1/senior/exercises?intensity=high")
        assert response.status_code == 400

    def test_exercise_contains_contraindications(self):
        """运动包含禁忌症"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        for exercise in data["data"]["exercises"]:
            assert "contraindications" in exercise
            assert len(exercise["contraindications"]) > 0

    def test_exercise_contains_duration(self):
        """运动包含时长"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        for exercise in data["data"]["exercises"]:
            assert "duration" in exercise
            assert "分钟" in exercise["duration"]

    def test_tai_chi_included(self):
        """包含太极"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        exercise_names = [e["name"] for e in data["data"]["exercises"]]
        assert "太极" in exercise_names

    def test_baduanjin_included(self):
        """包含八段锦"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        exercise_names = [e["name"] for e in data["data"]["exercises"]]
        # 应包含站式或坐式版本
        assert any("八段锦" in name for name in exercise_names)

    def test_standing_post_included(self):
        """包含站桩"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        exercise_names = [e["name"] for e in data["data"]["exercises"]]
        assert "站桩" in exercise_names

    def test_tai_chi_has_low_intensity(self):
        """太极标记为低强度"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        tai_chi = next((e for e in data["data"]["exercises"] if e["name"] == "太极"), None)
        assert tai_chi is not None
        assert tai_chi["intensity"] == "low"


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/senior/seasonal/{season} 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSeasonalWellness:
    """季节性养生测试"""

    def test_spring_seasonal(self):
        """获取春季养生"""
        response = client.get("/api/v1/senior/seasonal/spring")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["season"] == "春季"
        assert "tcm_principle" in data["data"]

    def test_summer_seasonal(self):
        """获取夏季养生"""
        response = client.get("/api/v1/senior/seasonal/summer")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "夏季"

    def test_autumn_seasonal(self):
        """获取秋季养生"""
        response = client.get("/api/v1/senior/seasonal/autumn")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "秋季"

    def test_winter_seasonal(self):
        """获取冬季养生"""
        response = client.get("/api/v1/senior/seasonal/winter")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "冬季"

    def test_invalid_season(self):
        """测试无效季节"""
        response = client.get("/api/v1/senior/seasonal/invalid_season")
        assert response.status_code == 400

    def test_seasonal_contains_dietary_focus(self):
        """季节方案包含饮食重点"""
        response = client.get("/api/v1/senior/seasonal/spring")
        data = response.json()
        assert "dietary_focus" in data["data"]
        assert "recommended" in data["data"]["dietary_focus"]
        assert "avoid" in data["data"]["dietary_focus"]

    def test_seasonal_contains_lifestyle(self):
        """季节方案包含生活方式建议"""
        response = client.get("/api/v1/senior/seasonal/summer")
        data = response.json()
        assert "lifestyle" in data["data"]
        assert "wake_time" in data["data"]["lifestyle"]

    def test_seasonal_contains_acupoints(self):
        """季节方案包含穴位"""
        response = client.get("/api/v1/senior/seasonal/autumn")
        data = response.json()
        assert "acupoints" in data["data"]
        assert len(data["data"]["acupoints"]) > 0

    def test_spring_involves_liver(self):
        """春季涉及肝"""
        response = client.get("/api/v1/senior/seasonal/spring")
        data = response.json()
        assert "肝" in data["data"]["tcm_principle"]

    def test_summer_involves_heart(self):
        """夏季涉及心"""
        response = client.get("/api/v1/senior/seasonal/summer")
        data = response.json()
        assert "心" in data["data"]["tcm_principle"]

    def test_autumn_involves_lung(self):
        """秋季涉及肺"""
        response = client.get("/api/v1/senior/seasonal/autumn")
        data = response.json()
        assert "肺" in data["data"]["tcm_principle"]

    def test_winter_involves_kidney(self):
        """冬季涉及肾"""
        response = client.get("/api/v1/senior/seasonal/winter")
        data = response.json()
        assert "肾" in data["data"]["tcm_principle"]


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/senior/daily-routine 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDailyRoutine:
    """理想作息测试"""

    def test_get_daily_routine(self):
        """获取理想作息"""
        response = client.get("/api/v1/senior/daily-routine")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "routine" in data["data"]
        assert isinstance(data["data"]["routine"], list)

    def test_routine_covers_24_hours(self):
        """作息覆盖全天时段"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        # 应包含至少 8-9 个主要时段
        assert len(routine) >= 8

    def test_routine_includes_breakfast(self):
        """作息包含早餐"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        activities = [r["activity"] for r in routine]
        assert "早餐" in activities

    def test_routine_includes_sleep(self):
        """作息包含睡眠"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        activities = [r["activity"] for r in routine]
        assert "睡眠" in activities

    def test_routine_includes_midday_rest(self):
        """作息包含午休"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        activities = [r["activity"] for r in routine]
        assert any("午" in activity for activity in activities)

    def test_routine_each_step_has_explanation(self):
        """每个时段都有 TCM 解释"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        for step in routine:
            assert "tcm_explanation" in step
            assert len(step["tcm_explanation"]) > 0

    def test_routine_includes_key_principles(self):
        """作息包含关键原则"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        assert "key_principles" in data["data"]
        assert len(data["data"]["key_principles"]) > 0

    def test_early_wake_time_recommended(self):
        """建议早起"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        wake_step = next((r for r in routine if "起床" in r["activity"]), None)
        assert wake_step is not None
        assert "5" in wake_step["time"] or "6" in wake_step["time"]

    def test_early_sleep_recommended(self):
        """建议早睡"""
        response = client.get("/api/v1/senior/daily-routine")
        data = response.json()
        routine = data["data"]["routine"]
        sleep_step = next((r for r in routine if "睡眠" in r["activity"]), None)
        assert sleep_step is not None
        assert "21" in sleep_step["time"]


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/v1/senior/check 端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestHealthCheck:
    """健康自查测试"""

    def test_health_check_basic(self):
        """基础健康自查"""
        payload = {
            "age": 65,
            "symptoms": ["fatigue"],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["age"] == 65

    def test_health_check_with_insomnia(self):
        """检查失眠症状"""
        payload = {
            "age": 70,
            "symptoms": ["insomnia"],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        recommendations = data["data"]["tcm_recommendations"]
        assert any("失眠" in rec for rec in recommendations)

    def test_health_check_with_memory_decline(self):
        """检查记忆力下降"""
        payload = {
            "age": 75,
            "symptoms": ["memory_decline"],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        recommendations = data["data"]["tcm_recommendations"]
        assert any("记忆" in rec or "黑芝麻" in rec for rec in recommendations)

    def test_health_check_with_hypertension_condition(self):
        """检查高血压现有疾病"""
        payload = {
            "age": 60,
            "symptoms": [],
            "conditions": ["hypertension"]
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        alerts = data["data"]["medical_alerts"]
        assert any("血压" in alert for alert in alerts)

    def test_health_check_with_diabetes_condition(self):
        """检查糖尿病现有疾病"""
        payload = {
            "age": 65,
            "symptoms": [],
            "conditions": ["diabetes"]
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        alerts = data["data"]["medical_alerts"]
        assert any("血糖" in alert for alert in alerts)

    def test_health_check_multiple_symptoms(self):
        """多症状检查"""
        payload = {
            "age": 70,
            "symptoms": ["fatigue", "insomnia", "memory_decline"],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        recommendations = data["data"]["tcm_recommendations"]
        assert len(recommendations) >= 3

    def test_health_check_multiple_conditions(self):
        """多疾病检查"""
        payload = {
            "age": 65,
            "symptoms": [],
            "conditions": ["hypertension", "diabetes", "osteoporosis"]
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        alerts = data["data"]["medical_alerts"]
        assert len(alerts) >= 3

    def test_health_check_age_too_young(self):
        """年龄过小测试"""
        payload = {
            "age": 45,
            "symptoms": [],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        assert response.status_code == 400

    def test_health_check_age_boundary_50(self):
        """边界年龄 50 岁"""
        payload = {
            "age": 50,
            "symptoms": [],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        assert response.status_code == 200

    def test_health_check_no_symptoms_no_conditions(self):
        """无症状无疾病"""
        payload = {
            "age": 70,
            "symptoms": [],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        recommendations = data["data"]["tcm_recommendations"]
        assert len(recommendations) > 0
        # 应给出一般养生建议
        assert any("作息" in rec or "运动" in rec for rec in recommendations)

    def test_health_check_returns_suggested_exercises(self):
        """返回推荐运动"""
        payload = {
            "age": 68,
            "symptoms": ["fatigue"],
            "conditions": []
        }
        response = client.post("/api/v1/senior/check", json=payload)
        data = response.json()
        assert "suggested_exercises" in data["data"]


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSeniorWellnessIntegration:
    """综合集成测试"""

    def test_all_endpoints_return_success_true(self):
        """所有端点返回 success: true"""
        endpoints = [
            "/api/v1/senior/conditions",
            "/api/v1/senior/conditions/hypertension",
            "/api/v1/senior/exercises",
            "/api/v1/senior/seasonal/spring",
            "/api/v1/senior/daily-routine"
        ]
        for endpoint in endpoints:
            response = client.get(endpoint)
            assert response.status_code == 200
            assert response.json()["success"] is True

    def test_seasonal_wellness_covers_all_seasons(self):
        """季节养生覆盖四个季节"""
        seasons = ["spring", "summer", "autumn", "winter"]
        for season in seasons:
            response = client.get(f"/api/v1/senior/seasonal/{season}")
            assert response.status_code == 200

    def test_exercise_count_reasonable(self):
        """运动数量合理（至少 10 种）"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        assert data["data"]["total"] >= 10

    def test_condition_count_5(self):
        """老年问题数量为 5 个"""
        response = client.get("/api/v1/senior/conditions")
        data = response.json()
        assert data["data"]["total"] == 5

    def test_exercises_have_varying_intensity(self):
        """运动包含不同强度"""
        response = client.get("/api/v1/senior/exercises")
        data = response.json()
        intensities = set(e["intensity"] for e in data["data"]["exercises"])
        assert "very_low" in intensities
        assert "low" in intensities
