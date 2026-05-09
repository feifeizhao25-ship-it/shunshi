"""
顺时 — 职场白领 TCM 养生 API 测试
包含久坐方案、加班时段、症状缓解等功能测试。
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# ─────────────────────────────────────────────────────────────────────────────
# 久坐解乏动作方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDeskExercises:
    """久坐解乏动作方案测试"""

    def test_desk_exercises_5min(self):
        """测试5分钟方案"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=5min")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["duration_minutes"] == 5
        assert "exercises" in data["data"]
        assert len(data["data"]["exercises"]) >= 3
        assert "tcm_theory" in data["data"]

    def test_desk_exercises_10min(self):
        """测试10分钟方案"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=10min")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["duration_minutes"] == 10
        assert "exercises" in data["data"]
        assert len(data["data"]["exercises"]) >= 4

    def test_desk_exercises_20min(self):
        """测试20分钟方案"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=20min")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["duration_minutes"] == 20
        assert "exercises" in data["data"]
        assert len(data["data"]["exercises"]) >= 4

    def test_desk_exercises_invalid_duration(self):
        """测试无效的时长参数"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=15min")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False
        assert "error" in data["data"]

    def test_desk_exercises_default_duration(self):
        """测试默认时长（应为5min）"""
        response = client.get("/api/v1/workplace/desk-exercises")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["duration_minutes"] == 5

    def test_desk_exercises_exercise_structure(self):
        """测试单个动作的结构完整性"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=5min")
        data = response.json()
        exercise = data["data"]["exercises"][0]
        assert "name" in exercise
        assert "steps" in exercise
        assert "duration_seconds" in exercise
        assert "benefit" in exercise
        assert isinstance(exercise["steps"], list)
        assert len(exercise["steps"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 护眼完整方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestEyeCare:
    """护眼完整方案测试"""

    def test_eye_care_basic(self):
        """测试护眼方案基本信息"""
        response = client.get("/api/v1/workplace/eye-care")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "diet" in data["data"]
        assert "eye_protection_rule" in data["data"]
        assert "acupoints" in data["data"]
        assert "daily_habits" in data["data"]

    def test_eye_care_diet_content(self):
        """测试食疗内容"""
        response = client.get("/api/v1/workplace/eye-care")
        data = response.json()
        diet = data["data"]["diet"]
        assert len(diet) >= 5
        assert all("ingredient" in item for item in diet)
        assert all("benefit" in item for item in diet)
        assert all("usage" in item for item in diet)

    def test_eye_care_20_20_20_rule(self):
        """测试20-20-20护眼法则"""
        response = client.get("/api/v1/workplace/eye-care")
        data = response.json()
        rule = data["data"]["eye_protection_rule"]
        assert rule["name"] == "20-20-20护眼法则"
        assert "description" in rule
        assert "tcm_correspondence" in rule
        assert "implementation" in rule
        assert len(rule["implementation"]) >= 4

    def test_eye_care_acupoints(self):
        """测试眼部穴位信息"""
        response = client.get("/api/v1/workplace/eye-care")
        data = response.json()
        acupoints = data["data"]["acupoints"]
        assert len(acupoints) >= 3
        acupoint_names = [ap["name"] for ap in acupoints]
        assert "睛明穴" in acupoint_names
        assert "四白穴" in acupoint_names
        assert "太阳穴" in acupoint_names

    def test_eye_care_daily_habits(self):
        """测试日常习惯建议"""
        response = client.get("/api/v1/workplace/eye-care")
        data = response.json()
        habits = data["data"]["daily_habits"]
        assert len(habits) >= 5
        assert all(isinstance(habit, str) for habit in habits)


# ─────────────────────────────────────────────────────────────────────────────
# 会议间隙快速恢复测试
# ─────────────────────────────────────────────────────────────────────────────

class TestQuickRecovery:
    """会议间隙快速恢复测试"""

    def test_quick_recovery_basic(self):
        """测试快速恢复方案基本信息"""
        response = client.get("/api/v1/workplace/quick-recovery")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "fatigue_relief" in data["data"]
        assert "breathing_exercise" in data["data"]
        assert "rejuvenating_foods" in data["data"]

    def test_quick_recovery_fatigue_relief(self):
        """测试疲劳缓解方案"""
        response = client.get("/api/v1/workplace/quick-recovery")
        data = response.json()
        fatigue = data["data"]["fatigue_relief"]
        assert fatigue["duration_minutes"] == 5
        assert "acupoints" in fatigue
        assert len(fatigue["acupoints"]) >= 3

    def test_quick_recovery_breathing(self):
        """测试呼吸调理方案"""
        response = client.get("/api/v1/workplace/quick-recovery")
        data = response.json()
        breathing = data["data"]["breathing_exercise"]
        assert breathing["duration_minutes"] == 3
        assert breathing["technique"] == "腹式呼吸（丹田呼吸）"
        assert "steps" in breathing
        assert "benefit" in breathing

    def test_quick_recovery_foods(self):
        """测试提神食物建议"""
        response = client.get("/api/v1/workplace/quick-recovery")
        data = response.json()
        foods = data["data"]["rejuvenating_foods"]
        assert len(foods) >= 4
        assert all("food" in item for item in foods)
        assert all("effect" in item for item in foods)
        assert all("prep_time" in item for item in foods)


# ─────────────────────────────────────────────────────────────────────────────
# 加班养护方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestOvertimeCare:
    """加班养护方案测试"""

    def test_overtime_20_oclock(self):
        """测试20点加班方案"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=20_oclock")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["time_range"] == "20:00-22:00"
        assert "care_tips" in data["data"]
        assert "food_recommendations" in data["data"]
        assert "acupoint_care" in data["data"]
        assert len(data["data"]["care_tips"]) >= 4

    def test_overtime_22_oclock(self):
        """测试22点加班方案"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=22_oclock")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["time_range"] == "22:00-00:00"
        assert "tcm_organ" in data["data"]
        assert "key_point" in data["data"]

    def test_overtime_midnight_after(self):
        """测试午夜后加班方案"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=midnight_after")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["time_range"] == "00:00之后"
        assert "recovery_protocol" in data["data"]
        assert "recovery_days" in data["data"]["recovery_protocol"]

    def test_overtime_20_oclock_food(self):
        """测试20点加班食疗建议"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=20_oclock")
        data = response.json()
        foods = data["data"]["food_recommendations"]
        assert len(foods) >= 3
        assert all(isinstance(food, str) for food in foods)

    def test_overtime_22_oclock_food(self):
        """测试22点加班食疗建议"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=22_oclock")
        data = response.json()
        foods = data["data"]["food_recommendations"]
        assert len(foods) >= 3

    def test_overtime_midnight_after_protocol(self):
        """测试午夜后恢复方案详情"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=midnight_after")
        data = response.json()
        protocol = data["data"]["recovery_protocol"]
        assert "post_midnight_hours" in protocol
        assert "recovery_days" in protocol
        assert "key_actions" in protocol

    def test_overtime_invalid_segment(self):
        """测试无效的时段参数"""
        response = client.get("/api/v1/workplace/overtime-care?time_segment=invalid_time")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_overtime_default_segment(self):
        """测试默认时段（应为20_oclock）"""
        response = client.get("/api/v1/workplace/overtime-care")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["time_range"] == "20:00-22:00"


