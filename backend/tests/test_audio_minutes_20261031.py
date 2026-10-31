"""Audio minutes: the quota `audio_daily_minutes` is backed by a real per-day counter fed by the players."""
from datetime import datetime
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services import audio_quota

GLOBAL = {"Accept-Language": "en-US", "X-App-Market": "global"}


@pytest.fixture()
def api(settings, chat_redis_url):
    settings.redis_url = chat_redis_url
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        yield client, {"Authorization": f"Bearer {login.json()['access_token']}"}


def _report(client, h, seconds, **extra):
    r = client.post("/api/v1/seasons/audio/progress", headers=h,
                    json={"audio_id": "a1", "progress_seconds": 10, "completed": False, "listened_seconds": seconds, **extra})
    assert r.status_code == 200, r.text
    return r.json()


def _item(client, h, headers=None):
    d = client.get("/api/v1/subscription/plan-usage", headers={**h, **(headers or {})}).json()
    return next(i for i in d["items"] if i["key"] == "audio_minutes")


def test_plan_usage_starts_at_zero_and_counts_whole_minutes(api):
    client, h = api
    start = _item(client, h)
    assert start["used"] == 0 and start["used_known"] is True and start["limit"] == 30
    out = _report(client, h, 90)
    assert out["counted"] is True and out["listened_today_seconds"] == 90 and out["limit_reached"] is False
    assert _item(client, h)["used"] == 1  # 90 s = 1 whole minute
    _report(client, h, 90)
    item = _item(client, h)
    assert item["used"] == 3 and item["remaining"] == 27


def test_position_alone_is_not_listening_time(api):
    client, h = api
    r = client.post("/api/v1/seasons/audio/progress", headers=h, json={"audio_id": "a1", "progress_seconds": 1800, "completed": False})
    assert r.json() == {"saved": True}
    assert _item(client, h)["used"] == 0


def test_total_is_clamped_at_the_daily_limit_and_flags_it(api):
    client, h = api
    for _ in range(3):
        out = _report(client, h, 3600)
    assert out["limit_reached"] is True and out["listened_today_seconds"] == 30 * 60
    item = _item(client, h)
    assert item["used"] == 30 and item["remaining"] == 0


def test_one_report_is_capped_and_bad_values_refused(api):
    client, h = api
    assert _report(client, h, 86400)["listened_today_seconds"] == 1800  # capped to 3600 s then to the 30 min limit
    r = client.post("/api/v1/seasons/audio/progress", headers=h, json={"audio_id": "a1", "progress_seconds": 1, "listened_seconds": -5})
    assert r.status_code == 422


def test_day_boundary_is_beijing_midnight():
    sh = ZoneInfo("Asia/Shanghai")
    k1, e1 = audio_quota.key_for("u", datetime(2026, 10, 31, 23, 59, tzinfo=sh))
    k2, e2 = audio_quota.key_for("u", datetime(2026, 11, 1, 0, 1, tzinfo=sh))
    assert k1 != k2 and e1 == int(datetime(2026, 11, 1, tzinfo=sh).timestamp())
    assert "u" not in k1.split(":")[-1]  # the user id is hashed, not stored


def test_counter_outage_reads_unknown_not_zero(settings):
    import asyncio
    assert asyncio.run(audio_quota.used_seconds("redis://127.0.0.1:1/0", "u")) is None
    out = asyncio.run(audio_quota.add_listened("redis://127.0.0.1:1/0", "u", "free", 60))
    assert out["counted"] is False and out["listened_today_seconds"] is None


def test_unlimited_tier_never_reaches_a_limit(chat_redis_url):
    import asyncio

    async def go():
        a = await audio_quota.add_listened(chat_redis_url, "u-unl", "plus", 3600)
        b = await audio_quota.add_listened(chat_redis_url, "u-unl", "plus", 3600)
        return a, b

    a, b = asyncio.run(go())
    assert b["listened_today_seconds"] == 7200 and b["limit_reached"] is False and b["limit_minutes"] is None
