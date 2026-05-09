"""顺时 - 食疗方案测试"""
import pytest


class TestFoodTherapyList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/food-therapy/list")
        assert response.status_code == 200

    def test_list_has_recipes(self, client):
        data = client.get("/api/v1/food-therapy/list").json()
        assert "recipes" in data["data"]
        assert len(data["data"]["recipes"]) > 0

    def test_list_filter_by_constitution(self, client):
        response = client.get("/api/v1/food-therapy/list?constitution=qi_deficiency")
        assert response.status_code == 200


class TestFoodTherapyDetail:
    def test_valid_id_returns_200(self, client):
        response = client.get("/api/v1/food-therapy/yam_millet_porridge")
        assert response.status_code == 200

    def test_invalid_id_returns_404(self, client):
        assert client.get("/api/v1/food-therapy/nonexistent_recipe").status_code == 404


class TestFoodTherapyRecommend:
    def test_recommend_returns_200(self, client):
        payload = {"constitution": "qi_deficiency", "season": "spring"}
        response = client.post("/api/v1/food-therapy/recommend", json=payload)
        assert response.status_code == 200

    def test_recommend_has_recipes(self, client):
        payload = {"constitution": "yin_deficiency"}
        data = client.post("/api/v1/food-therapy/recommend", json=payload).json()
        assert "recipes" in data["data"]


class TestFoodTherapyCategories:
    def test_categories_returns_200(self, client):
        response = client.get("/api/v1/food-therapy/categories/list")
        assert response.status_code == 200

    def test_categories_not_empty(self, client):
        data = client.get("/api/v1/food-therapy/categories/list").json()
        assert data["success"] is True
