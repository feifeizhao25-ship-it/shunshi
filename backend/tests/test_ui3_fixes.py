"""2026-11-04 全量 UI 测试发现的顺时 / SEASONS 问题：I-07（国际版漏中文）、I-08（今日计划乱跳）。"""
import re
import uuid
from datetime import datetime as real_datetime

import pytest

from app.router import today_plan

CJK = re.compile(r"[\u3400-\u9fff]")
EN = {"Accept-Language": "en-US", "X-App-Market": "global"}


def _plan(client, headers=None):
    r = client.get("/api/v1/today-plan", headers=headers or {})
    assert r.status_code == 200, r.text
    return r.json()


def _freeze(monkeypatch, y, m, d):
    class FakeDT(real_datetime):
        @classmethod
        def now(cls, tz=None):
            return real_datetime(y, m, d, 9, 0, 0)
    monkeypatch.setattr(today_plan, "datetime", FakeDT)


def test_today_plan_is_stable_within_a_day_and_changes_next_day(client, auth_headers, monkeypatch):
    _freeze(monkeypatch, 2026, 11, 4)
    first = _plan(client, auth_headers)
    again = [_plan(client, auth_headers) for _ in range(5)]
    assert all(p["insights"] == first["insights"] and p["tasks"] == first["tasks"] for p in again)
    refreshed = client.post("/api/v1/today-plan/refresh", headers=auth_headers).json()
    assert refreshed["insights"] == first["insights"] and refreshed["tasks"] == first["tasks"]
    seen = {tuple(t["title"] for t in first["tasks"])}
    for day in range(5, 12):
        _freeze(monkeypatch, 2026, 11, day)
        seen.add(tuple(t["title"] for t in _plan(client, auth_headers)["tasks"]))
    assert len(seen) >= 3, "每天应有不同的一组"


def test_today_plan_differs_between_users_and_variant_rotates(client, monkeypatch):
    _freeze(monkeypatch, 2026, 11, 4)
    plans = []
    for _ in range(4):
        tok = client.post("/api/v1/auth/guest-login", json={}).json()["access_token"]
        plans.append(_plan(client, {"Authorization": f"Bearer {tok}"}))
    assert len({tuple(t["title"] for t in p["tasks"]) for p in plans}) >= 2
    tok = client.post("/api/v1/auth/guest-login", json={}).json()["access_token"]
    h = {"Authorization": f"Bearer {tok}"}
    base = _plan(client, h)
    alt = client.post("/api/v1/today-plan/refresh?variant=1", headers=h).json()
    assert alt["tasks"] != base["tasks"] or alt["insights"] != base["insights"]


def test_today_plan_reacts_to_the_users_own_recent_sleep(client, auth_headers, monkeypatch):
    from app.database.db import get_db
    _freeze(monkeypatch, 2026, 11, 4)
    uid = client.get("/api/v1/auth/me", headers=auth_headers).json()
    uid = (uid.get("data") or uid).get("id") or (uid.get("data") or uid).get("user_id")
    assert uid
    db = get_db()
    db.execute("INSERT INTO sleep_records (id, user_id, date, hours) VALUES (?, ?, ?, ?)", (f"sl-{uuid.uuid4().hex}", uid, "2026-11-03", 4.5))
    db.commit()
    plan = _plan(client, auth_headers)
    assert plan["personalization"]["signals"] == ["sleep_low"]
    assert plan["personalization"]["basis"]["records_used"] >= 1
    assert any(t["category"] == "rest" for t in plan["tasks"])  # 睡眠不足时一定排进休息类任务


def test_today_plan_global_is_english_without_chinese(client, monkeypatch):
    _freeze(monkeypatch, 2026, 11, 4)
    plan = _plan(client, EN)
    assert plan["locale"] == "en"
    assert not CJK.search(str(plan)), [m for m in re.findall(r".{0,20}[\u3400-\u9fff]+.{0,10}", str(plan))][:5]


def test_today_plan_domestic_stays_chinese(client):
    plan = _plan(client)
    assert plan["locale"] == "zh" and CJK.search(str(plan["insights"]))


def test_global_subscription_plans_are_english_usd_yearly(client, auth_headers):
    body = client.get("/api/v1/subscription/plans", headers={**auth_headers, **EN}).json()
    assert body["success"]
    plans = body["data"]
    assert [p["id"] for p in plans] == ["free", "premium", "family"]
    assert not CJK.search(str(plans))
    assert plans[0]["is_current"] is True and plans[0]["name"] == "Free"
    assert plans[1]["price_yearly"] == 79.99 and plans[1]["currency"] == "usd" and plans[1]["period"] == "year"


def test_domestic_subscription_plans_unchanged(client, auth_headers):
    plans = client.get("/api/v1/subscription/plans", headers=auth_headers).json()["data"]
    assert plans[0]["name"] == "免费版" and len(plans) == 4


def test_global_family_default_name_and_errors_are_english(client, auth_headers):
    h = {**auth_headers, **EN}
    fam = client.get("/api/v1/family", headers=h)
    assert fam.status_code == 200, fam.text
    assert fam.json()["family_name"] == "My family"
    bad = client.post("/api/v1/family/join?code=NOPE00", headers=h)
    assert bad.status_code in (400, 404, 422)
    assert not CJK.search(bad.text)
    cn = client.get("/api/v1/family", headers=auth_headers).json()
    assert cn["family_name"] == "我的家庭"


# ── I-16：理由不再重复 ───────────────────────────────────────────
def test_reason_merges_time_and_season_into_one_phrase():
    from app.services.personal_home import _reason
    zh, basis = _reason([("time", "evening"), ("season", "autumn")], "zh")
    assert zh == "现在是秋季的晚上" and zh.count("现在是") == 1 and basis == ["time", "season"]
    en, _ = _reason([("time", "evening"), ("season", "autumn")], "en")
    assert en == "Because it is an autumn evening"
    solo, _ = _reason([("time", "evening")], "zh")
    assert solo == "现在是晚上"
    goal, _ = _reason([("goal", "sleep"), ("time", "night"), ("season", "winter")], "zh")
    assert goal == "你选的目标：睡个好觉，现在是冬季的深夜"


# ── I-09：资料库推荐为什么是空的要说清楚 ─────────────────────────────
def test_library_feed_explains_why_it_is_empty_when_nothing_is_reviewed(client, auth_headers):
    body = client.get("/api/v1/library/feed", headers=auth_headers).json()
    assert body["items"] == []
    assert body["eligible_count"] == 0 and body["empty_reason"] == "no_reviewed_entries"


# ── I-17：minor 分组有可见的差异化 ──────────────────────────────────
def test_age_profile_minor_is_differentiated_and_english_for_global(client, auth_headers):
    h = {**auth_headers, **EN}
    r = client.post("/api/v1/settings/age-profile", json={"birth_date": "2009-05-05"}, headers=h)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["age_group"] == "minor" and body["minor_mode"] is True
    assert body["reminders"]["break_every_minutes"] == 45 and body["reminders"]["quiet_from"] == "22:00"
    assert len(body["restrictions"]) == 3 and not CJK.search(str(body))
    again = client.get("/api/v1/settings/age-profile", headers=h).json()
    assert again == body
    zh = client.get("/api/v1/settings/age-profile", headers=auth_headers).json()
    assert CJK.search(zh["minor_notice"])


def test_age_profile_adult_has_no_minor_extras(client, auth_headers):
    r = client.post("/api/v1/settings/age-profile", json={"birth_date": "1990-01-01"}, headers=auth_headers).json()
    assert r == {"declared": True, "age_group": "adult"}
