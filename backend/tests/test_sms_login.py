# -*- coding: utf-8 -*-
"""手机号验证码登录。

2026-09-21 发现：
1. 国内两个客户端的「验证码登录」是假的：只认写死的 123456，然后调一个不存在的
   ``/api/v1/auth/phone-login``，失败后**每次新建一个游客账号**当作登录成功——
   同一个手机号每次登录都是一个新人，之前的记录全都找不回来；真实短信里的验证码反而被拒。
2. ``/api/v1/auth/sms/send`` 没有任何节流：每条短信都花钱，也能拿来轰炸别人的手机。
3. ``/sms/verify`` 的「最多试 5 次」从未生效：失败计数在抛异常时被 get_session 回滚。
4. 游客、短信登录的账号只写在核心库；``/api/v1/auth/me`` 按记录库查人 → 401。
"""
from __future__ import annotations

import os
import pathlib
import sys
import uuid

import httpx
import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))
REPO = BACKEND.parent

SECRET = "s" * 48
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)

from fastapi.testclient import TestClient  # noqa: E402

REAL_ASYNC_CLIENT = httpx.AsyncClient


@pytest.fixture()
def env(tmp_path, monkeypatch):
    from app.config import Settings
    from app.main import create_app
    from app.routers import user as user_mod

    sent: list[dict] = []
    state = {"fail": False, "now": 1_790_000_000.0}

    def handler(request: httpx.Request) -> httpx.Response:
        if state["fail"]:
            return httpx.Response(500, json={"error": "provider down"})
        import json

        sent.append(json.loads(request.content))
        return httpx.Response(200, json={"ok": True})

    monkeypatch.setattr(
        user_mod.httpx,
        "AsyncClient",
        lambda **kw: REAL_ASYNC_CLIENT(transport=httpx.MockTransport(handler)),
    )
    monkeypatch.setattr(user_mod, "_now", lambda: state["now"])
    settings = Settings(
        jwt_secret=os.environ["SHUNSHI_JWT_SECRET"],
        database_url=f"sqlite:///{tmp_path}/core.db",
        sms_provider_url="https://sms.example.cn/send",
        sms_provider_token="t",
    )
    app = create_app(settings)
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client, sent, state


def _phone() -> str:
    return "139" + f"{uuid.uuid4().int % 10**8:08d}"


def _sub(token: str) -> str:
    import jwt

    return jwt.decode(token, options={"verify_signature": False})["sub"]


def test_same_phone_logs_into_the_same_account_and_can_read_me(env):
    client, sent, state = env
    phone = _phone()
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
    first = client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": sent[-1]["code"]})
    assert first.status_code == 200, first.text

    state["now"] += 120
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
    second = client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": sent[-1]["code"]})
    assert _sub(first.json()["access_token"]) == _sub(second.json()["access_token"])

    me = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer " + second.json()["access_token"]})
    assert me.status_code == 200, me.text
    assert me.json()["data"]["phone"] == phone


def test_guest_account_can_read_me(env):
    client, _, _ = env
    token = client.post("/api/v1/auth/guest-login", json={"device_id": "d"}).json()["access_token"]
    assert client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"}).status_code == 200


def test_resend_within_cooldown_is_refused(env):
    client, sent, state = env
    phone = _phone()
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
    again = client.post("/api/v1/auth/sms/send", json={"phone": phone})
    assert again.status_code == 429 and "Retry-After" in again.headers
    assert len(sent) == 1
    state["now"] += 61
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200


def test_daily_cap_per_phone(env):
    client, sent, state = env
    phone = _phone()
    for _ in range(5):
        assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
        state["now"] += 61
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 429
    assert len(sent) == 5


def test_daily_cap_per_source_address(env):
    client, sent, _ = env
    headers = {"X-Real-IP": "203.0.113.9"}
    for _ in range(20):
        assert client.post("/api/v1/auth/sms/send", json={"phone": _phone()}, headers=headers).status_code == 200
    assert client.post("/api/v1/auth/sms/send", json={"phone": _phone()}, headers=headers).status_code == 429
    other = client.post("/api/v1/auth/sms/send", json={"phone": _phone()}, headers={"X-Real-IP": "198.51.100.7"})
    assert other.status_code == 200


def test_wrong_code_attempts_are_counted(env):
    client, sent, _ = env
    phone = _phone()
    client.post("/api/v1/auth/sms/send", json={"phone": phone})
    real = sent[-1]["code"]
    wrong = "000000" if real != "000000" else "111111"
    for _ in range(5):
        assert client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": wrong}).status_code == 400
    # 第 6 次即使对了也不放行
    assert client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": real}).status_code == 400


def test_provider_failure_is_502_and_does_not_burn_quota(env):
    client, sent, state = env
    phone = _phone()
    state["fail"] = True
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 502
    state["fail"] = False
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200


@pytest.mark.parametrize("platform", ["android-cn", "ios-cn"])
def test_clients_verify_the_code_on_the_server(platform):
    path = REPO / platform / "lib/presentation/pages/login/login_page.dart"
    if not path.exists():
        pytest.skip("client source not present")
    source = path.read_text(encoding="utf-8")
    start = source.index("Future<void> _smsLogin()")
    body = source[start : source.index("\n  }\n", start)]
    assert "123456" not in body
    assert "/api/v1/auth/sms/verify" in body
    assert "guest-login" not in body
    assert "phone-login" not in body


def test_parallel_guesses_do_not_overwrite_attempt_counter(env):
    from concurrent.futures import ThreadPoolExecutor
    client, sent, _ = env
    phone = _phone()
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
    wrong = "000000" if sent[-1]["code"] != "000000" else "111111"
    with ThreadPoolExecutor(max_workers=10) as pool:
        responses = list(pool.map(lambda _: client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": wrong}), range(20)))
    assert all(r.status_code == 400 for r in responses)
    assert client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": sent[-1]["code"]}).status_code == 400


def test_parallel_correct_code_is_consumed_once(env):
    from concurrent.futures import ThreadPoolExecutor
    client, sent, _ = env
    phone = _phone()
    assert client.post("/api/v1/auth/sms/send", json={"phone": phone}).status_code == 200
    with ThreadPoolExecutor(max_workers=8) as pool:
        responses = list(pool.map(lambda _: client.post("/api/v1/auth/sms/verify", json={"phone": phone, "code": sent[-1]["code"]}), range(8)))
    assert [r.status_code for r in responses].count(200) == 1
    assert all(r.status_code in (200, 400) for r in responses)
