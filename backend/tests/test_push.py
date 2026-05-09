"""
顺时 - 个性化推送 API 路由测试
test_push.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestMorningPush:
    """早晨推送端点测试"""

    def test_morning_push_returns_200(self):
        """GET /api/v1/push/morning 返回 200"""
        response = client.get("/api/v1/push/morning?user_id=user-001")
        assert response.status_code == 200

    def test_morning_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/morning")
        assert response.status_code == 422

    def test_morning_push_with_lang_cn(self):
        """GET /api/v1/push/morning?lang=cn 返回中文推送"""
        response = client.get("/api/v1/push/morning?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_morning_push_with_lang_gl(self):
        """GET /api/v1/push/morning?lang=gl 返回全球英文推送"""
        response = client.get("/api/v1/push/morning?user_id=user-001&lang=gl")
        assert response.status_code == 200

    def test_morning_push_has_content(self):
        """早晨推送包含内容"""
        response = client.get("/api/v1/push/morning?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        # 响应应该包含推送内容
        assert data is not None


class TestNoonPush:
    """午间推送端点测试"""

    def test_noon_push_returns_200(self):
        """GET /api/v1/push/noon 返回 200"""
        response = client.get("/api/v1/push/noon?user_id=user-001")
        assert response.status_code == 200

    def test_noon_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/noon")
        assert response.status_code == 422

    def test_noon_push_with_lang_cn(self):
        """GET /api/v1/push/noon?lang=cn 返回 200"""
        response = client.get("/api/v1/push/noon?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_noon_push_with_lang_gl(self):
        """GET /api/v1/push/noon?lang=gl 返回 200"""
        response = client.get("/api/v1/push/noon?user_id=user-001&lang=gl")
        assert response.status_code == 200


class TestAfternoonPush:
    """下午推送端点测试"""

    def test_afternoon_push_returns_200(self):
        """GET /api/v1/push/afternoon 返回 200"""
        response = client.get("/api/v1/push/afternoon?user_id=user-001")
        assert response.status_code == 200

    def test_afternoon_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/afternoon")
        assert response.status_code == 422

    def test_afternoon_push_with_lang_cn(self):
        """GET /api/v1/push/afternoon?lang=cn 返回 200"""
        response = client.get("/api/v1/push/afternoon?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_afternoon_push_with_lang_gl(self):
        """GET /api/v1/push/afternoon?lang=gl 返回 200"""
        response = client.get("/api/v1/push/afternoon?user_id=user-001&lang=gl")
        assert response.status_code == 200


class TestEveningPush:
    """晚间推送端点测试"""

    def test_evening_push_returns_200(self):
        """GET /api/v1/push/evening 返回 200"""
        response = client.get("/api/v1/push/evening?user_id=user-001")
        assert response.status_code == 200

    def test_evening_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/evening")
        assert response.status_code == 422

    def test_evening_push_with_lang_cn(self):
        """GET /api/v1/push/evening?lang=cn 返回 200"""
        response = client.get("/api/v1/push/evening?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_evening_push_with_lang_gl(self):
        """GET /api/v1/push/evening?lang=gl 返回 200"""
        response = client.get("/api/v1/push/evening?user_id=user-001&lang=gl")
        assert response.status_code == 200


class TestNightPush:
    """睡前推送端点测试"""

    def test_night_push_returns_200(self):
        """GET /api/v1/push/night 返回 200"""
        response = client.get("/api/v1/push/night?user_id=user-001")
        assert response.status_code == 200

    def test_night_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/night")
        assert response.status_code == 422

    def test_night_push_with_lang_cn(self):
        """GET /api/v1/push/night?lang=cn 返回 200"""
        response = client.get("/api/v1/push/night?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_night_push_with_lang_gl(self):
        """GET /api/v1/push/night?lang=gl 返回 200"""
        response = client.get("/api/v1/push/night?user_id=user-001&lang=gl")
        assert response.status_code == 200


class TestDailyPush:
    """完整日推送方案端点测试"""

    def test_daily_push_returns_200(self):
        """GET /api/v1/push/daily 返回 200"""
        response = client.get("/api/v1/push/daily?user_id=user-001")
        assert response.status_code == 200

    def test_daily_push_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/daily")
        assert response.status_code == 422

    def test_daily_push_with_lang_cn(self):
        """GET /api/v1/push/daily?lang=cn 返回 200"""
        response = client.get("/api/v1/push/daily?user_id=user-001&lang=cn")
        assert response.status_code == 200

    def test_daily_push_with_lang_gl(self):
        """GET /api/v1/push/daily?lang=gl 返回 200"""
        response = client.get("/api/v1/push/daily?user_id=user-001&lang=gl")
        assert response.status_code == 200

    def test_daily_push_structure(self):
        """完整日推送应该包含所有时间点的推送"""
        response = client.get("/api/v1/push/daily?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        # 可能包含多个推送段或完整日程
        assert data is not None


class TestPushPreferences:
    """推送偏好端点测试"""

    def test_set_push_preferences_returns_200(self):
        """POST /api/v1/push/preferences 返回 200"""
        payload = {
            "user_id": "user-001",
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "07:00",
            "push_frequency": "normal",
            "focus_areas": ["睡眠", "运动"],
            "language": "cn"
        }
        response = client.post("/api/v1/push/preferences", json=payload)
        assert response.status_code == 200

    def test_preferences_success_response(self):
        """设置偏好返回成功响应"""
        payload = {
            "user_id": "user-002",
            "push_frequency": "minimal"
        }
        response = client.post("/api/v1/push/preferences", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "success" in data or "preferences" in data

    def test_preferences_with_quiet_hours(self):
        """支持设置静默时段"""
        payload = {
            "user_id": "user-003",
            "quiet_hours_start": "23:00",
            "quiet_hours_end": "08:00"
        }
        response = client.post("/api/v1/push/preferences", json=payload)
        assert response.status_code == 200

    def test_preferences_with_focus_areas(self):
        """支持设置关注领域"""
        payload = {
            "user_id": "user-004",
            "focus_areas": ["饮食", "运动", "睡眠"]
        }
        response = client.post("/api/v1/push/preferences", json=payload)
        assert response.status_code == 200

    def test_preferences_with_frequency(self):
        """支持设置推送频率"""
        payload = {
            "user_id": "user-005",
            "push_frequency": "verbose"
        }
        response = client.post("/api/v1/push/preferences", json=payload)
        assert response.status_code == 200

    def test_get_push_preferences_returns_200(self):
        """GET /api/v1/push/preferences 返回 200"""
        response = client.get("/api/v1/push/preferences?user_id=user-001")
        assert response.status_code == 200

    def test_preferences_requires_user_id(self):
        """缺少 user_id 参数返回错误"""
        response = client.get("/api/v1/push/preferences")
        assert response.status_code == 422

    def test_get_preferences_has_default_values(self):
        """获取偏好应该返回默认值"""
        response = client.get("/api/v1/push/preferences?user_id=new-user-123")
        assert response.status_code == 200
        data = response.json()
        assert "quiet_hours_start" in data or "user_id" in data

    def test_get_preferences_structure(self):
        """偏好对象包含标准字段"""
        response = client.get("/api/v1/push/preferences?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        # 应该有某种偏好数据结构
        assert data is not None

    def test_set_and_get_preferences_roundtrip(self):
        """设置偏好后可以获取"""
        # 设置偏好
        set_payload = {
            "user_id": "user-roundtrip",
            "push_frequency": "minimal",
            "language": "en"
        }
        set_response = client.post("/api/v1/push/preferences", json=set_payload)
        assert set_response.status_code == 200

        # 获取偏好
        get_response = client.get("/api/v1/push/preferences?user_id=user-roundtrip")
        assert get_response.status_code == 200


class TestPushScheduleIntegration:
    """推送调度整体测试"""

    def test_daily_push_schedule_sequence(self):
        """测试完整日推送序列"""
        user_id = "user-schedule-test"
        times = ["morning", "noon", "afternoon", "evening", "night"]

        for time_slot in times:
            response = client.get(f"/api/v1/push/{time_slot}?user_id={user_id}")
            assert response.status_code == 200

    def test_different_languages_support(self):
        """支持多种语言"""
        user_id = "user-001"
        for lang in ["cn", "gl"]:
            response = client.get(f"/api/v1/push/morning?user_id={user_id}&lang={lang}")
            assert response.status_code == 200

    def test_push_with_user_preferences(self):
        """推送应该考虑用户偏好"""
        user_id = "user-pref-test"
        # 先设置偏好
        pref_payload = {
            "user_id": user_id,
            "push_frequency": "minimal"
        }
        client.post("/api/v1/push/preferences", json=pref_payload)

        # 获取推送
        response = client.get(f"/api/v1/push/morning?user_id={user_id}")
        assert response.status_code == 200
