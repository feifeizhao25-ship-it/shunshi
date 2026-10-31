"""语音对话（/api/v1/speech/chat-voice）必须和文字对话走同一套安全与合规链路。

原来这条路径自己直接调模型：不过安全守卫（语音说「不想活了」得到的是普通养生回答）、
不做输出拦截（可能读出剂量）、没有 AI 标识、不做年龄保护与额度，模型出错时还把原始异常文字放进响应。
"""

from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.router import speech as speech_module
from app.routers import chat as chat_module


class FakeSpeech:
    def __init__(self, transcript):
        self.transcript = transcript
        self.spoken = []
        self.languages = []

    async def speech_to_text(self, audio_data, model, filename, language=None):
        self.languages.append(language)
        return SimpleNamespace(text=self.transcript, latency_ms=1)

    async def text_to_speech(self, text, model, voice):
        self.spoken.append(text)
        return SimpleNamespace(format="mp3", audio_data=b"\x01\x02", latency_ms=1)


@pytest.fixture()
def env(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"
    state = {"calls": [], "answer": "今晚泡泡脚，早点休息。", "speech": None}

    async def fake_gateway(url, payload, tier=None):
        state["calls"].append(payload)
        return state["answer"]

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    monkeypatch.setattr(speech_module, "get_speech_service", lambda: state["speech"])
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        def talk(transcript, extra=None):
            state["speech"] = FakeSpeech(transcript)
            return client.post(
                "/api/v1/speech/chat-voice", headers={**headers, **(extra or {})},
                files={"file": ("a.wav", b"RIFFxxxx", "audio/wav")},
            )

        yield client, headers, talk, state


def test_normal_voice_reply_is_labelled_and_spoken(env):
    client, headers, talk, state = env
    response = talk("我今晚想早点睡")
    assert response.status_code == 200
    body = response.json()
    assert body["reply_text"] == "今晚泡泡脚，早点休息。"
    assert body["ai_generated"] is True and body["ai_label"] == "AI 生成"
    assert "不是真人" in body["ai_notice"]
    assert state["speech"].spoken == [body["reply_text"]]


def test_crisis_by_voice_gets_the_crisis_answer_and_never_reaches_the_model(env):
    client, headers, talk, state = env
    body = talk("我不想活了").json()
    assert "12356" in body["reply_text"]
    assert state["calls"] == []
    assert "12356" in state["speech"].spoken[0]


def test_dosage_in_model_answer_is_not_spoken(env):
    client, headers, talk, state = env
    state["answer"] = "黄芪每次9克，煎服。"
    body = talk("我想调理一下").json()
    assert "煎服" not in body["reply_text"]
    assert "煎服" not in state["speech"].spoken[0]


def test_under_14_is_refused_for_voice_too(env):
    client, headers, talk, state = env
    from datetime import date
    born = date.today().replace(year=date.today().year - 10).isoformat()
    client.post("/api/v1/settings/age-profile", headers=headers, json={"birth_date": born})
    response = talk("你好")
    assert response.status_code == 403
    assert state["calls"] == []


def test_voice_conversation_is_recorded_like_text_chat(env):
    client, headers, talk, state = env
    talk("我今晚想早点睡")
    from app.simple_models import Message
    with client.app.state.session_factory() as db:
        roles = [m.role for m in db.query(Message).all()]
    assert "user" in roles and "assistant" in roles


def test_model_failure_does_not_leak_raw_error_text(env, monkeypatch):
    client, headers, talk, state = env

    async def boom(url, payload, tier=None):
        raise RuntimeError("HTTP 401 Unauthorized sk-secret")

    monkeypatch.setattr(chat_module, "request_gateway", boom)
    response = talk("你好")
    assert response.status_code >= 500
    text = response.text
    assert "401" not in text and "sk-secret" not in text and "RuntimeError" not in text


GLOBAL = {"X-App-Market": "global", "Accept-Language": "en-GB", "X-Region": "GB"}


def test_international_voice_chat_is_english_with_local_crisis_line(env):
    """The voice route used to drop the locale and answer international users in Chinese with 12356."""
    client, headers, talk, state = env
    body = talk("I don't want to live anymore", GLOBAL).json()
    assert "12356" not in body["reply_text"] and "120" not in body["reply_text"].replace("116 123", "")
    assert "116 123" in body["reply_text"] or "Samaritans" in body["reply_text"]
    assert not any("\u4e00" <= ch <= "\u9fff" for ch in body["reply_text"])
    assert state["calls"] == []
    assert state["speech"].languages == ["en"]


def test_international_voice_chat_reaches_the_model_in_english(env):
    client, headers, talk, state = env
    state["answer"] = "A warm bath and an early night would help."
    body = talk("I would like to sleep better", GLOBAL).json()
    assert body["reply_text"].startswith("A warm bath")
    system = state["calls"][0]["messages"][0]["content"]
    assert "English" in system and "12356" not in system
    assert not any("\u4e00" <= ch <= "\u9fff" for ch in body["ai_label"] + body.get("ai_notice", ""))


def test_domestic_voice_chat_keeps_auto_language(env):
    client, headers, talk, state = env
    talk("我今晚想早点睡")
    assert state["speech"].languages == [None]


def test_international_voice_errors_are_english(env):
    client, headers, talk, state = env
    state["speech"] = SimpleNamespace(speech_to_text=None)

    async def boom(*a, **k):
        raise speech_module.ASRError("upstream")

    state["speech"] = SimpleNamespace(speech_to_text=boom, text_to_speech=boom)
    r = client.post("/api/v1/speech/chat-voice", headers={**headers, **GLOBAL},
                    files={"file": ("a.wav", b"RIFFxxxx", "audio/wav")})
    assert r.status_code == 400
    assert not any("\u4e00" <= ch <= "\u9fff" for ch in r.json()["detail"])
