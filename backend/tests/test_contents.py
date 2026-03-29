"""
顺时 - 内容系统测试
test_contents.py
"""

import pytest


class TestContentList:
    """内容列表测试"""

    def test_get_all_contents(self, client):
        response = client.get("/api/v1/contents")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "items" in data["data"]
        assert "total" in data["data"]
        # 种子数据至少有几条
        assert data["data"]["total"] > 0

    def test_get_contents_with_pagination(self, client):
        response = client.get("/api/v1/contents?limit=5&page=1")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["items"]) <= 5

    def test_get_contents_empty_page(self, client):
        response = client.get("/api/v1/contents?limit=5&page=9999")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["items"]) == 0


class TestContentFilter:
    """内容筛选测试"""

    def test_filter_by_type_recipe(self, client):
        response = client.get("/api/v1/contents?type=recipe")
        assert response.status_code == 200
        data = response.json()
        for item in data["data"]["items"]:
            assert item["type"] == "recipe"

    def test_filter_by_type_acupoint(self, client):
        response = client.get("/api/v1/contents?type=acupoint")
        assert response.status_code == 200
        data = response.json()
        for item in data["data"]["items"]:
            assert item["type"] == "acupoint"

    def test_filter_by_type_exercise(self, client):
        response = client.get("/api/v1/contents?type=exercise")
        assert response.status_code == 200
        data = response.json()
        for item in data["data"]["items"]:
            assert item["type"] == "exercise"

    def test_filter_by_type_tips(self, client):
        response = client.get("/api/v1/contents?type=tips")
        assert response.status_code == 200
        data = response.json()
        for item in data["data"]["items"]:
            assert item["type"] == "tips"

    def test_filter_by_type_solar_term(self, client):
        response = client.get("/api/v1/contents?type=solar_term")
        assert response.status_code == 200
        data = response.json()
        for item in data["data"]["items"]:
            assert item["type"] == "solar_term"

    def test_filter_by_type_nonexistent(self, client):
        response = client.get("/api/v1/contents?type=nonexistent_type")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["items"]) == 0


class TestContentSearch:
    """内容搜索测试"""

    def test_search_by_title(self, client):
        response = client.get("/api/v1/contents/search?q=枸杞")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] >= 1

    def test_search_by_description(self, client):
        response = client.get("/api/v1/contents/search?q=养生功法")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] >= 1

    def test_search_no_results(self, client):
        response = client.get("/api/v1/contents/search?q=量子力学黑洞")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total"] == 0


class TestContentDetail:
    """内容详情测试"""

    def test_get_content_by_id(self, client):
        response = client.get("/api/v1/contents/food-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["id"] == "food-001"
        assert data["data"]["title"] == "枸杞菊花茶"

    def test_get_content_404(self, client):
        response = client.get("/api/v1/contents/nonexistent-id")
        assert response.status_code == 404
