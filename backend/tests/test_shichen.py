"""顺时 - 十二时辰养生测试"""
import pytest


class TestShichenCurrent:
    def test_current_returns_200(self, client):
        response = client.get("/api/v1/shichen/current")
        assert response.status_code == 200

    def test_current_has_data(self, client):
        response = client.get("/api/v1/shichen/current")
        data = response.json()
        assert "data" in data
        assert "shichen_name" in data["data"]

    def test_current_success_true(self, client):
        response = client.get("/api/v1/shichen/current")
        assert response.json()["success"] is True


class TestShichenList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/shichen/list")
        assert response.status_code == 200

    def test_list_has_12_periods(self, client):
        response = client.get("/api/v1/shichen/list")
        data = response.json()
        assert "shichen_list" in data["data"]
        assert len(data["data"]["shichen_list"]) == 12


class TestShichenDetail:
    def test_valid_code_returns_200(self, client):
        response = client.get("/api/v1/shichen/zi")
        assert response.status_code == 200

    def test_valid_code_has_organ(self, client):
        response = client.get("/api/v1/shichen/zi")
        data = response.json()
        assert "organ" in data["data"]

    def test_invalid_code_returns_404(self, client):
        response = client.get("/api/v1/shichen/invalid_code")
        assert response.status_code == 404


class TestShichenWellness:
    def test_wellness_returns_200(self, client):
        response = client.get("/api/v1/shichen/zi/wellness")
        assert response.status_code == 200

    def test_wellness_has_advice(self, client):
        response = client.get("/api/v1/shichen/wu/wellness")
        data = response.json()
        assert "data" in data
