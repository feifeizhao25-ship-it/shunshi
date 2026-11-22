"""2026-11-22 顺时实测（顺1 第1-7天）：首页连续天数 / 一周打卡条只认 /personalization/action/complete，
两个客户端都没调它；日记打卡写的是 gamification。结果用户写了日记，「我的」页养生天数 1、首页仍是 0 天。

现在两边是一套进度：
- 首页把打卡 / 日记的日子算作当天做过一件小事（personal_home_service.load_activity）；
- 首页「做完了」走 /action/complete，同时记一次今天的打卡（同一天只记一次、只发一次积分）。
"""
from datetime import datetime
from zoneinfo import ZoneInfo

import pytest

from app.services import personal_home_service as phs

SH = ZoneInfo("Asia/Shanghai")


def _guest(client):
    r = client.post("/api/v1/auth/guest-login", json={})
    payload = r.json()
    token = payload.get("access_token") or payload["data"]["token"]
    uid = payload.get("user_id") or (payload.get("data") or {}).get("user_id") or (payload.get("data") or {}).get("user", {}).get("id")
    return {"Authorization": f"Bearer {token}"}, uid


def _pin_today(monkeypatch):
    now = datetime.now(SH).replace(hour=20, minute=0, second=0, microsecond=0)
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: now)
    return now


def test_diary_day_shows_on_home_week_strip_and_streak(client, monkeypatch):
    h, _ = _guest(client)
    _pin_today(monkeypatch)
    client.post("/api/v1/seasons/onboarding/complete", json={"help_goal": "睡得更好"}, headers=h)
    before = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert before["week"][-1]["done"] is False

    me = client.get("/api/v1/auth/me", headers=h).json()
    uid = (me.get("data") or me).get("id") or (me.get("data") or me).get("user_id") or (me.get("data") or {}).get("user", {}).get("id")
    assert uid, me
    r = client.post("/api/v1/journal/entry", json={"user_id": uid, "mood": 4, "energy": 3, "sleep_quality": 3, "notes": "测试"}, headers=h)
    assert r.status_code == 200, r.text
    assert r.json()["data"]["checkin"]["current_streak"] == 1

    after = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert after["week"][-1]["done"] is True
    assert after["streak"] is not None


def test_home_action_counts_as_todays_checkin_once(client, monkeypatch):
    h, _ = _guest(client)
    _pin_today(monkeypatch)
    first = client.post("/api/v1/personalization/action/complete", json={"action_type": "sleep", "completed": True}, headers=h).json()["data"]
    assert first["recorded"] is True
    assert first["checkin"]["checked_in"] is True and first["checkin"]["points_earned"] == 10
    second = client.post("/api/v1/personalization/action/complete", json={"action_type": "breathing", "completed": True}, headers=h).json()["data"]
    assert second["checkin"]["checked_in"] is False and second["checkin"]["points_earned"] == 0
    assert second["total_recorded"] == 2

    me = client.get("/api/v1/gamification/me", headers=h).json()
    data = me.get("data") or me
    assert data["points"] == 10
    home = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert home["week"][-1]["done"] is True


def test_not_completed_action_awards_nothing(client, monkeypatch):
    h, _ = _guest(client)
    _pin_today(monkeypatch)
    data = client.post("/api/v1/personalization/action/complete", json={"action_type": "sleep", "completed": False}, headers=h).json()["data"]
    assert data["checkin"] is None
    home = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert home["week"][-1]["done"] is False


def test_progress_days_failure_keeps_home_working(client, monkeypatch):
    h, _ = _guest(client)
    _pin_today(monkeypatch)
    import app.router.gamification as g

    def boom(db, user_id):
        raise RuntimeError("库连不上")

    monkeypatch.setattr(g, "activity_days", boom)
    r = client.get("/api/v1/seasons/home/dashboard", headers=h)
    assert r.status_code == 200
