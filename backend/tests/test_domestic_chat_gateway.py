# -*- coding: utf-8 -*-
"""顺时的对话要能在自己的部署里跑起来，并且只连境内模型。

原来 /api/v1/chat 只会调一个外部「模型网关」，契约写的是见己的 svc-model-router；
顺时自己的 compose 里没有模型网关——按顺时自己的部署文档上线，对话永远 503。
要让它能用，只能指向见己的服务，两条产品线共用模型出口。

现在默认进程内直连 DeepSeek，失败转硅基流动；两家都没配 key 时 503 并写明缺哪个变量。
另：用户打开「记忆」后，最近几轮对话交给模型（原来开关只影响清除按钮）。
"""
from __future__ import annotations

import asyncio
import json
import os
import pathlib
import sys

import httpx
import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

SECRET = "s" * 48
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)

from app.llm import domestic_gateway as gw  # noqa: E402

MESSAGES = [{"role": "user", "content": "最近总是睡不好"}]


def _mock(handler):
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def _ok(text):
    return httpx.Response(200, json={"choices": [{"message": {"role": "assistant", "content": text}}]})


# ── 一、出口本身 ──────────────────────────────────────────────

def test_no_domestic_key_is_503_and_names_the_variables():
    with pytest.raises(Exception) as info:
        asyncio.run(gw.complete(MESSAGES, env={}))
    assert info.value.status_code == 503
    assert "SHUNSHI_DEEPSEEK_API_KEY" in json.dumps(info.value.detail, ensure_ascii=False)


def test_calls_deepseek_with_the_key_and_messages():
    seen = []

    def handler(request):
        seen.append(request)
        return _ok("早点放下手机")

    text = asyncio.run(gw.complete(MESSAGES, "free", client=_mock(handler), env={"SHUNSHI_DEEPSEEK_API_KEY": "k1"}))
    assert text == "早点放下手机"
    assert seen[0].url.host == "api.deepseek.com"
    assert seen[0].headers["authorization"] == "Bearer k1"
    body = json.loads(seen[0].content)
    assert body["messages"] == MESSAGES and body["max_tokens"] == gw.MAX_TOKENS_BY_TIER["free"]


def test_falls_back_to_siliconflow_when_deepseek_fails():
    hosts = []

    def handler(request):
        hosts.append(request.url.host)
        return httpx.Response(503) if request.url.host == "api.deepseek.com" else _ok("备用供应商的回答")

    env = {"SHUNSHI_DEEPSEEK_API_KEY": "k1", "SHUNSHI_SILICONFLOW_API_KEY": "k2"}
    assert asyncio.run(gw.complete(MESSAGES, client=_mock(handler), env=env)) == "备用供应商的回答"
    assert hosts == ["api.deepseek.com", "api.siliconflow.cn"]


def test_all_providers_failing_is_502_without_leaking_provider_bodies():
    def handler(request):
        return httpx.Response(500, text="internal secret stack trace")

    with pytest.raises(Exception) as info:
        asyncio.run(gw.complete(MESSAGES, client=_mock(handler), env={"SHUNSHI_DEEPSEEK_API_KEY": "k"}))
    assert info.value.status_code == 502
    assert "stack trace" not in json.dumps(info.value.detail)


def test_only_domestic_hosts_are_ever_contacted():
    assert {httpx.URL(p.endpoint).host for p in gw.PROVIDERS} <= gw.DOMESTIC_HOSTS
    src = (BACKEND / "app" / "llm" / "domestic_gateway.py").read_text(encoding="utf-8")
    code = src.split('"""', 2)[2]  # 跳过模块说明
    for offshore in ("openrouter.ai", "api.openai.com", "anthropic.com", "googleapis.com"):
        assert offshore not in code


# ── 二、对话接口端到端 ────────────────────────────────────────

