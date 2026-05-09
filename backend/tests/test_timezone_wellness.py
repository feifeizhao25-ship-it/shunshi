"""
时区感知的昼夜节律养生系统 - 单元测试
覆盖时辰映射、时差计算、个性化作息生成及无效参数处理。
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime


# 假设 FastAPI app 已正确导入
from app.main import app

client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 当前时辰端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestCurrentShichen:
    """GET /api/v1/timezone/current-shichen 端点测试"""

    def test_current_shichen_default_tz(self):
        """获取当前时辰（默认时区 +8）"""
        response = client.get("/api/v1/timezone/current-shichen")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "shichen" in data["data"]
        assert "shichen_name" in data["data"]
        assert "organ" in data["data"]
        assert "optimal_activity" in data["data"]
        assert "avoid" in data["data"]

    def test_current_shichen_custom_tz_plus_8(self):
        """获取当前时辰（时区 +8）"""
        response = client.get("/api/v1/timezone/current-shichen?timezone_offset=+8")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["timezone_offset"] == "+8"

    def test_current_shichen_custom_tz_minus_5(self):
        """获取当前时辰（时区 -5）"""
        response = client.get("/api/v1/timezone/current-shichen?timezone_offset=-5")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_current_shichen_invalid_tz(self):
        """无效时区格式返回 422"""
        response = client.get("/api/v1/timezone/current-shichen?timezone_offset=invalid")
        assert response.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# 指定时辰端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestShichenByHour:
    """GET /api/v1/timezone/shichen/{hour} 端点测试"""

    def test_shichen_hour_0_midnight(self):
        """小时 0（子时）"""
        response = client.get("/api/v1/timezone/shichen/0")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["shichen"] == "子"
        assert data["data"]["name"] == "子时"
        assert data["data"]["organ"] == "胆"

    def test_shichen_hour_1_chou(self):
        """小时 1（丑时）"""
        response = client.get("/api/v1/timezone/shichen/1")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "丑"
        assert data["data"]["organ"] == "肝"

    def test_shichen_hour_3_yin(self):
        """小时 3（寅时）"""
        response = client.get("/api/v1/timezone/shichen/3")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "寅"
        assert data["data"]["organ"] == "肺"

    def test_shichen_hour_5_mao(self):
        """小时 5（卯时）"""
        response = client.get("/api/v1/timezone/shichen/5")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "卯"
        assert data["data"]["organ"] == "大肠"

    def test_shichen_hour_7_chen(self):
        """小时 7（辰时）"""
        response = client.get("/api/v1/timezone/shichen/7")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "辰"
        assert data["data"]["organ"] == "胃"

    def test_shichen_hour_9_si(self):
        """小时 9（巳时）"""
        response = client.get("/api/v1/timezone/shichen/9")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "巳"
        assert data["data"]["organ"] == "脾"

    def test_shichen_hour_11_wu(self):
        """小时 11（午时）"""
        response = client.get("/api/v1/timezone/shichen/11")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "午"
        assert data["data"]["organ"] == "心"

    def test_shichen_hour_13_wei(self):
        """小时 13（未时）"""
        response = client.get("/api/v1/timezone/shichen/13")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "未"
        assert data["data"]["organ"] == "小肠"

    def test_shichen_hour_15_shen(self):
        """小时 15（申时）"""
        response = client.get("/api/v1/timezone/shichen/15")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "申"
        assert data["data"]["organ"] == "膀胱"

    def test_shichen_hour_17_you(self):
        """小时 17（酉时）"""
        response = client.get("/api/v1/timezone/shichen/17")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "酉"
        assert data["data"]["organ"] == "肾"

    def test_shichen_hour_19_xu(self):
        """小时 19（戌时）"""
        response = client.get("/api/v1/timezone/shichen/19")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "戌"
        assert data["data"]["organ"] == "心包"

    def test_shichen_hour_21_hai(self):
        """小时 21（亥时）"""
        response = client.get("/api/v1/timezone/shichen/21")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "亥"
        assert data["data"]["organ"] == "三焦"

    def test_shichen_hour_23_late_zi(self):
        """小时 23（晚子时）"""
        response = client.get("/api/v1/timezone/shichen/23")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["shichen"] == "子"

    def test_shichen_hour_invalid_negative(self):
        """无效小时数 -1 返回 422"""
        response = client.get("/api/v1/timezone/shichen/-1")
        assert response.status_code == 422

    def test_shichen_hour_invalid_over_23(self):
        """无效小时数 24 返回 422"""
        response = client.get("/api/v1/timezone/shichen/24")
        assert response.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# 每日作息建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestDailySchedule:
    """GET /api/v1/timezone/daily-schedule 端点测试"""

    def test_daily_schedule_default(self):
        """获取完整一日作息建议"""
        response = client.get("/api/v1/timezone/daily-schedule")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]["schedule"]) == 24
        assert "十二时辰" in data["data"]["summary"]

    def test_daily_schedule_with_tz(self):
        """获取特定时区的一日作息建议"""
        response = client.get("/api/v1/timezone/daily-schedule?timezone_offset=+8")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]["schedule"]) == 24

    def test_daily_schedule_content_completeness(self):
        """验证每个时辰都有完整信息"""
        response = client.get("/api/v1/timezone/daily-schedule")
        data = response.json()
        for hour_data in data["data"]["schedule"]:
            assert "hour" in hour_data
            assert "shichen" in hour_data
            assert "organ" in hour_data
            assert "optimal_activity" in hour_data
            assert "avoid" in hour_data

    def test_daily_schedule_midnight_content(self):
        """验证午夜时辰（子时）的内容"""
        response = client.get("/api/v1/timezone/daily-schedule")
        data = response.json()
        zi_shichen = [h for h in data["data"]["schedule"] if h["hour"] == 0][0]
        assert zi_shichen["shichen"] == "子"
        assert zi_shichen["organ"] == "胆"


# ─────────────────────────────────────────────────────────────────────────────
# 时差调节方案测试
# ─────────────────────────────────────────────────────────────────────────────

class TestJetLagRecovery:
    """GET /api/v1/timezone/jet-lag 端点测试"""

    def test_jet_lag_light_2hours(self):
        """轻度时差：2 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC+6")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["time_difference_hours"] == 2
        assert "轻度时差" in data["data"]["severity"]
        assert data["data"]["estimated_recovery_days"] == 1

    def test_jet_lag_light_3hours(self):
        """轻度时差：3 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC+5")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["time_difference_hours"] == 3
        assert data["data"]["estimated_recovery_days"] == 1

    def test_jet_lag_moderate_5hours(self):
        """中度时差：5 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC+3")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["time_difference_hours"] == 5
        assert "中度时差" in data["data"]["severity"]
        assert data["data"]["estimated_recovery_days"] == 2

    def test_jet_lag_moderate_6hours(self):
        """中度时差：6 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC+2")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["time_difference_hours"] == 6
        assert data["data"]["estimated_recovery_days"] == 2

    def test_jet_lag_severe_8hours(self):
        """重度时差：8 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["time_difference_hours"] == 8
        assert "重度时差" in data["data"]["severity"]
        assert data["data"]["estimated_recovery_days"] == 3

    def test_jet_lag_severe_12hours(self):
        """重度时差：12 小时"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC-4")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["time_difference_hours"] == 12
        assert data["data"]["estimated_recovery_days"] == 3

    def test_jet_lag_direction_east(self):
        """向东飞行判定"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC-5&to_tz=UTC+8")
        assert response.status_code == 200
        data = response.json()
        assert "向东" in data["data"]["direction"]

    def test_jet_lag_direction_west(self):
        """向西飞行判定"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC-5")
        assert response.status_code == 200
        data = response.json()
        assert "向西" in data["data"]["direction"]

    def test_jet_lag_measures_provided(self):
        """验证调整措施已提供"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC-5")
        data = response.json()
        assert "adjustment_measures" in data["data"]
        assert len(data["data"]["adjustment_measures"]) > 0

    def test_jet_lag_invalid_from_tz(self):
        """无效的出发地时区"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=invalid&to_tz=UTC+8")
        assert response.status_code == 422

    def test_jet_lag_invalid_to_tz(self):
        """无效的目的地时区"""
        response = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=invalid")
        assert response.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# 最佳活动时辰测试
# ─────────────────────────────────────────────────────────────────────────────

class TestOptimalActivityTime:
    """GET /api/v1/timezone/optimal-activity/{activity} 端点测试"""

    def test_optimal_activity_sleep(self):
        """睡眠的最佳时辰"""
        response = client.get("/api/v1/timezone/optimal-activity/sleep")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "亥" in data["data"]["best_shichen"]
        assert 21 in data["data"]["best_hours"] or 22 in data["data"]["best_hours"]

    def test_optimal_activity_exercise(self):
        """运动的最佳时辰"""
        response = client.get("/api/v1/timezone/optimal-activity/exercise")
        assert response.status_code == 200
        data = response.json()
        assert "申" in data["data"]["best_shichen"]
        assert 15 in data["data"]["best_hours"] or 16 in data["data"]["best_hours"]

    def test_optimal_activity_meditation(self):
        """冥想的最佳时辰"""
        response = client.get("/api/v1/timezone/optimal-activity/meditation")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]["best_shichen"]) > 0

    def test_optimal_activity_eating(self):
        """进食的最佳时辰"""
        response = client.get("/api/v1/timezone/optimal-activity/eating")
        assert response.status_code == 200
        data = response.json()
        assert "辰" in data["data"]["best_shichen"]
        assert 7 in data["data"]["best_hours"] or 8 in data["data"]["best_hours"]

    def test_optimal_activity_work(self):
        """工作的最佳时辰"""
        response = client.get("/api/v1/timezone/optimal-activity/work")
        assert response.status_code == 200
        data = response.json()
        assert "巳" in data["data"]["best_shichen"]

    def test_optimal_activity_invalid(self):
        """无效活动类型返回 404"""
        response = client.get("/api/v1/timezone/optimal-activity/invalid_activity")
        assert response.status_code == 404

    def test_optimal_activity_case_insensitive(self):
        """活动名称大小写不敏感"""
        response = client.get("/api/v1/timezone/optimal-activity/SLEEP")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


# ─────────────────────────────────────────────────────────────────────────────
# 个性化作息建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestPersonalizedSchedule:
    """POST /api/v1/timezone/personalized-schedule 端点测试"""

    def test_personalized_schedule_basic(self):
        """基础个性化作息"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
            "timezone_offset": "+8",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["wake_time"] == "07:00"
        assert data["data"]["sleep_target"] == "23:00"

    def test_personalized_schedule_with_constitution(self):
        """包含体质类型的个性化作息"""
        payload = {
            "wake_time": "06:00",
            "sleep_target": "22:00",
            "timezone_offset": "+8",
            "constitution_type": "qi_deficiency",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "气虚体质" in data["data"]["constitution_advice"]

    def test_personalized_schedule_yin_deficiency(self):
        """阴虚体质的个性化作息"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
            "constitution_type": "yin_deficiency",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "阴虚体质" in data["data"]["constitution_advice"]

    def test_personalized_schedule_damp_heat(self):
        """湿热体质的个性化作息"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
            "constitution_type": "damp_heat",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "湿热体质" in data["data"]["constitution_advice"]

    def test_personalized_schedule_schedule_length(self):
        """验证个性化作息表的完整性"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        data = response.json()
        assert len(data["data"]["personalized_schedule"]) >= 6

    def test_personalized_schedule_contains_key_activities(self):
        """验证作息表包含关键活动"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        data = response.json()
        activities = [item["activity"] for item in data["data"]["personalized_schedule"]]
        assert "起床" in activities
        assert "早餐" in activities
        assert "午餐" in activities
        assert "运动锻炼" in activities

    def test_personalized_schedule_invalid_wake_time(self):
        """无效的起床时间格式"""
        payload = {
            "wake_time": "25:00",
            "sleep_target": "23:00",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 422

    def test_personalized_schedule_invalid_sleep_time(self):
        """无效的睡眠时间格式"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "99:99",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 422

    def test_personalized_schedule_invalid_tz(self):
        """无效的时区格式"""
        payload = {
            "wake_time": "07:00",
            "sleep_target": "23:00",
            "timezone_offset": "invalid",
        }
        response = client.post("/api/v1/timezone/personalized-schedule", json=payload)
        assert response.status_code == 422


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """端点间的集成测试"""

    def test_shichen_info_consistency(self):
        """验证不同端点返回的时辰信息一致"""
        # 从 current-shichen 获取信息
        current = client.get("/api/v1/timezone/current-shichen?timezone_offset=+8")
        current_hour = current.json()["data"]["hour"]

        # 从 shichen/{hour} 获取相同小时的信息
        specific = client.get(f"/api/v1/timezone/shichen/{current_hour}")

        # 验证器官和活动建议一致
        assert current.json()["data"]["organ"] == specific.json()["data"]["organ"]

    def test_optimal_activity_consistency(self):
        """验证最佳活动时辰与每日作息一致"""
        optimal_sleep = client.get("/api/v1/timezone/optimal-activity/sleep")
        daily_schedule = client.get("/api/v1/timezone/daily-schedule")

        optimal_hours = optimal_sleep.json()["data"]["best_hours"]
        schedule_data = daily_schedule.json()["data"]["schedule"]

        # 验证至少有一个最佳睡眠时段在每日作息中有对应数据
        for hour in optimal_hours[:3]:
            schedule_hour = [h for h in schedule_data if h["hour"] == hour]
            assert len(schedule_hour) > 0

    def test_jet_lag_and_schedule_flow(self):
        """时差 → 个性化作息建议的完整流程"""
        # 1. 获取时差恢复方案
        jet_lag = client.get("/api/v1/timezone/jet-lag?from_tz=UTC+8&to_tz=UTC-5")
        assert jet_lag.status_code == 200

        # 2. 根据时差信息生成个性化作息
        schedule = client.post("/api/v1/timezone/personalized-schedule", json={
            "wake_time": "07:00",
            "sleep_target": "23:00",
            "timezone_offset": "-5",
        })
        assert schedule.status_code == 200
        assert schedule.json()["success"] is True
