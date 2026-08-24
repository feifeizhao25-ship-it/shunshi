"""数据导出与账号注销：真实读写 DB，禁止假成功。"""

import jwt as pyjwt


def _user_id(settings, headers) -> str:
    return pyjwt.decode(
        headers["Authorization"][7:], settings.jwt_secret, algorithms=["HS256"]
    )["sub"]


def _seed_user_data(client, headers):
    client.post(
        "/api/v1/reflections",
        json={"mood": "calm", "question": "q", "notes": "导出完整性测试", "recorded_at": "2026-08-23T00:00:00Z"},
        headers=headers,
    )
    client.post("/api/v1/feedback", json={"content": "导出里的反馈"}, headers=headers)
    client.post("/api/v1/settings/memory", json={"enabled": True}, headers=headers)
    client.post(
        "/api/v1/seasons/audio/progress",
        json={"audio_id": "a9", "progress_seconds": 5, "completed": False},
        headers=headers,
    )


def test_export_requires_auth(client):
    assert client.post("/api/v1/auth/data/export").status_code == 401
    assert client.get("/api/v1/auth/data/export").status_code == 401


def test_export_contains_all_user_data(client, auth_headers):
    _seed_user_data(client, auth_headers)
    response = client.post("/api/v1/auth/data/export", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["product"] == "shunshi"
    assert data["user"]["is_guest"] is True
    assert data["settings"]["settings:memory"] == {"enabled": True}
    assert any(r["notes"] == "导出完整性测试" for r in data["reflections"])
    assert any(f["payload"]["content"] == "导出里的反馈" for f in data["feedback"])
    assert data["audio_progress"][0]["audio_id"] == "a9"


def test_export_get_alias(client, auth_headers):
    response = client.get("/api/v1/auth/data/export", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["product"] == "shunshi"


def test_cancel_delete_no_pending_state(client, auth_headers):
    response = client.post("/api/v1/auth/account/cancel-delete", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"pending_deletion": False, "cancelled": False}


def test_delete_account_requires_auth(client):
    assert client.delete("/api/v1/auth/account").status_code == 401


def test_delete_account_removes_everything(client, settings, auth_headers):
    _seed_user_data(client, auth_headers)
    user_id = _user_id(settings, auth_headers)

    deleted = client.delete("/api/v1/auth/account", headers=auth_headers)
    assert deleted.status_code == 200
    body = deleted.json()
    assert body["deleted"] is True
    assert body["deleted_rows"]["users"] == 1
    assert body["deleted_rows"]["reflections"] == 1
    assert body["deleted_rows"]["feedback"] == 1

    # 数据完整性：删除后导出应为全空（token 仍有效，但库内已无任何记录）
    exported = client.post("/api/v1/auth/data/export", headers=auth_headers).json()
    assert exported["user"] is None
    assert exported["settings"] == {}
    assert exported["messages"] == []
    assert exported["reflections"] == []
    assert exported["feedback"] == []
    assert exported["audio_progress"] == []
    assert exported["entitlement"] is None

    # 同一 user_id 不应再能被登录体系外的接口看到任何残留
    listed = client.get("/api/v1/reflections", headers=auth_headers).json()
    assert listed["items"] == []
