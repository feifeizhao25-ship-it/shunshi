"""错误码对照：代码和文档是同一张表，六种情况的句子互不相同。"""
import os

import jwt

from app.error_catalog import CATALOG, text
from app.router.speech import TTSError
from app.security import token_now

DOC = os.path.join(os.path.dirname(__file__), "..", "..", "docs", "grok_review_20261124", "错误码对照.md")
DISTINCT = (
    "speech_unconfigured",
    "not_signed_in",
    "session_expired",
    "forbidden",
    "quota_exhausted",
    "compliance_blocked",
    "service_unavailable",
)


def test_document_lists_every_catalog_sentence():
    body = open(DOC, encoding="utf-8").read()
    for code, entry in CATALOG.items():
        assert f"| {code} |" in body, code
        assert entry.zh in body, code
        assert entry.en in body, code


def test_six_situations_do_not_share_a_sentence():
    zh = [text(code, "zh") for code in DISTINCT]
    en = [text(code, "en") for code in DISTINCT]
    assert len(set(zh)) == len(zh)
    assert len(set(en)) == len(en)
    assert "请求内容有误" not in text("speech_unconfigured", "zh")
    assert "稍后再试" not in text("compliance_blocked", "zh")
    assert text("not_signed_in", "zh") != text("session_expired", "zh")


class _Unconfigured:
    async def text_to_speech(self, **kwargs):
        raise TTSError("SILICONFLOW_API_KEY 未配置")


def test_missing_speech_key_is_not_a_bad_request(client, auth_headers, monkeypatch):
    monkeypatch.setattr("app.router.speech.get_speech_service", lambda: _Unconfigured())
    domestic = client.post("/api/v1/speech/tts", json={"text": "试一下"}, headers=auth_headers)
    assert domestic.status_code == 503, domestic.text
    assert domestic.json()["detail"] == text("speech_unconfigured", "zh")
    assert "请求内容有误" not in domestic.text
    assert "API_KEY" not in domestic.text

    global_headers = {**auth_headers, "Accept-Language": "en-US", "X-App-Market": "global"}
    international = client.post("/api/v1/speech/tts", json={"text": "hello"}, headers=global_headers)
    assert international.status_code == 503, international.text
    assert international.json()["detail"] == text("speech_unconfigured", "en")
    assert not any("\u4e00" <= ch <= "\u9fff" for ch in international.text)


def test_missing_token_and_expired_token_use_different_sentences(client):
    missing = client.get("/api/v1/subscription/status")
    assert missing.status_code == 401
    assert missing.json()["detail"] == text("not_signed_in", "zh")

    garbage = client.get("/api/v1/subscription/status", headers={"Authorization": "Bearer not-a-token"})
    assert garbage.status_code == 401
    assert garbage.json()["detail"] == text("not_signed_in", "zh")

    secret = os.environ["SHUNSHI_JWT_SECRET"]
    now = int(token_now())
    expired = jwt.encode({"sub": "user-expired", "jti": "expired-jti", "iat": now - 7200, "exp": now - 60}, secret, algorithm="HS256")
    gone = client.get("/api/v1/subscription/status", headers={"Authorization": f"Bearer {expired}"})
    assert gone.status_code == 401, gone.text
    assert gone.json()["detail"] == text("session_expired", "zh")

    english = client.get(
        "/api/v1/subscription/status",
        headers={"Authorization": f"Bearer {expired}", "Accept-Language": "en-US", "X-App-Market": "global"},
    )
    assert english.status_code == 401
    assert english.json()["detail"] == text("session_expired", "en")
    assert not any("\u4e00" <= ch <= "\u9fff" for ch in english.text)
