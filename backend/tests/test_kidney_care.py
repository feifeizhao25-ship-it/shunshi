"""顺时 - 肾脏养护测试"""
import pytest


class TestKidneyTcmFunctions:
    def test_tcm_functions_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/tcm-functions")
        assert response.status_code == 200


class TestKidneyDeficiencyTypes:
    def test_deficiency_types_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/deficiency-types")
        assert response.status_code == 200

    def test_deficiency_types_has_list(self, client):
        data = client.get("/api/v1/kidney-care/deficiency-types").json()
        assert "deficiency_types" in data["data"]


class TestKidneyDeficiencyTypeDetail:
    def test_valid_type_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/deficiency-types/kidney_yin")
        assert response.status_code == 200

    def test_invalid_type_returns_404(self, client):
        assert client.get("/api/v1/kidney-care/deficiency-types/nonexistent").status_code == 404


class TestKidneyFoods:
    def test_foods_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/foods")
        assert response.status_code == 200


class TestKidneyAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/acupoints")
        assert response.status_code == 200


class TestKidneyDailyPlan:
    def test_daily_plan_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/daily-plan")
        assert response.status_code == 200


class TestKidneySeasonalCare:
    def test_seasonal_returns_200(self, client):
        response = client.get("/api/v1/kidney-care/seasonal-care")
        assert response.status_code == 200
