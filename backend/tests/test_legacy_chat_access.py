"""Mounted compatibility API authorization regressions."""
import pytest
from app.router.chat import conversations_db
from app.routers import chat as canonical

@pytest.mark.parametrize("method,path", [("post", "/api/v1/chat"), ("get", "/api/v1/chat/conversations"), ("get", "/api/v1/chat/conversations/fixture"), ("get", "/api/v1/chat/history/fixture"), ("delete", "/api/v1/chat/conversations/fixture")])
def test_requires_login(client, method, path):
    assert getattr(client, method)(path, params={"user_id": "victim", "message": "你好"}).status_code == 401


def test_two_users_cannot_impersonate(client, auth_headers, settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fixture-gateway"
    calls = []
    async def gateway(url, payload, tier=None):
        calls.append((payload, tier))
        return "今天先做一件小事。"
    monkeypatch.setattr(canonical, "request_gateway", gateway)
    other = client.post("/api/v1/auth/guest-login", json={}).json()
    headers = {"Authorization": "Bearer " + other["access_token"]}
    response = client.post("/api/v1/chat", headers=auth_headers, json={"message": "你好", "user_id": "fake-paid-id"})
    assert response.status_code == 200
    conversation = response.json()["data"]["conversation_id"]
    owner = calls[0][0]["user_id"]
    assert owner != "fake-paid-id"
    assert calls[0][1] == "free"
    try:
        for path in (f"/api/v1/chat/conversations/{conversation}", f"/api/v1/chat/history/{conversation}"):
            assert client.get(path, headers=auth_headers).status_code == 200
            denied = client.get(path, headers=headers, params={"user_id": owner})
            assert denied.status_code in (403, 404)
            assert "今天先做" not in denied.text
        assert conversation not in client.get("/api/v1/chat/conversations", headers=headers, params={"user_id": owner}).text
        assert client.delete(f"/api/v1/chat/conversations/{conversation}", headers=headers, params={"user_id": owner}).status_code == 403
        before = len(conversations_db[conversation]["messages"])
        denied = client.post("/api/v1/chat", headers=headers, json={"message": "你好", "user_id": owner, "conversation_id": conversation})
        assert denied.status_code == 404
        assert len(calls) == 1
        assert len(conversations_db[conversation]["messages"]) == before
        stored_ids = list(conversations_db[conversation]["stored_message_ids"])
        assert len(stored_ids) == 2
        from app.simple_models import Message
        with client.app.state.session_factory() as session:
            assert all(session.get(Message, key) is not None for key in stored_ids)
        assert client.delete(f"/api/v1/chat/conversations/{conversation}", headers=auth_headers).status_code == 200
        with client.app.state.session_factory() as session:
            assert all(session.get(Message, key) is None for key in stored_ids)
    finally:
        conversations_db.pop(conversation, None)


def test_no_fake_success(client, auth_headers):
    assert client.post("/api/v1/chat", headers=auth_headers, params={"message": "你好"}).status_code == 503


def test_crisis_without_gateway(client, auth_headers):
    response = client.post("/api/v1/chat", headers=auth_headers, json={"message": "我想自杀"})
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["safety_flag"] == "crisis"
    assert "12356" in data["text"]
    conversations_db.pop(data["conversation_id"], None)


@pytest.mark.parametrize("as_json", [True, False])
def test_oversized_message_rejected(client, auth_headers, as_json):
    args = {"json" if as_json else "params": {"message": "字" * 4001}}
    assert client.post("/api/v1/chat", headers=auth_headers, **args).status_code == 422