# ─────────────────────────────────────────────────────────────────────────────
# 工作阶段TCM建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestWorkPhases:
    """工作阶段TCM建议测试"""

    def test_work_phases_basic(self):
        """测试工作阶段基本信息"""
        response = client.get("/api/v1/workplace/work-phases")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        phases = data["data"]
        assert len(phases) >= 5

    def test_work_phases_all_phases(self):
        """测试所有工作阶段存在"""
        response = client.get("/api/v1/workplace/work-phases")
        data = response.json()
        phases = data["data"]
        phase_keys = [
            "pre_morning_meeting",
            "morning_focus",
            "afternoon_fatigue",
            "afternoon_sprint",
            "evening_closeout"
        ]
        for phase_key in phase_keys:
            assert phase_key in phases

    def test_work_phases_phase_structure(self):
        """测试单个阶段的完整性"""
        response = client.get("/api/v1/workplace/work-phases")
        data = response.json()
        phase = list(data["data"].values())[0]
        assert "phase" in phase
        assert "time_window" in phase
        assert "tcm_principle" in phase
        assert "recommendations" in phase
        assert "food_suggestions" in phase

    def test_work_phases_morning_phase(self):
        """测试早会前阶段"""
        response = client.get("/api/v1/workplace/work-phases")
        data = response.json()
        phase = data["data"]["pre_morning_meeting"]
        assert phase["phase"] == "早会前"
        assert "08:00-09:00" in phase["time_window"]

    def test_work_phases_afternoon_fatigue(self):
        """测试午后困倦期"""
        response = client.get("/api/v1/workplace/work-phases")
        data = response.json()
        phase = data["data"]["afternoon_fatigue"]
        assert phase["phase"] == "午后困倦期"
        assert "13:00-15:00" in phase["time_window"]
        assert len(phase["recommendations"]) >= 3

    def test_work_phases_evening_phase(self):
        """测试晚间收尾阶段"""
        response = client.get("/api/v1/workplace/work-phases")
        data = response.json()
        phase = data["data"]["evening_closeout"]
        assert phase["phase"] == "晚间收尾"
        assert "18:00-20:00" in phase["time_window"]


