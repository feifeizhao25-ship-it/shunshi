"""对话模块：网关未配置 fail-closed 503；配置后代理到 /v1/scene/complete 并按客户端格式解包。"""

import asyncio

import httpx
import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module


def test_chat_fail_closed_when_gateway_unconfigured(client, auth_headers):
    for path in ("/api/v1/chat/send", "/api/v1/ai/chat"):
        response = client.post(path, headers=auth_headers, json={"message": "我昨晚没睡好"})
        assert response.status_code == 503
        assert response.json()["detail"]["configured"] is False


@pytest.fixture()
def gateway_client(settings, monkeypatch):
    settings.model_router_url = "http://fake-gateway"
    captured = {}

    async def fake_gateway(url, payload, tier=None):
        captured["url"] = url
        captured["payload"] = payload
        captured["tier"] = tier
        return "先从一件今天能完成的小事开始。"

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        yield client, headers, captured


def test_chat_send_contract_via_api_service(gateway_client):
    client, headers, captured = gateway_client
    # ApiService.chat：body {"user_id", "message"}，响应取整个 map 并读 content/message
    response = client.post(
        "/api/v1/chat/send",
        headers=headers,
        json={"user_id": "u1", "message": "我昨晚没睡好"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["content"] == "先从一件今天能完成的小事开始。"
    assert body["message"] == body["content"]
    # 网关契约：scene 路由，messages 携带 system prompt + 用户原文
    payload = captured["payload"]
    assert payload["scene"] == "chat"
    assert payload["market"] == "cn"
    assert payload["messages"][0]["role"] == "system"
    assert payload["messages"][-1] == {"role": "user", "content": "我昨晚没睡好"}
    assert payload["user_id"]  # JWT 里的用户 id，而非客户端自报的 "u1"
    # 未显式给 model_tier 时按 free 档传给网关（经 X-Membership-Tier 头）
    assert captured["tier"] == "free"


def test_ai_chat_contract_via_shunshi_router(gateway_client):
    client, headers, captured = gateway_client
    # ShunShiRouter._callLLM：body {"user_input", "intent", "context", "prompt", "model_tier"}
    response = client.post(
        "/api/v1/ai/chat",
        headers=headers,
        json={
            "user_input": "最近总是失眠",
            "intent": "emotion_support",
            "context": {"current_season": "winter"},
            "prompt": "系统提示词",
            "model_tier": "premium",
        },
    )
    assert response.status_code == 200
    assert response.json()["content"]
    # 客户端已组装完整 prompt 时以它为准作为 system 消息
    assert captured["payload"]["messages"] == [
        {"role": "system", "content": "系统提示词"},
        {"role": "user", "content": "最近总是失眠"},
    ]
    assert captured["tier"] == "premium"


def test_chat_requires_auth(client):
    assert client.post("/api/v1/chat/send", json={"message": "hi"}).status_code == 401


# ── request_gateway 的错误映射与真实解包 ──────────────────────────────


class _FakeResponse:
    def __init__(self, status_code=200, payload=None, raw_text=""):
        self.status_code = status_code
        self._payload = payload
        self.text = raw_text

    def json(self):
        if self._payload is None:
            raise ValueError("not json")
        return self._payload


def test_request_gateway_posts_scene_complete_with_tier_header(monkeypatch):
    sent = {}

    class FakeClient:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def post(self, url, json=None, headers=None):
            sent["url"] = url
            sent["json"] = json
            sent["headers"] = headers
            return _FakeResponse(
                200,
                {"text": "你好，我是顺时。", "provider": "deepseek", "model": "deepseek-chat"},
            )

    monkeypatch.setattr(chat_module.httpx, "AsyncClient", FakeClient)
    text = asyncio.run(
        chat_module.request_gateway(
            "http://gw:8600/", {"scene": "chat", "messages": []}, tier="free"
        )
    )
    assert text == "你好，我是顺时。"
    assert sent["url"] == "http://gw:8600/v1/scene/complete"
    assert sent["headers"] == {"X-Membership-Tier": "free"}


def test_request_gateway_forwards_429_and_503(monkeypatch):
    for status in (429, 503):
        class FakeClient:
            def __init__(self, **kwargs):
                pass

            async def __aenter__(self):
                return self

            async def __aexit__(self, *args):
                return False

            async def post(self, url, json=None, headers=None):
                return _FakeResponse(status, {"detail": "boom", "code": "X"})

        monkeypatch.setattr(chat_module.httpx, "AsyncClient", FakeClient)
        with pytest.raises(chat_module.HTTPException) as exc_info:
            asyncio.run(chat_module.request_gateway("http://gw", {"scene": "chat"}))
        assert exc_info.value.status_code == status
        assert exc_info.value.detail["gateway_status"] == status
        assert exc_info.value.detail["gateway_detail"]["code"] == "X"


def test_request_gateway_maps_other_errors_to_502(monkeypatch):
    class FakeClient:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def post(self, url, json=None, headers=None):
            return _FakeResponse(400, {"detail": "Unknown scene"})

    monkeypatch.setattr(chat_module.httpx, "AsyncClient", FakeClient)
    with pytest.raises(chat_module.HTTPException) as exc_info:
        asyncio.run(chat_module.request_gateway("http://gw", {"scene": "chat"}))
    assert exc_info.value.status_code == 502
    assert exc_info.value.detail["gateway_status"] == 400


def test_request_gateway_unreachable_maps_to_502(monkeypatch):
    class FakeClient:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def post(self, url, json=None, headers=None):
            raise httpx.ConnectError("refused")

    monkeypatch.setattr(chat_module.httpx, "AsyncClient", FakeClient)
    with pytest.raises(chat_module.HTTPException) as exc_info:
        asyncio.run(chat_module.request_gateway("http://gw", {"scene": "chat"}))
    assert exc_info.value.status_code == 502
    assert exc_info.value.detail["gateway"] == "unreachable"


def test_request_gateway_rejects_empty_content(monkeypatch):
    class FakeClient:
        def __init__(self, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def post(self, url, json=None, headers=None):
            return _FakeResponse(200, {"text": "   "})

    monkeypatch.setattr(chat_module.httpx, "AsyncClient", FakeClient)
    with pytest.raises(chat_module.HTTPException) as exc_info:
        asyncio.run(chat_module.request_gateway("http://gw", {"scene": "chat"}))
    assert exc_info.value.status_code == 502
