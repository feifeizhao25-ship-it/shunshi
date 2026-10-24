"""/api/v1/personalization/action/complete 以前不落库却回 recorded: True（假回执）。"""
import json

import pytest

pytestmark = pytest.mark.signed_in


def test_action_completion_is_really_stored(client):
    body = {"action_type": "breathing", "completed": True, "rating": 4, "note": "不保存的自由文本"}
    first = client.post("/api/v1/personalization/action/complete", json=body)
    assert first.status_code == 200, first.text
    second = client.post("/api/v1/personalization/action/complete", json={**body, "action_type": "walk"})
    assert second.json()["data"]["recorded"] is True
    assert second.json()["data"]["total_recorded"] == 2

    from app.simple_models import UserSetting

    session = client.app.state.session_factory()
    try:
        row = session.get(UserSetting, {"user_id": client.default_user_id, "key": "behavior:action_completions"})
        log = json.loads(row.value)
    finally:
        session.close()
    assert [item["action_type"] for item in log] == ["breathing", "walk"]
    assert all("note" not in item for item in log)  # 自由文本不留存


def test_action_completion_requires_login(anonymous_client):
    response = anonymous_client.post(
        "/api/v1/personalization/action/complete", json={"action_type": "walk", "completed": True}
    )
    assert response.status_code == 401
