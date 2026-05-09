"""顺时 - 感恩日记测试"""
import pytest


class TestGratitudeLog:
    def test_log_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "content": "今天阳光很好，很感恩。",
            "items": ["健康", "家人", "工作"],
            "mood": "happy"
        }
        response = client.post("/api/v1/gratitude/log", json=payload)
        assert response.status_code == 200

    def test_log_success(self, client):
        payload = {"user_id": "test_user", "content": "感恩今日平安。"}
        data = client.post("/api/v1/gratitude/log", json=payload).json()
        assert data["success"] is True

    def test_log_requires_user_id(self, client):
        response = client.post("/api/v1/gratitude/log", json={"content": "感恩"})
        assert response.status_code == 422


class TestGratitudeHistory:
    def test_history_returns_200(self, client):
        response = client.get("/api/v1/gratitude/history/test_user")
        assert response.status_code == 200

    def test_history_has_entries(self, client):
        data = client.get("/api/v1/gratitude/history/test_user").json()
        assert "entries" in data["data"]


class TestGratitudeStreak:
    def test_streak_returns_200(self, client):
        response = client.get("/api/v1/gratitude/streak/test_user")
        assert response.status_code == 200

    def test_streak_has_count(self, client):
        data = client.get("/api/v1/gratitude/streak/test_user").json()
        assert "streak_days" in data["data"]


class TestGratitudeDailyPrompts:
    def test_prompts_returns_200(self, client):
        response = client.get("/api/v1/gratitude/prompts/daily")
        assert response.status_code == 200

    def test_prompts_has_prompt(self, client):
        data = client.get("/api/v1/gratitude/prompts/daily").json()
        assert "prompt" in data["data"]


class TestGratitudeInsights:
    def test_insights_returns_200(self, client):
        response = client.get("/api/v1/gratitude/insights")
        assert response.status_code == 200
