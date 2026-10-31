"""Personalised home: 5 users x 7 days must visibly differ, stay stable within a day, rotate, and stay safe.

Engine tests are pure (no DB). API tests drive the real endpoints with a pinned clock.
"""

import re
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest

from app.services import personal_home as ph
from app.services import personal_home_service as phs

CJK = re.compile(r"[\u3400-\u9fff]")
SH = ZoneInfo("Asia/Shanghai")
START = date(2026, 11, 2)  # Monday

PERSONAS = {
    "sleeper": dict(goals=frozenset({"sleep"}), support_time="night", constitution="阴虚"),
    "walker": dict(goals=frozenset({"exercise", "mood"}), support_time="morning", constitution="气虚"),
    "caregiver": dict(goals=frozenset({"family", "food"}), support_time="evening", constitution="痰湿"),
    "stressed": dict(goals=frozenset({"breathing", "mood"}), support_time="afternoon", constitution="气郁"),
    "newcomer": dict(goals=frozenset(), support_time=None, constitution=None),
}


def week(lang, persona, hour=8, history_seed=True, complete=()):
    """Run one persona for 7 days, feeding shown cards back as the app does."""
    kw = PERSONAS[persona]
    activity = ph.Activity()
    boards = []
    for i in range(7):
        day = START + timedelta(days=i)
        now = datetime(day.year, day.month, day.day, hour, 0, tzinfo=SH)
        profile = ph.Profile(lang=lang, season=ph.season_of(day), **kw)
        daytype = "weekend" if day.weekday() >= 5 else "weekday"
        board = ph.compose(profile, activity, persona, now, daytype)
        boards.append(board)
        if history_seed:
            activity.seen += [(c["id"], day) for c in board["cards"] if c["id"] in ph.BY_ID]
        for k in complete:
            if i in k[0]:
                activity.completed.append((k[1], now))
    return boards


def ids(board):
    return [c["id"] for c in board["cards"]]


@pytest.mark.parametrize("lang", ["zh", "en"])
def test_five_users_get_visibly_different_boards_every_day(lang):
    weeks = {p: week(lang, p) for p in PERSONAS}
    for d in range(7):
        day_sets = {p: frozenset(ids(weeks[p][d])) for p in PERSONAS}
        heroes = {weeks[p][d]["hero"]["id"] for p in PERSONAS}
        assert len(heroes) >= 3, (d, heroes)
        assert len(set(day_sets.values())) == 5, f"day {d}: two users got identical boards"
        names = list(PERSONAS)
        for i in range(5):
            for j in range(i + 1, 5):
                a, b = day_sets[names[i]], day_sets[names[j]]
                assert len(a & b) / len(a | b) < 0.8, (d, names[i], names[j])


@pytest.mark.parametrize("lang", ["zh", "en"])
def test_each_user_changes_from_day_to_day_and_does_not_repeat_the_same_cards(lang):
    for persona in PERSONAS:
        boards = week(lang, persona)
        sets = [frozenset(ids(b)) for b in boards]
        assert len(set(sets)) == 7, persona
        for a, b in zip(sets, sets[1:]):
            assert len(a & b) <= 2, (persona, a & b)  # rotation: at most two carry over between consecutive days
        seen_heroes = [b["hero"]["id"] for b in boards]
        assert len(set(seen_heroes)) >= 5, (persona, seen_heroes)


def test_without_history_rotation_would_repeat_more():
    with_hist = week("en", "sleeper")
    without = week("en", "sleeper", history_seed=False)
    overlap = lambda bs: sum(len(set(ids(a)) & set(ids(b))) for a, b in zip(bs, bs[1:]))
    assert overlap(with_hist) < overlap(without)