# ─────────────────────────────────────────────────────────────────────────────
# 症状缓解方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSymptomRelief:
    """症状缓解方案测试"""

    def test_symptom_relief_neck_shoulder(self):
        """测试颈肩疼缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "颈肩疼"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "颈肩疼"
        assert "tcm_cause" in data["data"]
        assert "quick_solutions" in data["data"]
        assert len(data["data"]["quick_solutions"]) >= 3

    def test_symptom_relief_eye_fatigue(self):
        """测试眼疲劳缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "眼疲劳"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "眼疲劳"
        assert len(data["data"]["quick_solutions"]) >= 3

    def test_symptom_relief_drowsiness(self):
        """测试困倦缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "困倦"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "困倦"
        solutions = data["data"]["quick_solutions"]
        assert len(solutions) >= 3

    def test_symptom_relief_stomach_pain(self):
        """测试胃痛缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "胃痛"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "胃痛"
        assert "quick_solutions" in data["data"]

    def test_symptom_relief_headache(self):
        """测试头痛缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "头痛"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "头痛"
        assert len(data["data"]["quick_solutions"]) >= 3

    def test_symptom_relief_anxiety(self):
        """测试焦虑缓解"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "焦虑"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "焦虑"
        assert len(data["data"]["quick_solutions"]) >= 3

    def test_symptom_relief_unknown_symptom(self):
        """测试未知症状"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "未知症状"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False
        assert "error" in data["data"]

    def test_symptom_relief_solution_structure(self):
        """测试单个解决方案的完整性"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": "颈肩疼"})
        data = response.json()
        solution = data["data"]["quick_solutions"][0]
        assert "name" in solution
        assert "time_minutes" in solution
        assert "steps" in solution
        assert "effect" in solution

    def test_symptom_relief_all_symptoms_supported(self):
        """测试所有6种症状都被支持"""
        symptoms = ["颈肩疼", "眼疲劳", "困倦", "胃痛", "头痛", "焦虑"]
        for symptom in symptoms:
            response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": symptom})
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_symptom_relief_empty_symptom(self):
        """测试空症状字段"""
        response = client.post("/api/v1/workplace/symptom-relief", json={"symptom": ""})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """综合功能测试"""

    def test_all_endpoints_success_response_format(self):
        """测试所有端点的成功响应格式一致"""
        endpoints = [
            ("/api/v1/workplace/desk-exercises?duration=5min", "GET"),
            ("/api/v1/workplace/eye-care", "GET"),
            ("/api/v1/workplace/quick-recovery", "GET"),
            ("/api/v1/workplace/overtime-care?time_segment=20_oclock", "GET"),
            ("/api/v1/workplace/work-phases", "GET"),
        ]

        for endpoint, method in endpoints:
            if method == "GET":
                response = client.get(endpoint)
            data = response.json()
            assert "success" in data
            assert "data" in data
            assert data["success"] is True

    def test_error_response_format(self):
        """测试错误响应格式一致"""
        response = client.get("/api/v1/workplace/desk-exercises?duration=invalid")
        data = response.json()
        assert "success" in data
        assert "data" in data
        assert data["success"] is False
        assert "error" in data["data"]

    def test_multiple_time_segments_coverage(self):
        """测试加班时段的全覆盖"""
        time_segments = ["20_oclock", "22_oclock", "midnight_after"]
        for segment in time_segments:
            response = client.get(f"/api/v1/workplace/overtime-care?time_segment={segment}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_exercise_durations_coverage(self):
        """测试动作时长的全覆盖"""
        durations = ["5min", "10min", "20min"]
        for duration in durations:
            response = client.get(f"/api/v1/workplace/desk-exercises?duration={duration}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["data"]["duration_minutes"] == int(duration.rstrip("min"))
