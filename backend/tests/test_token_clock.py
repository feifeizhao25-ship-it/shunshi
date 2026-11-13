"""签发和校验必须用同一只钟。

时钟回放会把 time.time 钉在过去。令牌若仍用那只钟签发、用墙上时间校验，
新游客令牌的 exp 会落在校验时刻之前。注销名单若用另一只钟清理，未过期的
jti 会被提前忘掉。exp / nbf / iat 仍然检查，不加 leeway。
"""

import base64
import json
import time
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi import HTTPException

from app.config import Settings
from app.security import issue_token, revoke_token, verify_token

SECRET = "token-clock-test-secret-at-least-32"


def _settings() -> Settings:
    return Settings(env="test", jwt_secret=SECRET, jwt_ttl_seconds=3600)


def _encode(**claims) -> str:
    return jwt.encode(claims, SECRET, algorithm="HS256")


def _unverified_claims(token: str) -> dict:
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


def test_pinned_time_time_still_accepts_a_new_token(monkeypatch):
    pinned = datetime(2026, 11, 4, 13, 0, tzinfo=timezone.utc).timestamp()
    monkeypatch.setattr(time, "time", lambda: pinned)
    token = issue_token(_settings(), "guest-after-pin")["access_token"]
    assert verify_token(_settings(), token) == "guest-after-pin"


def test_issue_and_verify_follow_the_injected_clock(monkeypatch):
    fixed = 1_700_000_000
    monkeypatch.setattr("app.security.token_now", lambda: fixed)
    token = issue_token(_settings(), "replay-user")["access_token"]
    claims = _unverified_claims(token)
    assert claims["iat"] == fixed
    assert claims["exp"] == fixed + 3600
    assert verify_token(_settings(), token) == "replay-user"


def test_exp_nbf_and_iat_stay_enforced(monkeypatch):
    fixed = 1_700_000_000
    monkeypatch.setattr("app.security.token_now", lambda: fixed)
    settings = _settings()

    expired = _encode(sub="u", jti="expired", iat=fixed - 120, exp=fixed - 1)
    not_before = _encode(sub="u", jti="early", iat=fixed, nbf=fixed + 60, exp=fixed + 3600)
    future_iat = _encode(sub="u", jti="future", iat=fixed + 60, exp=fixed + 3600)

    for token in (expired, not_before, future_iat):
        with pytest.raises(HTTPException) as denied:
            verify_token(settings, token)
        assert denied.value.status_code == 401


def test_guest_logout_rejects_the_same_token(client):
    created = client.post("/api/v1/auth/guest-login", json={})
    assert created.status_code == 200, created.text
    token = created.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    assert client.get("/api/v1/auth/me", headers=headers).status_code == 200
    logged_out = client.post("/api/v1/auth/logout", headers=headers)
    assert logged_out.status_code == 200, logged_out.text
    assert client.get("/api/v1/auth/me", headers=headers).status_code == 401


def test_revocation_ignores_a_different_time_time(monkeypatch):
    settings = _settings()
    token = issue_token(settings, "logout-user")["access_token"]
    revoke_token(settings, token)
    monkeypatch.setattr(time, "time", lambda: datetime.now(timezone.utc).timestamp() + timedelta(days=3650).total_seconds())
    with pytest.raises(HTTPException) as denied:
        verify_token(settings, token)
    assert denied.value.status_code == 401