def test_time_of_day_changes_the_board_for_the_same_user_and_day():
    day = START
    profile = ph.Profile(lang="zh", season="winter", **PERSONAS["sleeper"])
    boards = {h: ph.compose(profile, ph.Activity(), "u", datetime(day.year, day.month, day.day, h, tzinfo=SH), "weekday") for h in (7, 12, 16, 20, 23)}
    assert len({frozenset(ids(b)) for b in boards.values()}) >= 4
    cats = lambda b: {c["category"] for c in b["cards"]}
    assert "sleep" in cats(boards[23]) and "sleep" in cats(boards[20])
    assert boards[23]["hero"]["category"] == "sleep"
    assert "time" in boards[23]["hero"]["bases"] and "time" not in boards[7]["hero"]["bases"] or boards[7]["hero"]["id"] != boards[23]["hero"]["id"]
    assert boards[7]["greeting"] != boards[23]["greeting"]


def test_weekend_and_weekday_differ():
    profile = ph.Profile(lang="en", season="autumn", **PERSONAS["walker"])
    mon = ph.compose(profile, ph.Activity(), "u", datetime(2026, 11, 2, 9, tzinfo=SH), "weekday")
    sat = ph.compose(profile, ph.Activity(), "u", datetime(2026, 11, 7, 9, tzinfo=SH), "weekend")
    assert set(ids(mon)) != set(ids(sat))
    assert not any(ph.BY_ID[i]["day"] == "weekday" for i in ids(sat) if i in ph.BY_ID)


def test_season_and_hemisphere_change_cards():
    assert ph.season_of(date(2026, 12, 15), "north") == "winter"
    assert ph.season_of(date(2026, 12, 15), "south") == "summer"
    north = ph.compose(ph.Profile(lang="en", season="winter"), ph.Activity(), "u", datetime(2026, 12, 15, 8, tzinfo=timezone.utc), "weekday")
    south = ph.compose(ph.Profile(lang="en", season="summer"), ph.Activity(), "u", datetime(2026, 12, 15, 8, tzinfo=timezone.utc), "weekday")
    assert "season_winter" in ids(north) and "season_summer" not in ids(north)
    assert "season_summer" in ids(south) and "season_winter" not in ids(south)


def test_streaks_and_welcome_back():
    now = datetime(2026, 11, 9, 9, tzinfo=SH)
    prof = ph.Profile(lang="en", season="autumn")
    act = ph.Activity(completed=[("sleep", now - timedelta(days=d)) for d in (0, 1, 2, 3)])
    assert ph.compose(prof, act, "u", now)["streak"]["kind"] == "streak"
    assert ph.compose(prof, act, "u", now)["streak"]["days"] == 4
    old = ph.Activity(completed=[("sleep", now - timedelta(days=6))])
    assert ph.compose(prof, old, "u", now)["streak"]["kind"] == "welcome_back"
    assert ph.compose(prof, ph.Activity(), "u", now)["streak"]["kind"] == "start"
    zh = ph.compose(ph.Profile(lang="zh", season="autumn"), act, "u", now)["streak"]["text"]
    assert "连续 4 天" in zh


def test_completed_category_is_reinforced_and_not_handed_back_immediately():
    now = datetime(2026, 11, 9, 21, tzinfo=SH)
    prof = ph.Profile(lang="en", season="autumn", goals=frozenset({"breathing"}))
    base = ph.compose(prof, ph.Activity(), "u", now)
    done = ph.compose(prof, ph.Activity(completed=[("breathing", now - timedelta(days=1))]), "u", now)
    assert any(c["category"] == "breathing" for c in base["cards"])
    reasons = " ".join(c["reason"] for c in done["cards"])
    assert "recently" in reasons or done != base


def test_every_card_has_a_reason_in_the_right_language_and_is_attributable():
    for lang in ("zh", "en"):
        for p in PERSONAS:
            for board in week(lang, p):
                for c in board["cards"]:
                    assert c["reason"] and c["title"] and c["basis"]
                    if c["id"] in ph.BY_ID:
                        assert c["bases"], c
                text = " ".join(c["title"] + " " + c["reason"] for c in board["cards"]) + board["greeting"] + board["personalization"]["note"]
                assert bool(CJK.search(text)) == (lang == "zh"), (lang, p, text[:200])


def test_global_week_contains_no_chinese_and_no_tcm_constitution():
    for p in PERSONAS:
        for board in week("en", p):
            blob = str(board)
            assert not CJK.search(blob)
    # constitution only ever shows up as a domestic, self-chosen, labelled-not-diagnosis reason
    zh = [c for b in week("zh", "sleeper") for c in b["cards"] if "cons" in c.get("bases", [])]
    assert zh and all("自评，不是诊断" in c["reason"] for c in zh)


