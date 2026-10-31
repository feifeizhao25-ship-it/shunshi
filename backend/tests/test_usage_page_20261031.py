"""Plan & usage page backend: real limits, real counters, honest unknowns, English for the international edition."""
import re

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module
from app.services import chat_quota

GLOBAL = {"Accept-Language": "en-US", "X-App-Market": "global"}
CJK = re.compile(r"[\u3400-\u9fff]")


@pytest.fixture()
def api(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"

    async def fake_gateway(url, payload, tier=None):
        return "Try a steady wake-up time."

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        yield client, {"Authorization": f"Bearer {login.json()['access_token']}"}, settings


def items(data):
    return {i["key"]: i for i in data["items"]}


def test_free_plan_limits_come_from_the_registry(api):
    client, h, _ = api
    d = client.get("/api/v1/subscription/plan-usage", headers=h).json()
    it = items(d)
    assert d["plan"] == "free" and d["plan_name"] == "免费版" and d["active"] is False
    assert it["chat_messages"]["limit"] == 20 and it["chat_messages"]["used"] == 0 and it["chat_messages"]["remaining"] == 20
    assert it["reflections"]["limit"] == 3 and it["reflections"]["unlimited"] is False
    assert it["audio_minutes"]["limit"] == 30 and it["audio_minutes"]["used"] is None and it["audio_minutes"]["used_known"] is False
    assert "北京时间" in d["reset_note"] and d["resets_at"].endswith("+00:00")


def test_chat_usage_counts_real_messages(api):
    client, h, _ = api
    for _ in range(2):
        assert client.post("/api/v1/chat/send", headers=h, json={"message": "How do I sleep better?"}).status_code == 200
    it = items(client.get("/api/v1/subscription/plan-usage", headers=h).json())["chat_messages"]
    assert it["used"] == 2 and it["remaining"] == 18


def test_reflection_usage_counts_todays_entries(api):
    client, h, _ = api
    r = client.post("/api/v1/reflections", headers=h, json={"mood": "calm", "notes": "A quiet day."})
    assert r.status_code in (200, 201)
    assert items(client.get("/api/v1/subscription/plan-usage", headers=h).json())["reflections"]["used"] == 1


def test_international_edition_gets_english_only(api):
    client, h, _ = api
    d = client.get("/api/v1/subscription/plan-usage", headers={**h, **GLOBAL}).json()
    assert d["plan_name"] == "Free" and "Beijing time" in d["reset_note"]
    assert not CJK.search(str(d))


def test_unreadable_counter_is_unknown_not_zero(api, monkeypatch):
    client, h, settings = api
    settings.redis_url = "redis://127.0.0.1:1/0"
    it = items(client.get("/api/v1/subscription/plan-usage", headers=h).json())["chat_messages"]
    assert it["used"] is None and it["used_known"] is False and it["remaining"] is None and it["limit"] == 20


def test_quota_errors_are_localised(api):
    assert "已达上限" in chat_quota.message("exhausted", "zh")
    en = chat_quota.message("exhausted", "en")
    assert "limit resets" in en and not CJK.search(en)
    for kind in chat_quota.MESSAGES:
        assert not CJK.search(chat_quota.message(kind, "en"))


def test_exhausted_quota_returns_english_429_for_global_and_chinese_for_domestic(api, monkeypatch):
    client, h, _ = api
    from app import entitlements

    reg = entitlements.get_registry()
    monkeypatch.setitem(reg["tiers"]["free"]["quotas"], "ai_daily_messages", 1)
    assert client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "Hello there"}).status_code == 200
    r = client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "Hello again"})
    assert r.status_code == 429 and not CJK.search(r.json()["detail"])
    r = client.post("/api/v1/chat/send", headers=h, json={"message": "你好"})
    assert r.status_code == 429 and "北京时间" in r.json()["detail"]
