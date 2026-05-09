"""顺时 - 月经期养护测试"""
import pytest


class TestMenstrualCycleLog:
    def test_log_cycle_returns_200(self, client):
        payload = {"user_id": "test_user", "start_date": "2024-01-01", "cycle_length": 28}
        response = client.post("/api/v1/menstrual/cycle/log", json=payload)
        assert response.status_code == 200

    def test_log_returns_success(self, client):
        payload = {"user_id": "test_user", "start_date": "2024-02-01"}
        data = client.post("/api/v1/menstrual/cycle/log", json=payload).json()
        assert data["success"] is True

    def test_log_requires_user_id(self, client):
        response = client.post("/api/v1/menstrual/cycle/log", json={"start_date": "2024-01-01"})
        assert response.status_code == 422


class TestMenstrualHistory:
    def test_history_returns_200(self, client):
        response = client.get("/api/v1/menstrual/cycle/history?user_id=test_user")
        assert response.status_code == 200

    def test_history_has_data(self, client):
        data = client.get("/api/v1/menstrual/cycle/history?user_id=test_user").json()
        assert "data" in data


class TestMenstrualSettings:
    def test_settings_returns_200(self, client):
        payload = {"user_id": "test_user", "cycle_length": 30, "period_length": 5}
        response = client.post("/api/v1/menstrual/settings", json=payload)
        assert response.status_code == 200


class TestMenstrualPredict:
    def test_predict_returns_200(self, client):
        response = client.get("/api/v1/menstrual/predict?user_id=test_user")
        assert response.status_code == 200


class TestMenstrualPhaseCare:
    def test_phase_care_returns_200(self, client):
        response = client.get("/api/v1/menstrual/phase-care?user_id=test_user")
        assert response.status_code == 200


class TestMenstrualDysmenorrhea:
    def test_dysmenorrhea_returns_200(self, client):
        response = client.get("/api/v1/menstrual/dysmenorrhea")
        assert response.status_code == 200

    def test_dysmenorrhea_has_remedies(self, client):
        data = client.get("/api/v1/menstrual/dysmenorrhea").json()
        assert data["success"] is True
