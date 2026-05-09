"""顺时 - 体重管理测试"""
import pytest


class TestWeightLog:
    def test_log_returns_200(self, client):
        payload = {"user_id": "test_user", "weight_kg": 65.5, "date": "2024-01-01"}
        response = client.post("/api/v1/weight-manage/log", json=payload)
        assert response.status_code == 200

    def test_log_success(self, client):
        payload = {"user_id": "test_user", "weight_kg": 70.0}
        data = client.post("/api/v1/weight-manage/log", json=payload).json()
        assert data["success"] is True

    def test_log_requires_user_id(self, client):
        response = client.post("/api/v1/weight-manage/log", json={"weight_kg": 65.0})
        assert response.status_code == 422


class TestWeightHistory:
    def test_history_returns_200(self, client):
        response = client.get("/api/v1/weight-manage/history/test_user")
        assert response.status_code == 200

    def test_history_has_records(self, client):
        data = client.get("/api/v1/weight-manage/history/test_user").json()
        assert "data" in data


class TestWeightGoal:
    def test_set_goal_returns_200(self, client):
        payload = {"user_id": "test_user", "target_weight_kg": 60.0, "weeks": 12}
        response = client.post("/api/v1/weight-manage/goal", json=payload)
        assert response.status_code == 200


class TestWeightTcmPlan:
    def test_tcm_plan_returns_200(self, client):
        response = client.get("/api/v1/weight-manage/tcm-plan?constitution=phlegm_dampness")
        assert response.status_code == 200

    def test_tcm_plan_has_plan(self, client):
        data = client.get("/api/v1/weight-manage/tcm-plan").json()
        assert "data" in data


class TestWeightAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/weight-manage/acupoints")
        assert response.status_code == 200


class TestWeightBMIGuide:
    def test_bmi_guide_returns_200(self, client):
        response = client.get("/api/v1/weight-manage/bmi-guide")
        assert response.status_code == 200

    def test_bmi_guide_has_categories(self, client):
        data = client.get("/api/v1/weight-manage/bmi-guide").json()
        assert data["success"] is True
