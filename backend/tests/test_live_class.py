"""顺时 - 直播课测试"""
import pytest


class TestLiveClassList:
    def test_list_returns_200(self, client):
        response = client.get("/api/v1/live-class/list")
        assert response.status_code == 200

    def test_list_has_classes(self, client):
        data = client.get("/api/v1/live-class/list").json()
        assert "classes" in data["data"]
        assert data["success"] is True

    def test_list_filter_by_type(self, client):
        response = client.get("/api/v1/live-class/list?class_type=live")
        assert response.status_code == 200


class TestLiveClassDetail:
    def test_valid_class_returns_200(self, client):
        response = client.get("/api/v1/live-class/class_001")
        assert response.status_code == 200

    def test_invalid_class_returns_404(self, client):
        assert client.get("/api/v1/live-class/nonexistent_class").status_code == 404


class TestLiveClassBook:
    def test_book_class_returns_200(self, client):
        payload = {"user_id": "test_user"}
        response = client.post("/api/v1/live-class/class_001/book", json=payload)
        assert response.status_code == 200

    def test_book_class_success(self, client):
        payload = {"user_id": "test_user"}
        data = client.post("/api/v1/live-class/class_002/book", json=payload).json()
        assert data["success"] is True


class TestLiveClassBookings:
    def test_my_bookings_returns_200(self, client):
        response = client.get("/api/v1/live-class/bookings/test_user")
        assert response.status_code == 200

    def test_bookings_has_list(self, client):
        data = client.get("/api/v1/live-class/bookings/test_user").json()
        assert "bookings" in data["data"]


class TestLiveClassCategories:
    def test_categories_returns_200(self, client):
        response = client.get("/api/v1/live-class/categories/list")
        assert response.status_code == 200


class TestLiveClassUpcoming:
    def test_upcoming_returns_200(self, client):
        response = client.get("/api/v1/live-class/upcoming/schedule")
        assert response.status_code == 200
