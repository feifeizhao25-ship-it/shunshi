"""顺时 - 食物相克测试"""
import pytest


class TestFoodCompatibilityList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/food-compatibility/list")
        assert response.status_code == 200

    def test_list_has_pairs(self, client):
        data = client.get("/api/v1/food-compatibility/list").json()
        assert "incompatible_pairs" in data["data"]
        assert len(data["data"]["incompatible_pairs"]) > 0


class TestFoodCompatibilityCheck:
    def test_check_incompatible_pair(self, client):
        payload = {"food1": "螃蟹", "food2": "柿子"}
        response = client.post("/api/v1/food-compatibility/check", json=payload)
        assert response.status_code == 200

    def test_check_has_is_compatible(self, client):
        payload = {"food1": "苹果", "food2": "香蕉"}
        data = client.post("/api/v1/food-compatibility/check", json=payload).json()
        assert "is_compatible" in data["data"]

    def test_check_requires_both_foods(self, client):
        response = client.post("/api/v1/food-compatibility/check", json={"food1": "苹果"})
        assert response.status_code == 422


class TestFoodCompatibilityByFood:
    def test_by_food_returns_200(self, client):
        response = client.get("/api/v1/food-compatibility/food/螃蟹")
        assert response.status_code == 200

    def test_by_food_has_incompatible(self, client):
        data = client.get("/api/v1/food-compatibility/food/螃蟹").json()
        assert "data" in data


class TestFoodProperties:
    def test_properties_returns_200(self, client):
        response = client.get("/api/v1/food-compatibility/properties/螃蟹")
        assert response.status_code == 200
