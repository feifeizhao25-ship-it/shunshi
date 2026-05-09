"""顺时 - 肺部养护测试"""
import pytest


class TestLungTcmFunctions:
    def test_tcm_functions_returns_200(self, client):
        response = client.get("/api/v1/lung-care/tcm-functions")
        assert response.status_code == 200

    def test_tcm_functions_success(self, client):
        data = client.get("/api/v1/lung-care/tcm-functions").json()
        assert data["success"] is True


class TestLungFoods:
    def test_foods_returns_200(self, client):
        response = client.get("/api/v1/lung-care/foods")
        assert response.status_code == 200

    def test_foods_has_list(self, client):
        data = client.get("/api/v1/lung-care/foods").json()
        assert "data" in data


class TestLungBreathingExercises:
    def test_breathing_returns_200(self, client):
        response = client.get("/api/v1/lung-care/breathing-exercises")
        assert response.status_code == 200


class TestLungAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/lung-care/acupoints")
        assert response.status_code == 200


class TestLungSeasonalCare:
    def test_seasonal_returns_200(self, client):
        response = client.get("/api/v1/lung-care/seasonal-care")
        assert response.status_code == 200

    def test_seasonal_has_data(self, client):
        data = client.get("/api/v1/lung-care/seasonal-care").json()
        assert "data" in data


class TestLungDailyPlan:
    def test_daily_plan_returns_200(self, client):
        response = client.get("/api/v1/lung-care/daily-plan")
        assert response.status_code == 200
