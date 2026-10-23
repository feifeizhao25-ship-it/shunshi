"""对话必须让用户随时知道「这是 AI、不是真人」。

依据《人工智能拟人化互动服务管理暂行办法》（2026-07-15 施行）与顺时红线：
AI 生成内容必须有显式标识（「AI 生成」）且不得删除、隐藏；对话界面要有
「你在和人工智能对话，不是真人」的常驻提示。

客户端拿不到就没法显示，所以每个对话出口的响应都要带这两项，正常回答与危机回答一样。
"""

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module

LABEL = "AI 生成"
NOTICE = "你在和人工智能对话，不是真人"


@pytest.fixture()
def chat_client(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"

    async def fake_gateway(url, payload, tier=None):
        return "先从一件今天能完成的小事开始。"

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        yield client, {"Authorization": f"Bearer {login.json()['access_token']}"}


PATHS = ["/api/v1/chat/send", "/api/v1/ai/chat", "/ai/chat"]


def _assert_disclosed(body):
    assert body["ai_generated"] is True
    assert body["ai_label"] == LABEL
    assert NOTICE in body["ai_notice"]


@pytest.mark.parametrize("path", PATHS)
def test_normal_answer_carries_ai_label_and_identity_notice(chat_client, path):
    client, headers = chat_client
    response = client.post(path, headers=headers, json={"message": "我昨晚没睡好"})
    assert response.status_code == 200
    _assert_disclosed(response.json())


@pytest.mark.parametrize("path", PATHS)
def test_crisis_answer_also_carries_them(chat_client, path):
    client, headers = chat_client
    response = client.post(path, headers=headers, json={"message": "我不想活了"})
    assert response.status_code == 200
    body = response.json()
    assert body["care_status"] == "crisis"
    _assert_disclosed(body)


def test_medical_boundary_answer_also_carries_them(chat_client):
    client, headers = chat_client
    response = client.post("/api/v1/chat/send", headers=headers, json={"message": "给我开药"})
    assert response.status_code == 200
    assert response.json()["safety_flag"] == "medical_boundary"
    _assert_disclosed(response.json())


def test_legacy_envelope_and_history_keep_the_label(chat_client):
    """/api/v1/chat 的信封与会话历史里的助手消息，同样不能丢标识。"""
    client, headers = chat_client
    sent = client.post("/api/v1/chat", headers=headers, json={"message": "今天想早点睡"})
    assert sent.status_code == 200
    data = sent.json()["data"]
    _assert_disclosed(data)
    history = client.get(f"/api/v1/chat/history/{data['conversation_id']}", headers=headers)
    assistant = [m for m in history.json()["data"]["items"] if m["role"] == "assistant"]
    assert assistant and all(m["ai_generated"] is True and m["ai_label"] == LABEL for m in assistant)
    detail = client.get(f"/api/v1/chat/conversations/{data['conversation_id']}", headers=headers)
    assert all(m["ai_generated"] for m in detail.json()["data"]["messages"] if m["role"] == "assistant")
