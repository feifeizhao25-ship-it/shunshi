"""顺时 - 肝脏养护测试"""
import pytest


class TestLiverTcmFunctions:
    def test_tcm_functions_returns_200(self, client):
        response = client.get("/api/v1/liver-care/tcm-functions")
        assert response.status_code == 200

    def test_tcm_functions_has_data(self, client):
        data = client.get("/api/v1/liver-care/tcm-functions").json()
        assert data["success"] is True


class TestLiverCareFoods:
    def test_care_foods_returns_200(self, client):
        response = client.get("/api/v1/liver-care/care-foods")
        assert response.status_code == 200


class TestLiverMeridianCare:
    def test_meridian_care_returns_200(self, client):
        response = client.get("/api/v1/liver-care/meridian-care")
        assert response.status_code == 200


class TestLiverEmotionRegulation:
    def test_emotion_regulation_returns_200(self, client):
        response = client.get("/api/v1/liver-care/emotion-regulation")
        assert response.status_code == 200

    def test_emotion_regulation_has_data(self, client):
        data = client.get("/api/v1/liver-care/emotion-regulation").json()
        assert "data" in data


class TestLiverDailyPlan:
    def test_daily_plan_returns_200(self, client):
        response = client.get("/api/v1/liver-care/daily-plan")
        assert response.status_code == 200


class TestLiverSeasonalCare:
    def test_seasonal_care_returns_200(self, client):
        response = client.get("/api/v1/liver-care/seasonal-care")
        assert response.status_code == 200
