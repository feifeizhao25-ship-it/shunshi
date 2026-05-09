"""顺时 - 胃部养护测试"""
import pytest


class TestStomachConditions:
    def test_conditions_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/conditions")
        assert response.status_code == 200

    def test_conditions_has_list(self, client):
        data = client.get("/api/v1/stomach-care/conditions").json()
        assert "data" in data
        assert data["success"] is True


class TestStomachConditionDetail:
    def test_valid_condition_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/conditions/gastritis")
        assert response.status_code == 200

    def test_invalid_condition_returns_404(self, client):
        assert client.get("/api/v1/stomach-care/conditions/nonexistent").status_code == 404


class TestStomachProtectionTips:
    def test_tips_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/protection-tips")
        assert response.status_code == 200


class TestStomachSeasonalCare:
    def test_seasonal_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/seasonal-care")
        assert response.status_code == 200


class TestStomachAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/acupoints")
        assert response.status_code == 200


class TestStomachDietGuide:
    def test_diet_guide_returns_200(self, client):
        response = client.get("/api/v1/stomach-care/diet-guide")
        assert response.status_code == 200

    def test_diet_guide_has_data(self, client):
        data = client.get("/api/v1/stomach-care/diet-guide").json()
        assert data["success"] is True