@pytest.fixture()
def chat_client(tmp_path, monkeypatch):
    from fastapi.testclient import TestClient

    from app.config import Settings
    from app.main import create_app
    from app.security import issue_token
    from app.services import chat_quota

    async def _reserve(*_a, **_k):
        return ("counter", "token")

    async def _refund(*_a, **_k):
        return None

    monkeypatch.setattr(chat_quota, "reserve", _reserve)
    monkeypatch.setattr(chat_quota, "refund", _refund)

    calls = []

    def handler(request):
        calls.append(json.loads(request.content)["messages"])
        return _ok(f"第{len(calls)}次回答")

    real_complete = gw.complete

    async def fake_complete(messages, tier="free", **_):
        return await real_complete(messages, tier, client=_mock(handler), env={"SHUNSHI_DEEPSEEK_API_KEY": "k"})

    monkeypatch.setattr(gw, "complete", fake_complete)

    settings = Settings(jwt_secret=SECRET, env="test", database_url=f"sqlite:///{tmp_path / 'core.db'}")
    app = create_app(settings)
    client = TestClient(app)
    client.__enter__()
    token = issue_token(settings, "user-chat-1")["access_token"]
    yield client, {"Authorization": f"Bearer {token}"}, calls
    client.__exit__(None, None, None)


def test_chat_answers_without_any_external_gateway(chat_client):
    client, headers, calls = chat_client
    r = client.post("/api/v1/chat/send", json={"message": "最近总是睡不好"}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["content"] == "第1次回答"
    assert calls[0][-1] == {"role": "user", "content": "最近总是睡不好"}


def test_history_is_not_sent_while_memory_is_off(chat_client):
    client, headers, calls = chat_client
    client.post("/api/v1/chat/send", json={"message": "我叫小周"}, headers=headers)
    client.post("/api/v1/chat/send", json={"message": "我叫什么"}, headers=headers)
    assert [m["content"] for m in calls[1] if m["role"] != "system"] == ["我叫什么"]


def test_history_is_sent_once_memory_is_on(chat_client):
    client, headers, calls = chat_client
    assert client.post("/api/v1/settings/memory", json={"enabled": True}, headers=headers).status_code == 200
    client.post("/api/v1/chat/send", json={"message": "我叫小周"}, headers=headers)
    client.post("/api/v1/chat/send", json={"message": "我叫什么"}, headers=headers)
    convo = [(m["role"], m["content"]) for m in calls[1] if m["role"] != "system"]
    assert convo == [("user", "我叫小周"), ("assistant", "第1次回答"), ("user", "我叫什么")]


def test_history_never_includes_other_users(chat_client):
    from app.security import issue_token

    client, headers, calls = chat_client
    client.post("/api/v1/settings/memory", json={"enabled": True}, headers=headers)
    client.post("/api/v1/chat/send", json={"message": "我的秘密"}, headers=headers)
    other = {"Authorization": "Bearer " + issue_token(client.app.state.settings, "user-chat-2")["access_token"]}
    client.post("/api/v1/settings/memory", json={"enabled": True}, headers=other)
    client.post("/api/v1/chat/send", json={"message": "你好"}, headers=other)
    assert all("我的秘密" not in m["content"] for m in calls[1])


def test_health_reports_domestic_gateway_instead_of_permanent_down(monkeypatch, tmp_path):
    """没配外部网关、配了境内 key 时，/api/health 的模型一项不能永远是 down。"""
    from fastapi.testclient import TestClient

    from app.config import Settings
    from app.main import create_app
    from app.routers import health as health_mod

    monkeypatch.delenv("SHUNSHI_DEEPSEEK_API_KEY", raising=False)
    monkeypatch.delenv("DEEPSEEK_API_KEY", raising=False)
    monkeypatch.delenv("SHUNSHI_SILICONFLOW_API_KEY", raising=False)
    monkeypatch.delenv("SILICONFLOW_API_KEY", raising=False)
    monkeypatch.setattr(health_mod, "probe_redis", lambda url: True)
    app = create_app(
        Settings(
            jwt_secret="x" * 40,
            database_url=f"sqlite:///{tmp_path}/h.db",
            redis_url="redis://unused:6379/0",
        )
    )
    with TestClient(app) as client:
        body = client.get("/api/health").json()
        assert body["components"]["model_gateway"]["status"] == "down"
        monkeypatch.setenv("SHUNSHI_DEEPSEEK_API_KEY", "k-test")
        body = client.get("/api/health").json()
        gw = body["components"]["model_gateway"]
        assert gw["status"] == "up" and gw["providers"] == ["deepseek"]
        assert "k-test" not in str(body)
