"""算法推荐规定第 17 条：可以关掉个性化；关掉后首页卡片等于非个性化默认。

每张卡有「为什么推荐」。点「不再推荐」只影响这一个用户，并且关掉个性化之后不再生效。
"""

from datetime import datetime
from zoneinfo import ZoneInfo

from app.services import home_cards
from app.services import personal_home_service as phs

SH = ZoneInfo("Asia/Shanghai")
WHEN = datetime(2026, 11, 8, 9, 0, tzinfo=SH)


def _guest(client):
    payload = client.post("/api/v1/auth/guest-login", json={}).json()
    token = payload.get("access_token") or payload["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def _pin(monkeypatch):
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: WHEN if not is_global else WHEN)


def _brief(cards):
    return [(card["id"], card["title"], card["reason"], card["basis"], card["why_label"]) for card in cards]


def _setup(client, headers, *, province, goal):
    assert client.post("/api/v1/settings/region", json={"province": province}, headers=headers).status_code == 200
    assert client.post(
        "/api/v1/seasons/onboarding/complete",
        json={"help_goal": goal},
        headers=headers,
    ).status_code == 200


def test_turning_personalization_off_matches_the_shared_default(client, monkeypatch):
    _pin(monkeypatch)
    chengdu = _guest(client)
    guangzhou = _guest(client)
    _setup(client, chengdu, province="四川", goal="睡得更好")
    _setup(client, guangzhou, province="广东", goal="照顾家人")

    on_chengdu = client.get("/api/v1/seasons/home/dashboard", headers=chengdu).json()
    on_guangzhou = client.get("/api/v1/seasons/home/dashboard", headers=guangzhou).json()
    assert on_chengdu["personalization"]["enabled"] is True
    assert _brief(on_chengdu["suggestions"]) != _brief(on_guangzhou["suggestions"])
    for board in (on_chengdu, on_guangzhou):
        assert board["suggestions"]
        for card in board["suggestions"]:
            assert card["why_label"] == "为什么推荐"
            assert card["reason"]

    for headers in (chengdu, guangzhou):
        saved = client.post(
            "/api/v1/seasons/profile/preferences",
            json={"personalization_enabled": False},
            headers=headers,
        )
        assert saved.status_code == 200 and saved.json()["personalization_enabled"] is False

    off_chengdu = client.get("/api/v1/seasons/home/dashboard", headers=chengdu).json()
    off_guangzhou = client.get("/api/v1/seasons/home/dashboard", headers=guangzhou).json()
    expected = home_cards.nonpersonalized_cards(WHEN.date())
    assert off_chengdu["personalization"]["enabled"] is False
    assert off_chengdu["hero"] is None
    assert _brief(off_chengdu["suggestions"]) == _brief(expected)
    assert _brief(off_guangzhou["suggestions"]) == _brief(expected)
    assert all(card["basis"] in {"solar_term", "holiday_calendar", "weekday"} for card in expected)
    assert "四川" not in str(off_chengdu["suggestions"])
    assert "广东" not in str(off_guangzhou["suggestions"])


def test_not_recommend_hides_one_card_for_that_user_only(client, monkeypatch):
    _pin(monkeypatch)
    one = _guest(client)
    other = _guest(client)
    _setup(client, one, province="四川", goal="睡得更好")
    _setup(client, other, province="四川", goal="睡得更好")
    before = client.get("/api/v1/seasons/home/dashboard", headers=one).json()["suggestions"]
    target = before[0]["id"]
    saved = client.post("/api/v1/seasons/home/not-recommend", json={"card_id": target}, headers=one)
    assert saved.status_code == 200 and target in saved.json()["not_recommend"]
    again = client.post("/api/v1/seasons/home/not-recommend", json={"card_id": target}, headers=one)
    assert again.json()["not_recommend"].count(target) == 1

    one_ids = [card["id"] for card in client.get("/api/v1/seasons/home/dashboard", headers=one).json()["suggestions"]]
    other_ids = [card["id"] for card in client.get("/api/v1/seasons/home/dashboard", headers=other).json()["suggestions"]]
    assert target not in one_ids
    assert target in other_ids

    assert client.post("/api/v1/seasons/home/not-recommend", json={"card_id": "  "}, headers=one).status_code == 422

    client.post("/api/v1/seasons/profile/preferences", json={"personalization_enabled": False}, headers=one)
    off = client.get("/api/v1/seasons/home/dashboard", headers=one).json()
    expected = home_cards.nonpersonalized_cards(WHEN.date())
    assert _brief(off["suggestions"]) == _brief(expected)
    assert target in [card["id"] for card in expected]
