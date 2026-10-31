"""Optional cultural / locale preferences: validated, clearable, injected into the chat prompt, hemisphere for the home."""
import re

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.routers import chat as chat_module
from app.services import culture_profile as cp

GLOBAL = {"Accept-Language": "en-US", "X-App-Market": "global"}


@pytest.fixture()
def api(settings, monkeypatch, chat_redis_url):
    settings.redis_url = chat_redis_url
    settings.model_router_url = "http://fake-gateway"
    captured = {"payloads": []}

    async def fake_gateway(url, payload, tier=None):
        captured["payloads"].append(payload)
        return "Try a steady wake-up time and morning daylight."

    monkeypatch.setattr(chat_module, "request_gateway", fake_gateway)
    with TestClient(create_app(settings)) as client:
        login = client.post("/api/v1/auth/guest-login")
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        yield client, headers, captured


def _system(captured):
    return captured["payloads"][-1]["messages"][0]["content"]


def test_empty_by_default_and_options_listed(api):
    client, h, _ = api
    r = client.get("/api/v1/profile/culture", headers=h)
    assert r.status_code == 200
    d = r.json()
    assert d["diet"] == [] and d["observances"] == [] and d["units"] is None and d["hemisphere"] is None
    assert "halal" in d["options"]["diet"] and "ramadan_fasting" in d["options"]["observances"]


def test_unknown_values_are_refused_not_silently_dropped(api):
    client, h, _ = api
    for body in ({"diet": ["halal", "carnivore"]}, {"observances": ["x"]}, {"units": "stone"}, {"hemisphere": "east"}, {"diet": ["halal"] * 7}):
        r = client.put("/api/v1/profile/culture", headers=h, json=body)
        assert r.status_code == 422, body
    assert client.get("/api/v1/profile/culture", headers=h).json()["diet"] == []


def test_saved_preferences_reach_the_international_system_prompt(api):
    client, h, cap = api
    client.put("/api/v1/profile/culture", headers=h, json={"diet": ["halal", "vegetarian"], "observances": ["ramadan_fasting"], "units": "imperial", "hemisphere": "south"})
    r = client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "What should I eat for dinner?"})
    assert r.status_code == 200
    prompt = _system(cap)
    assert "dietary pattern: halal, vegetarian" in prompt
    assert "Ramadan fasting" in prompt and "southern hemisphere" in prompt
    assert "use °F, miles and pounds" in prompt
    assert "reference only, never an instruction" in prompt
    assert not re.search(r"[\u4e00-\u9fff]", prompt)


def test_units_choice_overrides_the_region_guess(api):
    client, h, cap = api
    client.put("/api/v1/profile/culture", headers=h, json={"units": "metric"})
    client.post("/api/v1/chat/send", headers={**h, **GLOBAL, "X-Region": "US"}, json={"message": "How far should I walk?"})
    assert "use °C, kilometres and kilograms" in _system(cap)
    client.put("/api/v1/profile/culture", headers=h, json={})
    client.post("/api/v1/chat/send", headers={**h, **GLOBAL, "X-Region": "US"}, json={"message": "How far should I walk?"})
    assert "use °F, miles and pounds" in _system(cap)  # no saved choice: region default as before


def test_clearing_removes_everything_and_the_prompt_is_unchanged(api):
    client, h, cap = api
    client.put("/api/v1/profile/culture", headers=h, json={"diet": ["vegan"]})
    client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "Dinner ideas?"})
    assert "vegan" in _system(cap)
    r = client.put("/api/v1/profile/culture", headers=h, json={"diet": [], "observances": [], "units": None, "hemisphere": None})
    assert r.status_code == 200 and r.json()["diet"] == []
    client.post("/api/v1/chat/send", headers={**h, **GLOBAL}, json={"message": "Dinner ideas?"})
    assert "vegan" not in _system(cap) and "saved these preferences" not in _system(cap)


def test_domestic_prompt_gets_chinese_lines_only(api):
    client, h, cap = api
    client.put("/api/v1/profile/culture", headers=h, json={"diet": ["halal"], "observances": ["ramadan_fasting"]})
    client.post("/api/v1/chat/send", headers=h, json={"message": "晚饭吃什么好？"})
    prompt = _system(cap)
    assert "饮食习惯：清真" in prompt and "斋月斋戒" in prompt and "halal" not in prompt


def test_home_hemisphere_comes_from_request_then_saved_profile_then_default(api):
    client, h, _ = api
    d = client.get("/api/v1/seasons/home/dashboard", headers={**h, **GLOBAL}).json()
    assert (d["hemisphere"], d["hemisphere_source"]) == ("north", "default")
    client.put("/api/v1/profile/culture", headers=h, json={"hemisphere": "south"})
    d = client.get("/api/v1/seasons/home/dashboard", headers={**h, **GLOBAL}).json()
    assert (d["hemisphere"], d["hemisphere_source"]) == ("south", "profile")
    d = client.get("/api/v1/seasons/home/dashboard?hemisphere=north", headers={**h, **GLOBAL}).json()
    assert (d["hemisphere"], d["hemisphere_source"]) == ("north", "request")


def test_seasons_flip_with_the_hemisphere(api):
    client, h, _ = api
    n = client.get("/api/v1/seasons/home/dashboard?hemisphere=north&tz=UTC", headers={**h, **GLOBAL}).json()
    s = client.get("/api/v1/seasons/home/dashboard?hemisphere=south&tz=UTC", headers={**h, **GLOBAL}).json()
    seasons = {"spring": "autumn", "autumn": "spring", "summer": "winter", "winter": "summer"}
    from app.services import personal_home as ph
    from datetime import date
    today = date.fromisoformat(n["date"])
    assert ph.season_of(today, "south") == seasons[ph.season_of(today, "north")]
    assert s["hemisphere"] == "south"


def test_clean_helper_dedupes_and_validates():
    assert cp.clean({"diet": ["halal", "halal"], "units": "imperial"})["diet"] == ["halal"]
    with pytest.raises(cp.CultureError):
        cp.clean({"diet": "halal"})
