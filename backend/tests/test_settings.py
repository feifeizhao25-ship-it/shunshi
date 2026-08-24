"""通知/免打扰设置：未登录 401；默认值空态；保存→读取闭环。"""

QUIET_BODY = {"enabled": True, "start_time": "22:30", "end_time": "07:00"}


def test_notification_settings_require_auth(client):
    assert client.get("/api/v1/notifications/settings").status_code == 401
    assert client.post("/api/v1/notifications/settings", json={}).status_code == 401


def test_notification_settings_default(client, auth_headers):
    response = client.get("/api/v1/notifications/settings", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"push_enabled": True, "time_slots": {}, "preferences": {}}


def test_notification_settings_roundtrip(client, auth_headers):
    body = {
        "push_enabled": False,
        "time_slots": {"morning": True, "evening": False},
        "preferences": {"weekly_report": True},
    }
    saved = client.post("/api/v1/notifications/settings", json=body, headers=auth_headers)
    assert saved.status_code == 200
    assert saved.json() == body
    loaded = client.get("/api/v1/notifications/settings", headers=auth_headers)
    assert loaded.json() == body


def test_quiet_hours_require_auth(client):
    assert client.get("/api/v1/settings/quiet-hours").status_code == 401
    assert client.post("/api/v1/settings/quiet-hours", json=QUIET_BODY).status_code == 401
    assert client.put("/api/v1/settings/quiet-hours", json=QUIET_BODY).status_code == 401


def test_quiet_hours_default(client, auth_headers):
    response = client.get("/api/v1/settings/quiet-hours", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"enabled": False, "start_time": None, "end_time": None}


def test_quiet_hours_post_roundtrip(client, auth_headers):
    saved = client.post("/api/v1/settings/quiet-hours", json=QUIET_BODY, headers=auth_headers)
    assert saved.status_code == 200
    assert saved.json() == QUIET_BODY
    loaded = client.get("/api/v1/settings/quiet-hours", headers=auth_headers)
    assert loaded.json() == QUIET_BODY


def test_quiet_hours_put_alias(client, auth_headers):
    saved = client.put("/api/v1/settings/quiet-hours", json=QUIET_BODY, headers=auth_headers)
    assert saved.status_code == 200
    loaded = client.get("/api/v1/settings/quiet-hours", headers=auth_headers)
    assert loaded.json() == QUIET_BODY


def test_quiet_hours_rejects_bad_time_format(client, auth_headers):
    bad = {"enabled": True, "start_time": "十点半", "end_time": "07:00"}
    assert client.post("/api/v1/settings/quiet-hours", json=bad, headers=auth_headers).status_code == 422
