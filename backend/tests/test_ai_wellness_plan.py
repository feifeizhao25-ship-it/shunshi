"""顺时 - AI健康计划测试"""
import pytest


class TestAIWellnessPlanGenerate:
    def test_generate_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "constitution": "qi_deficiency",
            "season": "spring",
            "available_time_minutes": 30,
            "fitness_level": "beginner"
        }
        response = client.post("/api/v1/ai-wellness-plan/generate", json=payload)
        assert response.status_code == 200

    def test_generate_has_plan(self, client):
        payload = {"user_id": "test_user", "constitution": "yin_deficiency"}
        data = client.post("/api/v1/ai-wellness-plan/generate", json=payload).json()
        assert data["success"] is True
        assert "plan" in data["data"]

    def test_generate_requires_user_id(self, client):
        response = client.post("/api/v1/ai-wellness-plan/generate",
                               json={"constitution": "qi_deficiency"})
        assert response.status_code == 422

    def test_generate_requires_constitution(self, client):
        response = client.post("/api/v1/ai-wellness-plan/generate",
                               json={"user_id": "test_user"})
        assert response.status_code == 422


class TestAIWellnessPlanGet:
    def test_get_plan_returns_200(self, client):
        payload = {"user_id": "test_user", "constitution": "qi_deficiency", "season": "spring"}
        create_data = client.post("/api/v1/ai-wellness-plan/generate", json=payload).json()
        plan_id = create_data["data"]["plan"]["plan_id"]
        response = client.get(f"/api/v1/ai-wellness-plan/plan/{plan_id}")
        assert response.status_code == 200

    def test_nonexistent_plan_returns_404(self, client):
        assert client.get("/api/v1/ai-wellness-plan/plan/nonexistent_plan").status_code == 404


class TestAIWellnessPlanLatest:
    def test_latest_plan_returns_200_after_generate(self, client):
        payload = {"user_id": "plan_latest_test", "constitution": "qi_deficiency"}
        client.post("/api/v1/ai-wellness-plan/generate", json=payload)
        response = client.get("/api/v1/ai-wellness-plan/user/plan_latest_test/latest")
        assert response.status_code == 200

    def test_latest_no_plan_returns_404(self, client):
        response = client.get("/api/v1/ai-wellness-plan/user/no_plan_user/latest")
        assert response.status_code == 404


class TestAIWellnessPlanFeedback:
    def test_feedback_returns_200(self, client):
        payload = {"user_id": "test_user", "constitution": "qi_deficiency"}
        create_data = client.post("/api/v1/ai-wellness-plan/generate", json=payload).json()
        plan_id = create_data["data"]["plan"]["plan_id"]
        feedback_payload = {"user_id": "test_user", "plan_id": plan_id, "rating": 4}
        response = client.post("/api/v1/ai-wellness-plan/feedback", json=feedback_payload)
        assert response.status_code == 200

    def test_feedback_nonexistent_plan(self, client):
        payload = {"user_id": "test_user", "plan_id": "nonexistent", "rating": 3}
        assert client.post("/api/v1/ai-wellness-plan/feedback", json=payload).status_code == 404


class TestAIWellnessConstitutionTips:
    def test_constitution_tips_returns_200(self, client):
        response = client.get("/api/v1/ai-wellness-plan/constitution-tips")
        assert response.status_code == 200

    def test_constitution_tips_has_list(self, client):
        data = client.get("/api/v1/ai-wellness-plan/constitution-tips").json()
        assert "tips" in data["data"]
