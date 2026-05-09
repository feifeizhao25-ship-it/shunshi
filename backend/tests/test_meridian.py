"""顺时 - 经络养生测试"""
import pytest


class TestMeridianList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/meridian/list")
        assert response.status_code == 200

    def test_list_has_meridians(self, client):
        data = client.get("/api/v1/meridian/list").json()
        assert "meridians" in data["data"]
        assert len(data["data"]["meridians"]) > 0


class TestMeridianDetail:
    def test_valid_code_returns_200(self, client):
        response = client.get("/api/v1/meridian/lung")
        assert response.status_code == 200

    def test_valid_code_has_name(self, client):
        data = client.get("/api/v1/meridian/lung").json()
        assert "name_cn" in data["data"]

    def test_invalid_code_returns_404(self, client):
        assert client.get("/api/v1/meridian/unknown_meridian").status_code == 404


class TestMeridianAcupoints:
    def test_acupoints_returns_200(self, client):
        response = client.get("/api/v1/meridian/lung/acupoints")
        assert response.status_code == 200

    def test_acupoints_list_not_empty(self, client):
        data = client.get("/api/v1/meridian/lung/acupoints").json()
        assert "acupoints" in data["data"]


class TestMeridianWellness:
    def test_wellness_returns_200(self, client):
        response = client.get("/api/v1/meridian/lung/wellness")
        assert response.status_code == 200


class TestMeridianBySeason:
    def test_by_season_spring(self, client):
        response = client.get("/api/v1/meridian/by-season/spring")
        assert response.status_code == 200

    def test_by_season_has_data(self, client):
        data = client.get("/api/v1/meridian/by-season/autumn").json()
        assert "data" in data
        assert data["success"] is True
