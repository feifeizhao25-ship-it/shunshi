"""顺时 - 宠物养生测试"""
import pytest


class TestPetSeasonalCare:
    def test_seasonal_care_returns_200(self, client):
        response = client.get("/api/v1/pet-wellness/seasonal-care")
        assert response.status_code == 200

    def test_seasonal_care_has_data(self, client):
        data = client.get("/api/v1/pet-wellness/seasonal-care").json()
        assert "seasonal_care" in data["data"]
        assert data["success"] is True

    def test_seasonal_filter_by_season(self, client):
        response = client.get("/api/v1/pet-wellness/seasonal-care?season=winter")
        assert response.status_code == 200


class TestPetHealthSigns:
    def test_health_signs_returns_200(self, client):
        response = client.get("/api/v1/pet-wellness/health-signs")
        assert response.status_code == 200

    def test_health_signs_has_data(self, client):
        data = client.get("/api/v1/pet-wellness/health-signs").json()
        assert "data" in data


class TestPetTcmWisdom:
    def test_tcm_wisdom_returns_200(self, client):
        response = client.get("/api/v1/pet-wellness/tcm-wisdom")
        assert response.status_code == 200


class TestPetHealthyFoods:
    def test_healthy_foods_returns_200(self, client):
        response = client.get("/api/v1/pet-wellness/healthy-foods")
        assert response.status_code == 200

    def test_healthy_foods_filter_by_pet(self, client):
        response = client.get("/api/v1/pet-wellness/healthy-foods?pet_type=dog")
        assert response.status_code == 200


class TestPetOverview:
    def test_overview_returns_200(self, client):
        response = client.get("/api/v1/pet-wellness/overview")
        assert response.status_code == 200

    def test_overview_success(self, client):
        data = client.get("/api/v1/pet-wellness/overview").json()
        assert data["success"] is True
