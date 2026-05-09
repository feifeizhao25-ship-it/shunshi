"""顺时 - 新手引导测试"""
import pytest


class TestOnboardingSteps:
    def test_steps_returns_200(self, client):
        response = client.get("/api/v1/onboarding/steps")
        assert response.status_code == 200

    def test_steps_has_list(self, client):
        data = client.get("/api/v1/onboarding/steps").json()
        assert "steps" in data["data"]
        assert len(data["data"]["steps"]) > 0


class TestOnboardingProgress:
    def test_progress_returns_200(self, client):
        response = client.get("/api/v1/onboarding/progress/test_user")
        assert response.status_code == 200

    def test_progress_has_status(self, client):
        data = client.get("/api/v1/onboarding/progress/test_user").json()
        assert "data" in data


class TestOnboardingUpdateProgress:
    def test_update_progress_returns_200(self, client):
        payload = {"user_id": "test_user", "step_id": "welcome", "completed": True}
        response = client.post("/api/v1/onboarding/progress", json=payload)
        assert response.status_code == 200

    def test_update_progress_success(self, client):
        payload = {"user_id": "test_user", "step_id": "constitution_quiz", "completed": True}
        data = client.post("/api/v1/onboarding/progress", json=payload).json()
        assert data["success"] is True


class TestOnboardingHealthGoals:
    def test_health_goals_returns_200(self, client):
        response = client.get("/api/v1/onboarding/health-goals")
        assert response.status_code == 200

    def test_health_goals_has_options(self, client):
        data = client.get("/api/v1/onboarding/health-goals").json()
        assert "goals" in data["data"]


class TestOnboardingConstitutionQuiz:
    def test_quiz_returns_200(self, client):
        response = client.get("/api/v1/onboarding/constitution-quiz")
        assert response.status_code == 200

    def test_quiz_has_questions(self, client):
        data = client.get("/api/v1/onboarding/constitution-quiz").json()
        assert "questions" in data["data"]


class TestOnboardingQuizSubmit:
    def test_submit_quiz_returns_200(self, client):
        payload = {"user_id": "test_user", "answers": {"q1": "a", "q2": "b"}}
        response = client.post("/api/v1/onboarding/constitution-quiz/submit", json=payload)
        assert response.status_code == 200
