"""顺时 - 产后恢复测试"""
import pytest


class TestPostpartumPhases:
    def test_phases_returns_200(self, client):
        response = client.get("/api/v1/postpartum/phases")
        assert response.status_code == 200

    def test_phases_has_list(self, client):
        data = client.get("/api/v1/postpartum/phases").json()
        assert "phases" in data["data"]
        assert len(data["data"]["phases"]) > 0


class TestPostpartumPhaseDetail:
    def test_valid_phase_returns_200(self, client):
        response = client.get("/api/v1/postpartum/phases/week1")
        assert response.status_code == 200

    def test_invalid_phase_returns_404(self, client):
        assert client.get("/api/v1/postpartum/phases/nonexistent").status_code == 404


class TestPostpartumLactationFoods:
    def test_lactation_foods_returns_200(self, client):
        response = client.get("/api/v1/postpartum/lactation-foods")
        assert response.status_code == 200

    def test_lactation_foods_has_list(self, client):
        data = client.get("/api/v1/postpartum/lactation-foods").json()
        assert "data" in data


class TestPostpartumExercises:
    def test_exercises_returns_200(self, client):
        response = client.get("/api/v1/postpartum/exercises")
        assert response.status_code == 200


class TestPostpartumDepressionSupport:
    def test_depression_support_returns_200(self, client):
        response = client.get("/api/v1/postpartum/depression-support")
        assert response.status_code == 200

    def test_depression_support_has_resources(self, client):
        data = client.get("/api/v1/postpartum/depression-support").json()
        assert data["success"] is True


class TestPostpartumDietGuide:
    def test_diet_guide_returns_200(self, client):
        response = client.get("/api/v1/postpartum/diet-guide")
        assert response.status_code == 200
