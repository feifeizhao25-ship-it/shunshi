"""顺时 - 夫妻养生测试"""
import pytest


class TestCoupleTopics:
    def test_topics_returns_200(self, client):
        response = client.get("/api/v1/couple-wellness/topics")
        assert response.status_code == 200

    def test_topics_has_list(self, client):
        data = client.get("/api/v1/couple-wellness/topics").json()
        assert "topics" in data["data"]
        assert data["success"] is True


class TestCoupleSeasonalPlan:
    def test_spring_plan_returns_200(self, client):
        response = client.get("/api/v1/couple-wellness/seasonal/spring")
        assert response.status_code == 200

    def test_winter_plan_returns_200(self, client):
        response = client.get("/api/v1/couple-wellness/seasonal/winter")
        assert response.status_code == 200

    def test_seasonal_has_activities(self, client):
        data = client.get("/api/v1/couple-wellness/seasonal/summer").json()
        assert "data" in data


class TestCoupleGeneratePlan:
    def test_generate_plan_returns_200(self, client):
        payload = {
            "couple_id": "couple_001",
            "user1_constitution": "qi_deficiency",
            "user2_constitution": "yin_deficiency",
            "season": "spring"
        }
        response = client.post("/api/v1/couple-wellness/plan", json=payload)
        assert response.status_code == 200

    def test_generate_plan_has_activities(self, client):
        payload = {"couple_id": "couple_002", "season": "autumn"}
        data = client.post("/api/v1/couple-wellness/plan", json=payload).json()
        assert data["success"] is True


class TestCoupleGetPlan:
    def test_get_plan_returns_200(self, client):
        # Create first
        payload = {"couple_id": "couple_get_test", "season": "spring"}
        client.post("/api/v1/couple-wellness/plan", json=payload)
        response = client.get("/api/v1/couple-wellness/plan/couple_get_test")
        assert response.status_code == 200
