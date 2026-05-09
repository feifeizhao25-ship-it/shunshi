"""顺时 - 护发测试"""
import pytest


class TestHairTcmTheory:
    def test_tcm_theory_returns_200(self, client):
        response = client.get("/api/v1/hair-care/tcm-theory")
        assert response.status_code == 200

    def test_tcm_theory_has_data(self, client):
        data = client.get("/api/v1/hair-care/tcm-theory").json()
        assert data["success"] is True


class TestHairConditions:
    def test_conditions_returns_200(self, client):
        response = client.get("/api/v1/hair-care/conditions")
        assert response.status_code == 200

    def test_conditions_has_list(self, client):
        data = client.get("/api/v1/hair-care/conditions").json()
        assert "conditions" in data["data"]


class TestHairConditionDetail:
    def test_valid_condition_returns_200(self, client):
        response = client.get("/api/v1/hair-care/conditions/hair_loss")
        assert response.status_code == 200

    def test_invalid_condition_returns_404(self, client):
        assert client.get("/api/v1/hair-care/conditions/nonexistent").status_code == 404


class TestHairFoods:
    def test_foods_returns_200(self, client):
        response = client.get("/api/v1/hair-care/foods")
        assert response.status_code == 200


class TestHairScalpMassage:
    def test_scalp_massage_returns_200(self, client):
        response = client.get("/api/v1/hair-care/scalp-massage")
        assert response.status_code == 200


class TestHairDailyCare:
    def test_daily_care_returns_200(self, client):
        response = client.get("/api/v1/hair-care/daily-care")
        assert response.status_code == 200
