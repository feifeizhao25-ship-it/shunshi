"""顺时 - 护眼测试"""
import pytest


class TestEyeExercises:
    def test_exercises_returns_200(self, client):
        response = client.get("/api/v1/eye-care/exercises")
        assert response.status_code == 200

    def test_exercises_has_list(self, client):
        data = client.get("/api/v1/eye-care/exercises").json()
        assert "exercises" in data["data"]


class TestEyeExerciseDetail:
    def test_exercise_detail_returns_200(self, client):
        response = client.get("/api/v1/eye-care/exercises/eye_roll")
        assert response.status_code == 200

    def test_invalid_exercise_returns_404(self, client):
        assert client.get("/api/v1/eye-care/exercises/nonexistent").status_code == 404


class TestEyeAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/eye-care/acupoints")
        assert response.status_code == 200

    def test_acupoints_not_empty(self, client):
        data = client.get("/api/v1/eye-care/acupoints").json()
        assert "data" in data


class TestEyeDigitalStrain:
    def test_digital_strain_returns_200(self, client):
        response = client.get("/api/v1/eye-care/digital-eye-strain")
        assert response.status_code == 200


class TestEyeDiet:
    def test_diet_returns_200(self, client):
        response = client.get("/api/v1/eye-care/diet")
        assert response.status_code == 200


class TestEyeDailyCare:
    def test_daily_care_returns_200(self, client):
        response = client.get("/api/v1/eye-care/daily-care")
        assert response.status_code == 200

    def test_daily_care_has_routine(self, client):
        data = client.get("/api/v1/eye-care/daily-care").json()
        assert data["success"] is True
