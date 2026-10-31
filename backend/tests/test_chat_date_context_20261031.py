"""The model has no clock: it answered 'it's March' on 31 October. The prompt now carries today's date, and the
season only when the user saved a hemisphere."""
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module
from app.services import culture_profile as cp

GLOBAL = {"Accept-Language": "en-US", "X-App-Market": "global"}


def test_season_table_both_hemispheres():
    assert cp.season_for(10, "north") == "autumn" and cp.season_for(10, "south") == "spring"
    assert cp.season_for(12, "north") == "winter" and cp.season_for(12, "south") == "summer"
    assert cp.season_for(3, "north") == "spring" and cp.season_for(3, "south") == "autumn"
    assert {cp.season_for(m, "north") for m in range(1, 13)} == {"winter", "spring", "summer", "autumn"}


def test_zh_line_is_beijing_date():
    assert cp.date_line_zh(datetime(2026, 10, 31, 9, 0)) == "今天是2026年10月31日（北京时间）。"


@pytest.fixture()
def api(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"
    captured = {"payloads": []}

    async def fake_gateway(url, payload, tier=None):
        captured["payloads"].append(payload)
        return "ok"

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        yield client, {"Authorization": f"Bearer {login.json()['access_token']}"}, captured


def _system(captured):
    return captured["payloads"][-1]["messages"][0]["content"]


def test_global_prompt_has_date_and_no_season_when_hemisphere_unknown(api):
    client, h, cap = api
    assert client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "What season is it?"}).status_code == 200
    s = _system(cap)
    assert "Today's date is 20" in s and "hemisphere is not known" in s
    assert " it is spring" not in s and " it is autumn" not in s


def test_global_prompt_names_the_season_for_the_saved_hemisphere(api):
    client, h, cap = api
    assert client.put("/api/v1/profile/culture", headers={**h, **GLOBAL}, json={"hemisphere": "south"}).status_code == 200
    assert client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "What season is it?"}).status_code == 200
    s = _system(cap)
    month = datetime.now(timezone.utc).month
    assert f"it is {cp.season_for(month, 'south')}" in s and "southern" in s


def test_domestic_prompt_has_the_beijing_date(api):
    client, h, cap = api
    assert client.post("/api/v1/chat/send", headers=h, json={"message": "你好"}).status_code == 200
    assert "今天是20" in _system(cap) and "北京时间" in _system(cap)
