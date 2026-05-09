"""顺时 - 卡路里追踪测试"""
import pytest


class TestCalorieFoodSearch:
    def test_search_returns_200(self, client):
        response = client.get("/api/v1/calorie-tracker/foods/search?q=米饭")
        assert response.status_code == 200

    def test_search_has_results(self, client):
        data = client.get("/api/v1/calorie-tracker/foods/search?q=米饭").json()
        assert "results" in data["data"]


class TestCalorieFoodDetail:
    def test_food_detail_returns_200(self, client):
        response = client.get("/api/v1/calorie-tracker/foods/rice")
        assert response.status_code == 200

    def test_invalid_food_returns_404(self, client):
        assert client.get("/api/v1/calorie-tracker/foods/nonexistent_food").status_code == 404


class TestCalorieLog:
    def test_log_meal_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "meal_type": "breakfast",
            "foods": [{"food_id": "rice", "amount_g": 150}]
        }
        response = client.post("/api/v1/calorie-tracker/log", json=payload)
        assert response.status_code == 200

    def test_log_meal_success(self, client):
        payload = {
            "user_id": "test_user",
            "meal_type": "lunch",
            "foods": [{"food_id": "tofu", "amount_g": 100}]
        }
        data = client.post("/api/v1/calorie-tracker/log", json=payload).json()
        assert data["success"] is True

    def test_log_requires_user_id(self, client):
        response = client.post("/api/v1/calorie-tracker/log",
                               json={"meal_type": "breakfast", "foods": []})
        assert response.status_code == 422


class TestCalorieToday:
    def test_today_returns_200(self, client):
        response = client.get("/api/v1/calorie-tracker/today?user_id=test_user")
        assert response.status_code == 200

    def test_today_has_totals(self, client):
        data = client.get("/api/v1/calorie-tracker/today?user_id=test_user").json()
        assert "data" in data


class TestCalorieGoal:
    def test_set_goal_returns_200(self, client):
        payload = {"user_id": "test_user", "daily_calories": 1800}
        response = client.post("/api/v1/calorie-tracker/goal", json=payload)
        assert response.status_code == 200


class TestCalorieBMR:
    def test_bmr_calculator_returns_200(self, client):
        response = client.get("/api/v1/calorie-tracker/bmr-calculator"
                              "?gender=female&age=30&weight_kg=55&height_cm=160&activity_level=moderate")
        assert response.status_code == 200

    def test_bmr_has_value(self, client):
        response = client.get("/api/v1/calorie-tracker/bmr-calculator"
                              "?gender=male&age=25&weight_kg=70&height_cm=175")
        data = response.json()
        assert "data" in data
