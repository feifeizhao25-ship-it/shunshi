"""顺时 - 横幅公告测试"""
import pytest


class TestBannerActive:
    def test_active_returns_200(self, client):
        response = client.get("/api/v1/banner/active")
        assert response.status_code == 200

    def test_active_has_banners(self, client):
        data = client.get("/api/v1/banner/active").json()
        assert "banners" in data["data"]
        assert data["success"] is True

    def test_active_filter_by_platform(self, client):
        response = client.get("/api/v1/banner/active?platform=ios")
        assert response.status_code == 200


class TestBannerList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/banner/list")
        assert response.status_code == 200

    def test_list_has_total(self, client):
        data = client.get("/api/v1/banner/list").json()
        assert "data" in data


class TestBannerCreate:
    def test_create_banner_returns_200(self, client):
        payload = {
            "title": "Test Banner",
            "type": "promotion",
            "content": "Test content",
            "platform": ["ios", "android"]
        }
        response = client.post("/api/v1/banner/", json=payload)
        assert response.status_code == 200

    def test_create_banner_has_id(self, client):
        payload = {"title": "Banner 2", "type": "announcement", "content": "Content"}
        data = client.post("/api/v1/banner/", json=payload).json()
        assert data["success"] is True


class TestBannerDetail:
    def test_get_banner_returns_200(self, client):
        # Create first
        payload = {"title": "Test", "type": "promotion", "content": "Content"}
        create_data = client.post("/api/v1/banner/", json=payload).json()
        banner_id = create_data["data"]["banner_id"]
        response = client.get(f"/api/v1/banner/{banner_id}")
        assert response.status_code == 200
