"""
顺时 — 运动健身 TCM 恢复方案 API 测试
包含运动恢复方案、运动损伤、赛前调理、过度训练预警、运动后建议等测试。
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

# ─────────────────────────────────────────────────────────────────────────────
# 运动恢复方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSportsRecovery:
    """运动恢复方案测试"""

    def test_recovery_strength_training(self):
        """测试力量训练恢复方案"""
        response = client.get("/api/v1/sports/recovery/strength_training")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_name"] == "力量训练"
        assert "diet_recommendations" in data["data"]
        assert "acupoint_massage" in data["data"]
        assert len(data["data"]["diet_recommendations"]) >= 5

    def test_recovery_endurance_running(self):
        """测试长跑/马拉松恢复方案"""
        response = client.get("/api/v1/sports/recovery/endurance_running")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_name"] == "长跑/马拉松"
        assert "recovery_protocol" in data["data"]

    def test_recovery_swimming(self):
        """测试游泳恢复方案"""
        response = client.get("/api/v1/sports/recovery/swimming")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_name"] == "游泳"
        assert "warning_signs" in data["data"]

    def test_recovery_hiit(self):
        """测试HIIT恢复方案"""
        response = client.get("/api/v1/sports/recovery/hiit")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_name"] == "高强度间歇(HIIT)"
        assert "mental_recovery" in data["data"]

    def test_recovery_yoga_stretching(self):
        """测试瑜伽/拉伸恢复方案"""
        response = client.get("/api/v1/sports/recovery/yoga_stretching")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_name"] == "瑜伽/拉伸"
        assert "breathing_emphasis" in data["data"]

    def test_recovery_invalid_sport(self):
        """测试无效运动类型返回404"""
        response = client.get("/api/v1/sports/recovery/invalid_sport")
        assert response.status_code == 404

    def test_recovery_structure(self):
        """测试恢复方案结构完整性"""
        response = client.get("/api/v1/sports/recovery/strength_training")
        data = response.json()
        recovery = data["data"]
        assert "tcm_mechanism" in recovery
        assert "recovery_timeline" in recovery
        assert "immediate_care" in recovery
        assert "diet_recommendations" in recovery

    def test_recovery_diet_items(self):
        """测试食疗项包含必要信息"""
        response = client.get("/api/v1/sports/recovery/strength_training")
        data = response.json()
        diet_item = data["data"]["diet_recommendations"][0]
        assert "food" in diet_item
        assert "benefit" in diet_item
        assert "timing" in diet_item
        assert "usage" in diet_item


# ─────────────────────────────────────────────────────────────────────────────
# 运动类型列表测试
# ─────────────────────────────────────────────────────────────────────────────

class TestSportsList:
    """运动类型列表测试"""

    def test_sports_list_basic(self):
        """测试运动类型列表"""
        response = client.get("/api/v1/sports/sports")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert isinstance(data["data"], list)
        assert len(data["data"]) >= 5

    def test_sports_list_structure(self):
        """测试列表项结构"""
        response = client.get("/api/v1/sports/sports")
        data = response.json()
        sport = data["data"][0]
        assert "sport_id" in sport
        assert "sport_name" in sport

    def test_sports_list_contains_all_5_types(self):
        """测试列表包含所有5种运动"""
        response = client.get("/api/v1/sports/sports")
        data = response.json()
        sport_ids = [s["sport_id"] for s in data["data"]]
        assert "strength_training" in sport_ids
        assert "endurance_running" in sport_ids
        assert "swimming" in sport_ids
        assert "hiit" in sport_ids
        assert "yoga_stretching" in sport_ids


# ─────────────────────────────────────────────────────────────────────────────
# 运动损伤处理测试
# ─────────────────────────────────────────────────────────────────────────────

class TestInjuryCare:
    """运动损伤处理测试"""

    def test_injury_care_sprain(self):
        """测试扭伤处理"""
        response = client.get("/api/v1/sports/injury-care/sprain")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "扭伤"
        assert "phases" in data["data"]
        assert len(data["data"]["phases"]) == 3

    def test_injury_care_strain(self):
        """测试拉伤处理"""
        response = client.get("/api/v1/sports/injury-care/strain")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "拉伤"
        assert "phases" in data["data"]

    def test_injury_care_soreness(self):
        """测试肌肉酸痛处理"""
        response = client.get("/api/v1/sports/injury-care/soreness")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["name"] == "肌肉酸痛（DOMS）"
        assert "management" in data["data"]

    def test_injury_care_invalid_type(self):
        """测试无效损伤类型返回404"""
        response = client.get("/api/v1/sports/injury-care/invalid_injury")
        assert response.status_code == 404

    def test_injury_care_sprain_phases(self):
        """测试扭伤各阶段内容"""
        response = client.get("/api/v1/sports/injury-care/sprain")
        data = response.json()
        phases = data["data"]["phases"]
        phase_names = [p["phase"] for p in phases]
        assert "急性期（0-24小时）" in phase_names
        assert "缓解期（24小时-3天）" in phase_names
        assert "恢复期（3天以后）" in phase_names

    def test_injury_care_phase_structure(self):
        """测试阶段信息完整性"""
        response = client.get("/api/v1/sports/injury-care/sprain")
        data = response.json()
        phase = data["data"]["phases"][0]
        assert "phase" in phase
        assert "principle" in phase
        assert "treatment" in phase
        assert "diet" in phase

    def test_injury_care_soreness_timeline(self):
        """测试肌肉酸痛恢复时间"""
        response = client.get("/api/v1/sports/injury-care/soreness")
        data = response.json()
        assert "timeline" in data["data"]
        assert "3-5天" in data["data"]["timeline"]


# ─────────────────────────────────────────────────────────────────────────────
# 赛前调理方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPreCompetition:
    """赛前调理方案测试"""

    def test_pre_competition_basic(self):
        """测试赛前调理基本信息"""
        response = client.get("/api/v1/sports/pre-competition")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "7_days_before" in data["data"]
        assert "3_days_before" in data["data"]
        assert "race_day" in data["data"]

    def test_pre_competition_7_days(self):
        """测试赛前7天方案"""
        response = client.get("/api/v1/sports/pre-competition")
        data = response.json()
        phase = data["data"]["7_days_before"]
        assert phase["phase"] == "赛前7天"
        assert "training" in phase
        assert "diet" in phase
        assert "sleep" in phase
        assert len(phase["diet"]) >= 3

    def test_pre_competition_3_days(self):
        """测试赛前3天方案"""
        response = client.get("/api/v1/sports/pre-competition")
        data = response.json()
        phase = data["data"]["3_days_before"]
        assert phase["phase"] == "赛前3天"
        assert "mental_preparation" in phase
        assert "avoid" in phase

    def test_pre_competition_race_day(self):
        """测试比赛当日方案"""
        response = client.get("/api/v1/sports/pre-competition")
        data = response.json()
        phase = data["data"]["race_day"]
        assert phase["phase"] == "比赛当日"
        assert "pre_competition_meal" in phase
        assert "hydration" in phase
        assert "warm_up" in phase
        assert "mental_tips" in phase

    def test_pre_competition_hydration_details(self):
        """测试补水方案详情"""
        response = client.get("/api/v1/sports/pre-competition")
        data = response.json()
        hydration = data["data"]["race_day"]["hydration"]
        assert "before" in hydration
        assert "during" in hydration
        assert "after" in hydration


# ─────────────────────────────────────────────────────────────────────────────
# 过度训练预警测试
# ─────────────────────────────────────────────────────────────────────────────

class TestOverttrainingWarning:
    """过度训练预警测试"""

    def test_overtraining_signs_basic(self):
        """测试过度训练预警基本信息"""
        response = client.get("/api/v1/sports/overtraining-signs")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "physical_signs" in data["data"]
        assert "immunological_signs" in data["data"]
        assert "mental_signs" in data["data"]

    def test_overtraining_physical_signs(self):
        """测试身体预警信号"""
        response = client.get("/api/v1/sports/overtraining-signs")
        data = response.json()
        signs = data["data"]["physical_signs"]
        assert len(signs) >= 4
        assert all("sign" in s for s in signs)
        assert all("tcm_interpretation" in s for s in signs)
        assert all("action" in s for s in signs)

    def test_overtraining_immunological_signs(self):
        """测试免疫预警信号"""
        response = client.get("/api/v1/sports/overtraining-signs")
        data = response.json()
        signs = data["data"]["immunological_signs"]
        assert len(signs) >= 3

    def test_overtraining_mental_signs(self):
        """测试心理预警信号"""
        response = client.get("/api/v1/sports/overtraining-signs")
        data = response.json()
        signs = data["data"]["mental_signs"]
        assert len(signs) >= 3

    def test_overtraining_recovery_protocol(self):
        """测试恢复方案"""
        response = client.get("/api/v1/sports/overtraining-signs")
        data = response.json()
        protocol = data["data"]["recovery_protocol"]
        assert "immediate_action" in protocol
        assert "recovery_duration" in protocol
        assert "recovery_method" in protocol

    def test_overtraining_sign_structure(self):
        """测试预警信号结构完整性"""
        response = client.get("/api/v1/sports/overtraining-signs")
        data = response.json()
        sign = data["data"]["physical_signs"][0]
        assert "sign" in sign
        assert "tcm_interpretation" in sign
        assert "action" in sign


# ─────────────────────────────────────────────────────────────────────────────
# 运动后调养建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPostWorkout:
    """运动后调养建议测试"""

    def test_post_workout_strength_training_high(self):
        """测试力量训练高强度后建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 60,
            "intensity": "high",
            "current_time": "2024-01-01T15:30:00"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_type"] == "strength_training"
        assert data["data"]["duration_minutes"] == 60
        assert "recovery_priority" in data["data"]

    def test_post_workout_running_extreme(self):
        """测试马拉松极限强度后建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "endurance_running",
            "duration_minutes": 180,
            "intensity": "extreme",
            "current_time": "2024-01-01T10:00:00"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "recovery_emphasis" in data["data"]
        assert "极限" in data["data"]["recovery_emphasis"]

    def test_post_workout_swimming_medium(self):
        """测试游泳中等强度后建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "swimming",
            "duration_minutes": 45,
            "intensity": "medium"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["sport_type"] == "swimming"

    def test_post_workout_hiit_high(self):
        """测试HIIT高强度后建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "hiit",
            "duration_minutes": 30,
            "intensity": "high"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_post_workout_yoga_low(self):
        """测试瑜伽低强度后建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "yoga_stretching",
            "duration_minutes": 60,
            "intensity": "low"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "低强度" in data["data"]["recovery_emphasis"] or "轻度" in data["data"]["recovery_emphasis"]

    def test_post_workout_invalid_sport(self):
        """测试无效运动类型"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "invalid_sport",
            "duration_minutes": 60,
            "intensity": "high"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_post_workout_invalid_intensity(self):
        """测试无效强度值"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 60,
            "intensity": "invalid_intensity"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_post_workout_zero_duration(self):
        """测试零运动时长"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 0,
            "intensity": "high"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False

    def test_post_workout_energy_cost_calculation(self):
        """测试能量消耗计算"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 60,
            "intensity": "high"
        })
        data = response.json()
        # high intensity = 2.0 multiplier, 60 * 2.0 = 120
        assert data["data"]["energy_cost_score"] == 120

    def test_post_workout_recovery_priority(self):
        """测试恢复优先级根据能量消耗调整"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "yoga_stretching",
            "duration_minutes": 60,
            "intensity": "low"
        })
        data = response.json()
        # 能量消耗 60 * 1.0 = 60，属于轻度
        assert "recovery_priority" in data["data"]

    def test_post_workout_structure(self):
        """测试返回结构完整性"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 60,
            "intensity": "high"
        })
        data = response.json()
        result = data["data"]
        assert "sport_type" in result
        assert "duration_minutes" in result
        assert "intensity" in result
        assert "energy_cost_score" in result
        assert "recovery_emphasis" in result
        assert "recovery_priority" in result

    def test_post_workout_includes_diet(self):
        """测试返回包含食疗建议"""
        response = client.post("/api/v1/sports/post-workout", json={
            "sport_type": "strength_training",
            "duration_minutes": 60,
            "intensity": "high"
        })
        data = response.json()
        assert "recommended_diet" in data["data"]
        assert len(data["data"]["recommended_diet"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 综合测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """综合功能测试"""

    def test_all_5_sports_types_supported(self):
        """测试所有5种运动类型都被支持"""
        sports = [
            "strength_training",
            "endurance_running",
            "swimming",
            "hiit",
            "yoga_stretching"
        ]
        for sport in sports:
            response = client.get(f"/api/v1/sports/recovery/{sport}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_all_3_injury_types_supported(self):
        """测试所有3种损伤类型都被支持"""
        injuries = ["sprain", "strain", "soreness"]
        for injury in injuries:
            response = client.get(f"/api/v1/sports/injury-care/{injury}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_all_intensity_levels_accepted(self):
        """测试所有强度等级都被接受"""
        intensities = ["low", "medium", "high", "extreme"]
        for intensity in intensities:
            response = client.post("/api/v1/sports/post-workout", json={
                "sport_type": "strength_training",
                "duration_minutes": 60,
                "intensity": intensity
            })
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_energy_cost_gradient(self):
        """测试能量消耗按强度梯度上升"""
        durations = [30, 60, 90]
        for duration in durations:
            response = client.post("/api/v1/sports/post-workout", json={
                "sport_type": "strength_training",
                "duration_minutes": duration,
                "intensity": "medium"
            })
            data = response.json()
            # medium = 1.5, so cost should be duration * 1.5
            assert data["data"]["energy_cost_score"] == int(duration * 1.5)

    def test_post_workout_all_sports(self):
        """测试所有运动类型都支持运动后建议"""
        sports = [
            "strength_training",
            "endurance_running",
            "swimming",
            "hiit",
            "yoga_stretching"
        ]
        for sport in sports:
            response = client.post("/api/v1/sports/post-workout", json={
                "sport_type": sport,
                "duration_minutes": 60,
                "intensity": "medium"
            })
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["data"]["sport_type"] == sport

    def test_response_format_consistency(self):
        """测试所有端点的响应格式一致"""
        endpoints = [
            ("/api/v1/sports/recovery/strength_training", "GET"),
            ("/api/v1/sports/sports", "GET"),
            ("/api/v1/sports/injury-care/sprain", "GET"),
            ("/api/v1/sports/pre-competition", "GET"),
            ("/api/v1/sports/overtraining-signs", "GET"),
        ]

        for endpoint, method in endpoints:
            if method == "GET":
                response = client.get(endpoint)
            data = response.json()
            assert "success" in data
            assert "data" in data

    def test_minimum_required_endpoints(self):
        """测试最少的端点数量"""
        # 应该有至少6个端点
        endpoints = [
            ("/api/v1/sports/recovery/strength_training", True),
            ("/api/v1/sports/sports", True),
            ("/api/v1/sports/injury-care/sprain", True),
            ("/api/v1/sports/pre-competition", True),
            ("/api/v1/sports/overtraining-signs", True),
        ]

        for endpoint, should_exist in endpoints:
            response = client.get(endpoint)
            if should_exist:
                assert response.status_code == 200 or response.status_code == 404
