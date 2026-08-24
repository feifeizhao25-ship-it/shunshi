"""反思记录：未登录 401；提交→列表闭环。"""


def test_create_reflection_requires_auth(client):
    response = client.post("/api/v1/reflections", json={"mood": "calm", "notes": "今天不错"})
    assert response.status_code == 401


def test_list_reflections_requires_auth(client):
    assert client.get("/api/v1/reflections").status_code == 401


def test_create_and_list_reflections(client, auth_headers):
    body = {
        "mood": "calm",
        "question": "今天最值得感恩的一件事？",
        "notes": "睡了个好觉",
        "recorded_at": "2026-08-23T02:00:00+00:00",
    }
    created = client.post("/api/v1/reflections", json=body, headers=auth_headers)
    assert created.status_code == 200
    assert created.json()["saved"] is True
    assert created.json()["id"]

    listed = client.get("/api/v1/reflections", headers=auth_headers)
    assert listed.status_code == 200
    items = listed.json()["items"]
    assert len(items) == 1
    assert items[0]["mood"] == "calm"
    assert items[0]["notes"] == "睡了个好觉"
    assert items[0]["recorded_at"] == "2026-08-23T02:00:00+00:00"


def test_create_reflection_rejects_empty_mood(client, auth_headers):
    response = client.post("/api/v1/reflections", json={"mood": ""}, headers=auth_headers)
    assert response.status_code == 422
