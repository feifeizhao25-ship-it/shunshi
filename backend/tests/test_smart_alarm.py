"""顺时 - 智能闹钟测试"""
import pytest
from app.security import verify_token


class TestSmartAlarmRecommend:
    def test_recommend_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        response = client.get("/api/v1/smart-alarm/recommend?constitution=qi_deficiency")
        assert response.status_code == 200

    def test_recommend_has_alarms(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        data = client.get("/api/v1/smart-alarm/recommend").json()
        assert "data" in data
        assert data["success"] is True


class TestSmartAlarmCreate:
    def test_create_alarm_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        payload = {"user_id": actor, "time": "07:00", "type": "wake_up", "days": ["mon", "tue"]}
        response = client.post("/api/v1/smart-alarm/", json=payload)
        assert response.status_code == 200

    def test_create_alarm_has_id(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        payload = {"user_id": actor, "time": "22:00", "type": "sleep"}
        data = client.post("/api/v1/smart-alarm/", json=payload).json()
        assert data["success"] is True
        assert "alarm_id" in data["data"]


class TestSmartAlarmList:
    def test_user_alarms_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        response = client.get(f"/api/v1/smart-alarm/user/{actor}")
        assert response.status_code == 200

    def test_user_alarms_has_list(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        data = client.get(f"/api/v1/smart-alarm/user/{actor}").json()
        assert "alarms" in data["data"]


class TestSmartAlarmUpdate:
    def test_update_alarm_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        # Create first
        create_data = client.post("/api/v1/smart-alarm/",
                                  json={"user_id": actor, "time": "07:30", "type": "wake_up"}).json()
        alarm_id = create_data["data"]["alarm_id"]
        response = client.put(f"/api/v1/smart-alarm/user/{actor}/alarm/{alarm_id}",
                              json={"time": "08:00", "enabled": True})
        assert response.status_code == 200


class TestSmartAlarmDelete:
    def test_delete_alarm_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        create_data = client.post("/api/v1/smart-alarm/",
                                  json={"user_id": actor, "time": "06:00", "type": "wake_up"}).json()
        alarm_id = create_data["data"]["alarm_id"]
        response = client.delete(f"/api/v1/smart-alarm/user/{actor}/alarm/{alarm_id}")
        assert response.status_code == 200


class TestSmartAlarmSounds:
    def test_sounds_returns_200(self, client, auth_headers, settings):
        client.headers.update(auth_headers)
        actor = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
        response = client.get("/api/v1/smart-alarm/sounds")
        assert response.status_code == 200
