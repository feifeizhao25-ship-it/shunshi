"""顺时 - 饮水追踪测试"""
import pytest


class TestWaterTrackerLog:
    def test_log_returns_200(self, client):
        payload = {"user_id": "test_user", "amount_ml": 250, "type": "water"}
        response = client.post("/api/v1/water-tracker/log", json=payload)
        assert response.status_code == 200

    def test_log_returns_success(self, client):
        payload = {"user_id": "test_user", "amount_ml": 300}
        data = client.post("/api/v1/water-tracker/log", json=payload).json()
        assert data["success"] is True

    def test_log_requires_user_id(self, client):
        response = client.post("/api/v1/water-tracker/log", json={"amount_ml": 200})
        assert response.status_code == 422


class TestWaterTrackerToday:
    def test_today_returns_200(self, client):
        response = client.get("/api/v1/water-tracker/today?user_id=test_user")
        assert response.status_code == 200

    def test_today_has_total(self, client):
        data = client.get("/api/v1/water-tracker/today?user_id=test_user").json()
        assert "data" in data


class TestWaterTrackerGoal:
    def test_set_goal_returns_200(self, client):
        payload = {"user_id": "test_user", "goal_ml": 2000}
        response = client.post("/api/v1/water-tracker/goal", json=payload)
        assert response.status_code == 200


class TestWaterTrackerRecommend:
    def test_recommend_returns_200(self, client):
        response = client.get("/api/v1/water-tracker/recommend?user_id=test_user")
        assert response.status_code == 200

    def test_recommend_has_advice(self, client):
        data = client.get("/api/v1/water-tracker/recommend?user_id=test_user").json()
        assert "data" in data
        assert data["success"] is True
