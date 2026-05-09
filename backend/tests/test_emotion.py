"""
顺时 - 情绪端点测试
test_emotion.py
"""

import pytest


class TestEmotionLog:
    """情绪记录端点测试"""

    def test_log_calm_returns_200(self, client):
        """POST /api/v1/emotion/log 记录 calm 返回 200"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 2,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 200

    def test_log_has_guidance(self, client):
        """响应包含 'guidance' 键和 immediate_action"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 2,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "guidance" in data["data"]
        assert "immediate_action" in data["data"]["guidance"]

    def test_log_anxious(self, client):
        """POST 记录 anxious 返回 200"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "anxious",
            "intensity": 4,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["emotion"] == "anxious"

    def test_log_invalid_emotion_422(self, client):
        """POST 记录无效情绪返回 422"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "invalid_emotion",
            "intensity": 3,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 422

    def test_log_intensity_too_high_422(self, client):
        """POST intensity=10（超过上限）返回 422"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 10,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 422

    def test_log_intensity_too_low_422(self, client):
        """POST intensity=0（低于下限）返回 422"""
        payload = {
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 0,
        }
        response = client.post("/api/v1/emotion/log", json=payload)
        assert response.status_code == 422

    def test_log_message_varies_by_intensity(self, client):
        """检查消息随强度变化而不同"""
        # 强度 1
        response1 = client.post("/api/v1/emotion/log", json={
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 1,
        })
        msg1 = response1.json()["data"]["message"]

        # 强度 5
        response5 = client.post("/api/v1/emotion/log", json={
            "user_id": "test-user-001",
            "emotion": "calm",
            "intensity": 5,
        })
        msg5 = response5.json()["data"]["message"]

        # 消息应该不同
        assert msg1 != msg5


class TestEmotionGuide:
    """情绪指南端点测试"""

    def test_guide_returns_200(self, client):
        """GET /api/v1/emotion/guide 返回 200"""
        response = client.get("/api/v1/emotion/guide")
        assert response.status_code == 200

    def test_guide_north(self, client):
        """GET /api/v1/emotion/guide?hemisphere=north 包含 seasonal_pattern"""
        response = client.get("/api/v1/emotion/guide?hemisphere=north")
        assert response.status_code == 200
        data = response.json()
        assert "seasonal_pattern" in data["data"]
        assert isinstance(data["data"]["seasonal_pattern"], list)

    def test_guide_south(self, client):
        """GET /api/v1/emotion/guide?hemisphere=south 返回 200"""
        response = client.get("/api/v1/emotion/guide?hemisphere=south")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_guide_with_emotion(self, client):
        """GET /api/v1/emotion/guide?current_emotion=anxious 包含 personalized_response"""
        response = client.get("/api/v1/emotion/guide?current_emotion=anxious")
        assert response.status_code == 200
        data = response.json()
        assert "personalized_response" in data["data"]
        assert "personalized_for" in data["data"]
        assert data["data"]["personalized_for"] == "anxious"


class TestEmotionCheckin:
    """情绪签到端点测试"""

    def test_checkin_returns_200(self, client):
        """GET /api/v1/emotion/check-in 返回 200"""
        response = client.get("/api/v1/emotion/check-in")
        assert response.status_code == 200

    def test_checkin_has_8_emotions(self, client):
        """响应数据包含 8 种情绪"""
        response = client.get("/api/v1/emotion/check-in")
        assert response.status_code == 200
        data = response.json()
        assert "emotions" in data["data"]
        emotions = data["data"]["emotions"]
        assert len(emotions) == 8
        # 验证情绪结构
        for e in emotions:
            assert "key" in e
            assert "label" in e
            assert "emoji" in e


class TestEmotionInsights:
    """情绪深度解读端点测试"""

    def test_insight_calm(self, client):
        """GET /api/v1/emotion/insights/calm 返回 200，包含 affirmation"""
        response = client.get("/api/v1/emotion/insights/calm")
        assert response.status_code == 200
        data = response.json()
        assert "affirmation" in data["data"]
        assert data["data"]["emotion"] == "calm"

    def test_insight_anxious(self, client):
        """GET /api/v1/emotion/insights/anxious 包含 tcm_organ"""
        response = client.get("/api/v1/emotion/insights/anxious")
        assert response.status_code == 200
        data = response.json()
        assert "tcm_organ" in data["data"]
        assert "tcm_element" in data["data"]
        assert data["data"]["emotion"] == "anxious"

    def test_insight_unknown_404(self, client):
        """GET /api/v1/emotion/insights/bliss 返回 404"""
        response = client.get("/api/v1/emotion/insights/bliss")
        assert response.status_code == 404
