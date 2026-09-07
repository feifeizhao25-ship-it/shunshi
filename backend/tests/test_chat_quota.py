"""Real Redis atomicity and authenticated mounted-chat quota regressions."""
import asyncio
import uuid
from datetime import datetime, timezone

import pytest
from fastapi import HTTPException

from app.routers import chat
from app.services.chat_quota import keys_for, refund, reserve


@pytest.mark.parametrize("tier,limit", [("free", 20), ("pro", 200)])
def test_concurrent_reservations_and_idempotent_refund(chat_redis_url, tier, limit):
    async def run():
        user = uuid.uuid4().hex
        results = await asyncio.gather(*(reserve(chat_redis_url, user, tier) for _ in range(limit + 10)), return_exceptions=True)
        accepted = [result for result in results if not isinstance(result, Exception)]
        rejected = [result for result in results if isinstance(result, Exception)]
        assert len(accepted) == limit
        assert len(rejected) == 10
        assert all(isinstance(error, HTTPException) and error.status_code == 429 for error in rejected)
        await asyncio.gather(*(refund(chat_redis_url, accepted[0]) for _ in range(5)))
        await reserve(chat_redis_url, user, tier)
        with pytest.raises(HTTPException) as error:
            await reserve(chat_redis_url, user, tier)
        assert error.value.status_code == 429
    asyncio.run(run())


def test_beijing_midnight_reset():
    before = datetime(2026, 9, 7, 15, 59, 59, tzinfo=timezone.utc)
    after = datetime(2026, 9, 7, 16, 0, 0, tzinfo=timezone.utc)
    key1, _, expires1 = keys_for("fixture", before)
    key2, _, expires2 = keys_for("fixture", after)
    assert key1 != key2
    assert expires1 == int(after.timestamp())
    assert expires2 - expires1 == 86400


def test_aliases_share_quota_and_crisis_remains_available(client, auth_headers, settings, monkeypatch, chat_redis_url):
    settings.model_router_url = "http://fixture"
    settings.redis_url = chat_redis_url
    calls = []
    async def gateway(*args, **kwargs):
        calls.append(1)
        return "今天做一件小事。"
    monkeypatch.setattr(chat, "request_gateway", gateway)
    paths = ["/api/v1/chat", "/api/v1/chat/send", "/api/v1/ai/chat"]
    for index in range(20):
        response = client.post(paths[index % 3], headers=auth_headers, json={"message": "你好", "user_id": str(index), "model_tier": "enterprise"})
        assert response.status_code == 200
    for path in paths:
        assert client.post(path, headers=auth_headers, json={"message": "你好"}).status_code == 429
        crisis = client.post(path, headers=auth_headers, json={"message": "我想自杀"})
        assert crisis.status_code == 200
        assert "12356" in crisis.text
    assert len(calls) == 20


def test_gateway_failure_returns_reservation(client, auth_headers, settings, monkeypatch, chat_redis_url):
    settings.model_router_url = "http://fixture"
    settings.redis_url = chat_redis_url
    async def unavailable(*args, **kwargs):
        raise HTTPException(503, "fixture unavailable")
    monkeypatch.setattr(chat, "request_gateway", unavailable)
    for _ in range(22):
        assert client.post("/api/v1/chat/send", headers=auth_headers, json={"message": "你好"}).status_code == 503
    async def available(*args, **kwargs):
        return "今天做一件小事。"
    monkeypatch.setattr(chat, "request_gateway", available)
    assert client.post("/api/v1/chat/send", headers=auth_headers, json={"message": "你好"}).status_code == 200


@pytest.mark.parametrize("url", ["", "redis://127.0.0.1:1/0"])
def test_unavailable_counter_never_calls_model(client, auth_headers, settings, monkeypatch, url):
    settings.model_router_url = "http://fixture"
    settings.redis_url = url
    async def forbidden(*args, **kwargs):
        pytest.fail("Model must not be invoked without quota authorization")
    monkeypatch.setattr(chat, "request_gateway", forbidden)
    assert client.post("/api/v1/chat/send", headers=auth_headers, json={"message": "你好"}).status_code == 503
    assert client.post("/api/v1/chat/send", headers=auth_headers, json={"message": "我想自杀"}).status_code == 200
