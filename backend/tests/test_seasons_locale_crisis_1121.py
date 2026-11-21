"""2026-11-21 真实模型 UI 测试回归（SEASONS）：

- POST /api/v1/chat 忽略 locale：5/5 英文用户拿到中文回答，阿联酋用户拿到 12356 和北京热线；
- 'I feel hopeless and want to end it all' 只算情绪困扰，没进危机流程；
- 阿联酋没有本地资源。国内版行为不变（12356 仍在）。
"""
import re

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module
from app.safety import crisis_resources
from app.safety.guard import SafetyLevel, safety_guard

CJK = re.compile(r"[\u4e00-\u9fff]")
GL_AE = {"X-App-Market": "global", "Accept-Language": "en-AE", "X-Region": "AE"}


@pytest.fixture()
def app_client(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"
    captured = []

    async def fake_gateway(url, payload, tier=None):
        captured.append(payload)
        return "Keep a steady bedtime and get some morning light."

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        token = client.post("/api/v1/auth/guest-login").json()["access_token"]
        yield client, {"Authorization": f"Bearer {token}"}, captured


def _text(resp):
    body = resp.json()
    return (body.get("data") or body)["text"]


def test_v1_chat_honours_global_locale(app_client):
    client, auth, captured = app_client
    resp = client.post("/api/v1/chat", headers={**auth, **GL_AE}, json={"message": "How can I sleep better in winter?"})
    assert resp.status_code == 200
    assert captured[-1]["market"] == "global"
    assert not CJK.search(captured[-1]["messages"][0]["content"])
    assert resp.json()["data"]["locale"]["region"] == "AE"


def test_v1_chat_domestic_unchanged(app_client):
    client, auth, captured = app_client
    resp = client.post("/api/v1/chat", headers=auth, json={"message": "冬天怎么睡得更好？"})
    assert resp.status_code == 200
    assert captured[-1]["market"] == "cn"
    assert resp.json()["data"]["locale"]["market"] == "cn"


@pytest.mark.parametrize("phrase", [
    "I feel hopeless and want to end it all",
    "I just want to end it",
    "I don\u2019t want to be alive anymore",
    "there's no point in living",
    "I want to go to sleep and never wake up",
])
def test_english_crisis_phrases_enter_crisis_flow(phrase):
    assert safety_guard.check_input(phrase, {"user_id": "t", "lang": "cn"}).level == SafetyLevel.CRISIS


@pytest.mark.parametrize("path", ["/api/v1/chat", "/api/v1/chat/send"])
def test_uae_crisis_gets_local_lines_not_china(app_client, path):
    client, auth, captured = app_client
    resp = client.post(path, headers={**auth, **GL_AE}, json={"message": "I feel hopeless and want to end it all"})
    text = _text(resp)
    assert "800-HOPE" in text and "999" in text and "998" in text
    assert "12356" not in text and not CJK.search(text)
    assert captured == [], "crisis replies must not call the model"


def test_unknown_region_falls_back_to_directory():
    text = crisis_resources.crisis_reply_en("BR")
    assert "findahelpline.com" in text and "800-HOPE" not in text


def test_domestic_crisis_still_lists_12356(app_client):
    client, auth, captured = app_client
    text = _text(client.post("/api/v1/chat", headers=auth, json={"message": "我不想活了"}))
    assert "12356" in text
    assert captured == []
