"""顺时 - 本草知识测试"""
import pytest


class TestHerbalList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/herbal/list")
        assert response.status_code == 200

    def test_list_has_herbs(self, client):
        data = client.get("/api/v1/herbal/list").json()
        assert "herbs" in data["data"]
        assert len(data["data"]["herbs"]) > 0


class TestHerbalSearch:
    def test_search_returns_200(self, client):
        response = client.get("/api/v1/herbal/search?q=枸杞")
        assert response.status_code == 200

    def test_search_has_results(self, client):
        data = client.get("/api/v1/herbal/search?q=枸杞").json()
        assert "results" in data["data"]


class TestHerbalDetail:
    def test_valid_id_returns_200(self, client):
        response = client.get("/api/v1/herbal/goji")
        assert response.status_code == 200

    def test_invalid_id_returns_404(self, client):
        assert client.get("/api/v1/herbal/not_a_herb").status_code == 404


class TestHerbalPairs:
    def test_pairs_returns_200(self, client):
        response = client.get("/api/v1/herbal/goji/pairs")
        assert response.status_code == 200

    def test_pairs_has_combinations(self, client):
        data = client.get("/api/v1/herbal/goji/pairs").json()
        assert "data" in data


class TestHerbalByFunction:
    def test_by_function_returns_200(self, client):
        response = client.get("/api/v1/herbal/by-function/补气")
        assert response.status_code == 200