def test_content_library_is_lifestyle_only():
    assert len(ph.LIBRARY) >= 35 and len({c["id"] for c in ph.LIBRARY}) == len(ph.LIBRARY)
    for c in ph.LIBRARY:
        assert not ph.forbidden_hits(c["zh"], "zh"), c["id"]
        assert not ph.forbidden_hits(c["en"], "en"), c["id"]
        assert CJK.search(c["zh"]) and not CJK.search(c["en"]), c["id"]
        assert c["category"] in {"sleep", "breathing", "exercise", "food", "mood", "family", "seasonal", "rest"}


def test_personalisation_off_gives_everyone_the_same_generic_board_and_says_so():
    anchors = [{"id": "term", "category": "seasonal", "title": "t", "reason": "r", "basis": "solar_term"}]
    outs = []
    for p in PERSONAS:
        prof = ph.Profile(lang="zh", season="winter", enabled=False, **{k: v for k, v in PERSONAS[p].items()})
        outs.append(ph.compose(prof, ph.Activity(), p, datetime(2026, 11, 2, 8, tzinfo=SH), "weekday", extra_cards=anchors))
    assert all(o["cards"] == outs[0]["cards"] for o in outs)
    assert outs[0]["personalization"]["enabled"] is False and outs[0]["hero"] is None


def test_noise_is_stable_per_user_day_card_but_differs_between_users():
    a = ph._noise("u1", START, "x")
    assert a == ph._noise("u1", START, "x")
    assert a != ph._noise("u2", START, "x") and a != ph._noise("u1", START + timedelta(days=1), "x")


# ── API ─────────────────────────────────────────────────────────────────────
def _guest(client):
    r = client.post("/api/v1/auth/guest-login", json={})
    payload = r.json()
    token = payload.get("access_token") or payload["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def _pin(monkeypatch, when):
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: when.astimezone(SH) if not is_global else when)


ONBOARD = {
    "sleeper": {"help_goal": "睡得更好", "support_time": "晚上"},
    "walker": {"help_goal": "白天更有精神", "support_time": "早上"},
    "caregiver": {"help_goal": "照顾家人", "support_time": "晚上"},
    "stressed": {"help_goal": "放松减压", "support_time": "下午"},
    "newcomer": {},
}


def test_api_five_users_seven_days_differ_rotate_and_are_stable_within_a_day(client, monkeypatch):
    users = {}
    for name, body in ONBOARD.items():
        h = _guest(client)
        if body:
            assert client.post("/api/v1/seasons/onboarding/complete", json=body, headers=h).status_code == 200
        users[name] = h
    seen_by_user = {n: [] for n in users}
    for i in range(7):
        when = datetime(2026, 11, 2 + i, 21 if i % 2 else 8, 0, tzinfo=SH)
        _pin(monkeypatch, when)
        day_boards = {}
        for name, h in users.items():
            data = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
            again = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
            ids_now = [c["id"] for c in data["suggestions"]]
            assert ids_now == [c["id"] for c in again["suggestions"]], "refresh must not reshuffle"
            assert data["greeting"] and data["hero"] and data["personalization"]["enabled"] is True
            assert CJK.search(data["greeting"])  # domestic stays Chinese
            day_boards[name] = frozenset(ids_now)
            seen_by_user[name].append(ids_now)
        # user ids are random here, so two users with overlapping goals can rarely coincide on one day;
        # the strict 5-of-5 check runs on the engine with fixed keys above
        assert len(set(day_boards.values())) >= 4, f"day {i}: too many identical boards for different users"
    names = list(users)
    for a in range(5):
        for b in range(a + 1, 5):
            differing = sum(1 for x, y in zip(seen_by_user[names[a]], seen_by_user[names[b]]) if set(x) != set(y))
            assert differing >= 6, (names[a], names[b], differing)
    for name, days in seen_by_user.items():
        assert len({frozenset(d) for d in days}) >= 6, name
        for a, b in zip(days, days[1:]):
            non_anchor = lambda xs: {x for x in xs if x in ph.BY_ID}
            assert len(non_anchor(a) & non_anchor(b)) <= 2, (name, a, b)


