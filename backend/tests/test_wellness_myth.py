"""顺时 - 养生误区测试"""
import pytest


class TestWellnessMythList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/wellness-myth/list")
        assert response.status_code == 200

    def test_list_has_myths(self, client):
        data = client.get("/api/v1/wellness-myth/list").json()
        assert "myths" in data["data"]
        assert len(data["data"]["myths"]) > 0


class TestWellnessMythDetail:
    def test_valid_id_returns_200(self, client):
        response = client.get("/api/v1/wellness-myth/myth_001")
        assert response.status_code == 200

    def test_has_correction(self, client):
        data = client.get("/api/v1/wellness-myth/myth_001").json()
        assert "data" in data

    def test_invalid_id_returns_404(self, client):
        assert client.get("/api/v1/wellness-myth/nonexistent").status_code == 404


class TestWellnessMythCategories:
    def test_categories_returns_200(self, client):
        response = client.get("/api/v1/wellness-myth/categories/list")
        assert response.status_code == 200


class TestWellnessMythSearch:
    def test_search_returns_200(self, client):
        response = client.get("/api/v1/wellness-myth/search/query?q=排毒")
        assert response.status_code == 200

    def test_search_has_results_key(self, client):
        data = client.get("/api/v1/wellness-myth/search/query?q=排毒").json()
        assert "data" in data


class TestWellnessMythDailyTip:
    def test_daily_tip_returns_200(self, client):
        response = client.get("/api/v1/wellness-myth/daily/tip")
        assert response.status_code == 200

    def test_daily_tip_has_content(self, client):
        data = client.get("/api/v1/wellness-myth/daily/tip").json()
        assert data["success"] is True
