"""顺时 - 习惯养成测试"""
import pytest


class TestHabitTemplates:
    def test_templates_returns_200(self, client):
        response = client.get("/api/v1/habits/templates")
        assert response.status_code == 200

    def test_templates_has_list(self, client):
        data = client.get("/api/v1/habits/templates").json()
        assert "templates" in data["data"]
        assert len(data["data"]["templates"]) > 0


class TestHabitCreate:
    def test_create_habit_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "name": "早起练功",
            "category": "exercise",
            "frequency": "daily",
            "target_days": 21
        }
        response = client.post("/api/v1/habits/", json=payload)
        assert response.status_code == 200

    def test_create_habit_has_id(self, client):
        payload = {"user_id": "test_user", "name": "晨间冥想", "category": "meditation"}
        data = client.post("/api/v1/habits/", json=payload).json()
        assert data["success"] is True
        assert "habit_id" in data["data"]


class TestHabitUserList:
    def test_user_habits_returns_200(self, client):
        response = client.get("/api/v1/habits/user/test_user")
        assert response.status_code == 200

    def test_user_habits_has_list(self, client):
        data = client.get("/api/v1/habits/user/test_user").json()
        assert "habits" in data["data"]


class TestHabitCheckin:
    def test_checkin_returns_200(self, client):
        # Create a habit first
        create_data = client.post("/api/v1/habits/",
                                  json={"user_id": "test_user", "name": "CheckinTest", "category": "health"}).json()
        habit_id = create_data["data"]["habit_id"]
        response = client.post(f"/api/v1/habits/{habit_id}/checkin",
                               json={"user_id": "test_user"})
        assert response.status_code == 200

    def test_checkin_updates_streak(self, client):
        create_data = client.post("/api/v1/habits/",
                                  json={"user_id": "test_user", "name": "StreakTest", "category": "diet"}).json()
        habit_id = create_data["data"]["habit_id"]
        data = client.post(f"/api/v1/habits/{habit_id}/checkin",
                           json={"user_id": "test_user"}).json()
        assert data["success"] is True


class TestHabitProgress:
    def test_progress_returns_200(self, client):
        create_data = client.post("/api/v1/habits/",
                                  json={"user_id": "test_user", "name": "ProgressTest", "category": "sleep"}).json()
        habit_id = create_data["data"]["habit_id"]
        response = client.get(f"/api/v1/habits/{habit_id}/progress")
        assert response.status_code == 200


class TestHabitCategories:
    def test_categories_returns_200(self, client):
        response = client.get("/api/v1/habits/categories/list")
        assert response.status_code == 200
