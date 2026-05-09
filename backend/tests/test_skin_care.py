"""顺时 - 护肤测试"""
import pytest


class TestSkinConstitutionCare:
    def test_constitution_care_returns_200(self, client):
        response = client.get("/api/v1/skin-care/constitution-care")
        assert response.status_code == 200

    def test_constitution_care_has_data(self, client):
        data = client.get("/api/v1/skin-care/constitution-care").json()
        assert "skin_types" in data["data"]
        assert data["success"] is True

    def test_constitution_care_filter(self, client):
        response = client.get("/api/v1/skin-care/constitution-care?constitution=yin_deficiency")
        assert response.status_code == 200


class TestSkinSeasonalCare:
    def test_seasonal_care_returns_200(self, client):
        response = client.get("/api/v1/skin-care/seasonal-care")
        assert response.status_code == 200

    def test_seasonal_care_has_seasons(self, client):
        data = client.get("/api/v1/skin-care/seasonal-care").json()
        assert "seasonal_care" in data["data"]


class TestSkinBrighteningRecipes:
    def test_brightening_returns_200(self, client):
        response = client.get("/api/v1/skin-care/brightening-recipes")
        assert response.status_code == 200

    def test_brightening_has_recipes(self, client):
        data = client.get("/api/v1/skin-care/brightening-recipes").json()
        assert "data" in data


class TestSkinDailyRoutine:
    def test_daily_routine_returns_200(self, client):
        response = client.get("/api/v1/skin-care/daily-routine")
        assert response.status_code == 200

    def test_daily_routine_has_steps(self, client):
        data = client.get("/api/v1/skin-care/daily-routine").json()
        assert data["success"] is True
