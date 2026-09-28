import json
import pytest
from app.security import verify_token
from app.simple_models import UserSetting


def test_preferences_are_persisted_and_private(client, auth_headers, settings):
    owner = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
    response = client.post("/api/v1/push/preferences", headers=auth_headers, json={"user_id": owner, "language": "en", "focus_areas": ["睡眠"], "push_frequency": "minimal"})
    assert response.status_code == 200
    assert response.json()["preferences"]["language"] == "cn"
    # A fresh database session proves this is not only a process dictionary.
    with client.app.state.session_factory() as session:
        row = session.get(UserSetting, {"user_id": owner, "key": "settings:push"})
        assert json.loads(row.value)["focus_areas"] == ["睡眠"]
    assert client.get("/api/v1/push/preferences", headers=auth_headers).json()["push_frequency"] == "minimal"
    assert client.get(f"/api/v1/push/preferences?user_id={owner}").status_code == 401
    other = client.post("/api/v1/auth/guest-login", json={}).json()["access_token"]
    stranger = {"Authorization": "Bearer " + other}
    assert client.get(f"/api/v1/push/preferences?user_id={owner}", headers=stranger).status_code == 403
    assert client.post("/api/v1/push/preferences", headers=stranger, json={"user_id": owner}).status_code == 403


@pytest.mark.parametrize("period", ["morning", "noon", "afternoon", "evening", "night", "daily"])
def test_domestic_push_stays_chinese(client, auth_headers, period):
    response = client.get(f"/api/v1/push/{period}?lang=gl", headers=auth_headers)
    assert response.status_code == 200
    assert any("\u4e00" <= char <= "\u9fff" for char in response.json()["title"])


@pytest.mark.parametrize("invalid", [{"quiet_hours_start": "25:30"}, {"quiet_hours_end": "08:99"}, {"push_frequency": "spam"}])
def test_invalid_preferences_rejected(client, auth_headers, invalid):
    assert client.post("/api/v1/push/preferences", headers=auth_headers, json=invalid).status_code == 422