def test_api_international_user_gets_english_with_local_time_and_hemisphere(client, monkeypatch):
    h = _guest(client)
    client.post("/api/v1/seasons/onboarding/complete", json={"help_goal": "sleep better", "support_time": "night"}, headers=h)
    when = datetime(2026, 12, 15, 23, 0, tzinfo=timezone.utc)
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: when)
    en = {"Accept-Language": "en-AU", **h}
    south = client.get("/api/v1/seasons/home/dashboard?hemisphere=south&tz=Australia/Sydney", headers=en).json()
    assert not CJK.search(str(south)), south
    assert south["time_of_day"] == "night" and "It's late" in south["greeting"]
    assert all("winter" not in c["id"] for c in south["suggestions"])
    north = client.get("/api/v1/seasons/home/dashboard?hemisphere=north", headers=en).json()
    assert all("summer" not in c["id"] for c in north["suggestions"])


def test_api_preferences_switch_off_and_constitution_validation(client, monkeypatch):
    h = _guest(client)
    _pin(monkeypatch, datetime(2026, 11, 3, 9, tzinfo=SH))
    p = client.post("/api/v1/seasons/profile/preferences", json={"constitution": "阳虚"}, headers=h).json()
    assert p["constitution"] == "阳虚" and p["personalization_enabled"] is True
    assert client.post("/api/v1/seasons/profile/preferences", json={"constitution": "癌症"}, headers=h).status_code == 422
    on = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert on["personalization"]["enabled"] is True
    off = client.post("/api/v1/seasons/profile/preferences", json={"personalization_enabled": False}, headers=h).json()
    assert off["personalization_enabled"] is False
    generic = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert generic["personalization"]["enabled"] is False and generic["hero"] is None
    assert generic["suggestions"]  # still useful: calendar / solar-term tips
    assert client.post("/api/v1/seasons/profile/preferences", json={"clear_constitution": True}, headers=h).json()["constitution"] is None


def test_api_actions_drive_the_streak(client, monkeypatch):
    h = _guest(client)
    import time as _t
    assert client.post("/api/v1/personalization/action/complete", json={"action_type": "breathing", "completed": True}, headers=h).status_code == 200
    _pin(monkeypatch, datetime.fromtimestamp(_t.time(), SH))
    data = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert data["streak"]["kind"] in ("steady", "streak")
    assert "activity" in data["personalization"]["used"]


def test_fixed_utc_offset_timezone_for_apps_without_an_iana_name():
    now = datetime(2026, 11, 2, 20, 0, tzinfo=timezone.utc)
    assert phs.local_now(True, "UTC+05:30", now).hour == 1
    assert phs.local_now(True, "UTC-08:00", now).hour == 12
    assert phs.local_now(True, "UTC+99:00", now).hour == 20  # nonsense falls back to UTC
    assert phs.local_now(True, "Europe/Berlin", now).hour == 21
    assert phs.local_now(False, "UTC+05:30", now).hour == 4  # domestic stays on Beijing time


def test_api_global_market_header_alone_is_enough_for_english_home(client, monkeypatch):
    """The international app sends Accept-Language and X-App-Market; a client that only sends the market header
    must still get an all-English board (greeting, hero, cards, personalization note), including after some activity."""
    h = _guest(client)
    client.post("/api/v1/seasons/onboarding/complete", json={"help_goal": "sleep better", "support_time": "night"}, headers=h)
    client.post("/api/v1/user/daily-checkin", json={}, headers=h)
    when = datetime(2026, 11, 3, 14, 0, tzinfo=timezone.utc)
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: when)
    for extra in ({"X-App-Market": "global"}, {"X-App-Market": "global", "Accept-Language": "en-US"}):
        data = client.get("/api/v1/seasons/home/dashboard?tz=America/New_York", headers={**extra, **h}).json()
        assert not CJK.search(str(data)), (extra, data)
        assert data["greeting"] and data["personalization"]["note"]
