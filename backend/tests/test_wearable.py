"""顺时 - 可穿戴设备测试"""
import pytest


class TestWearableDevices:
    def test_devices_returns_200(self, client):
        response = client.get("/api/v1/wearable/devices")
        assert response.status_code == 200

    def test_devices_has_list(self, client):
        data = client.get("/api/v1/wearable/devices").json()
        assert "devices" in data["data"]
        assert len(data["data"]["devices"]) > 0

    def test_devices_include_apple_watch(self, client):
        data = client.get("/api/v1/wearable/devices").json()
        device_ids = [d["id"] for d in data["data"]["devices"]]
        assert "apple_watch" in device_ids


class TestWearableConnect:
    def test_connect_valid_device(self, client):
        payload = {"user_id": "test_user", "device_id": "apple_watch"}
        response = client.post("/api/v1/wearable/connect", json=payload)
        assert response.status_code == 200

    def test_connect_has_confirmation(self, client):
        payload = {"user_id": "test_user", "device_id": "xiaomi_band"}
        data = client.post("/api/v1/wearable/connect", json=payload).json()
        assert data["success"] is True

    def test_connect_invalid_device_returns_404(self, client):
        payload = {"user_id": "test_user", "device_id": "nonexistent_device"}
        assert client.post("/api/v1/wearable/connect", json=payload).status_code == 404


class TestWearableConnectedDevice:
    def test_connected_returns_200(self, client):
        # Connect first
        client.post("/api/v1/wearable/connect",
                    json={"user_id": "test_user", "device_id": "apple_watch"})
        response = client.get("/api/v1/wearable/connected/test_user")
        assert response.status_code == 200

    def test_connected_has_is_connected(self, client):
        data = client.get("/api/v1/wearable/connected/test_user").json()
        assert "is_connected" in data["data"]


class TestWearableSync:
    def test_sync_data_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "device_id": "apple_watch",
            "date": "2024-01-01",
            "heart_rate_avg": 72.0,
            "heart_rate_resting": 65.0,
            "steps": 8500,
            "sleep_hours": 7.5,
            "spo2_avg": 98.0
        }
        response = client.post("/api/v1/wearable/sync", json=payload)
        assert response.status_code == 200

    def test_sync_has_tcm_insights(self, client):
        payload = {
            "user_id": "test_user",
            "device_id": "huawei_watch",
            "date": "2024-01-02",
            "heart_rate_resting": 90.0
        }
        data = client.post("/api/v1/wearable/sync", json=payload).json()
        assert "tcm_insights" in data["data"]


class TestWearableHistory:
    def test_history_returns_200(self, client):
        response = client.get("/api/v1/wearable/history/test_user")
        assert response.status_code == 200

    def test_history_has_list(self, client):
        data = client.get("/api/v1/wearable/history/test_user?days=7").json()
        assert "history" in data["data"]


class TestWearableTodaySummary:
    def test_today_summary_returns_200(self, client):
        response = client.get("/api/v1/wearable/today-summary/test_user")
        assert response.status_code == 200
