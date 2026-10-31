"""Weekly home: day-3 / day-7 milestones, a week strip and an in-app-only recall card for lapsed users."""
import ast
import pathlib
import re
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest

from app.services import personal_home as ph
from app.services import personal_home_service as phs

SH = ZoneInfo("Asia/Shanghai")
TODAY = date(2026, 11, 9)


def acts(days_ago):
    return ph.Activity(completed=[("sleep", datetime.combine(TODAY - timedelta(days=d), datetime.min.time(), SH).replace(hour=20)) for d in days_ago])


def board(days_ago, lang="zh", **kw):
    now = datetime(2026, 11, 9, 9, 0, tzinfo=SH)
    return ph.compose(ph.Profile(lang=lang, goals=frozenset({"sleep"}), season="autumn", **kw), acts(days_ago), "u", now, "weekday")


def test_no_activity_has_no_milestone_recall_or_fake_week():
    b = board([])
    assert b["milestone"]["reached"] == 0 and b["milestone"]["text"] == "" and b["recall"] is None
    assert [d["done"] for d in b["week"]] == [False] * 7 and b["week"][-1]["today"] is True


@pytest.mark.parametrize("days,reached,just", [([0], 0, False), ([0, 1], 0, False), ([0, 1, 2], 3, True), ([0, 1, 2, 3], 3, False),
                                                ([0, 1, 2, 3, 4, 5], 3, False), (list(range(7)), 7, True), (list(range(9)), 7, False)])
def test_milestones_follow_the_real_streak(days, reached, just):
    m = board(days)["milestone"]
    assert (m["reached"], m["just_reached"]) == (reached, just)
    assert m["streak"] == len(days)


def test_progress_text_counts_down_to_the_next_milestone():
    m = board([0, 1], "en")["milestone"]
    assert m["next"] == {"day": 3, "days_left": 1} and "1 more day to reach day 3" in m["text"]
    assert board([0, 1, 2, 3], "zh")["milestone"]["next"] == {"day": 7, "days_left": 3}
    assert board(list(range(8)))["milestone"]["next"] is None


def test_streak_is_not_credited_when_yesterday_was_missed():
    assert board([2, 3, 4, 5])["milestone"]["reached"] == 0


def test_week_strip_marks_real_days_oldest_first():
    w = board([0, 2, 5])["week"]
    assert [d["date"] for d in w] == [(TODAY - timedelta(days=i)).isoformat() for i in range(6, -1, -1)]
    assert [d["done"] for d in w] == [False, True, False, False, True, False, True]


@pytest.mark.parametrize("gap,tier", [(2, None), (3, "short"), (6, "short"), (7, "week"), (13, "week"), (14, "long"), (60, "long")])
def test_recall_tiers(gap, tier):
    r = board([gap])["recall"]
    assert (r["tier"] if r else None) == tier
    if r:
        assert r["days_away"] == gap and r["delivery"] == "in_app_only" and r["dismissible"] is True


def test_recall_offers_the_lightest_card_and_never_a_catch_up():
    b = board([10])
    r = b["recall"]
    picked = [c for c in b["cards"] if c["id"] in ph.BY_ID]
    assert r["suggested_card_id"] == min(picked, key=lambda c: (c["duration_min"], c["id"]))["id"]
    assert not re.search(r"补|落下|错过|\d+ ?天没", r["text"]) and "miss" not in board([10], "en")["recall"]["text"].lower()


def test_recall_and_milestone_text_pass_the_forbidden_word_scan_in_both_languages():
    for lang in ("zh", "en"):
        for days in ([0, 1, 2], list(range(7)), [0, 1], [4], [9], [30]):
            b = board(days, lang)
            texts = [b["milestone"]["text"]] + ([b["recall"]["text"]] if b["recall"] else [])
            for t in texts:
                assert not ph.forbidden_hits(t, lang), (lang, days, t)
                if lang == "en":
                    assert not re.search(r"[\u3400-\u9fff]", t)


def test_personalisation_off_means_no_recall_and_no_milestone():
    b = ph.compose(ph.Profile(lang="zh", enabled=False), acts([10]), "u", datetime(2026, 11, 9, 9, tzinfo=SH))
    assert b.get("recall") is None and b.get("milestone") is None


def test_recall_is_in_app_only_nothing_here_can_push_sms_or_email():
    """Structural guard: the engine and its service import no sender, and recall never schedules anything."""
    root = pathlib.Path(ph.__file__).parent
    banned = ("push", "sms", "smtp", "twilio", "apns", "fcm", "email", "notification", "sendgrid")
    for name in ("personal_home.py", "personal_home_service.py"):
        tree = ast.parse((root / name).read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            mods = [a.name for a in node.names] if isinstance(node, ast.Import) else ([node.module or ""] if isinstance(node, ast.ImportFrom) else [])
            for m in mods:
                assert not any(b in m.lower() for b in banned), (name, m)


def _guest(client):
    r = client.post("/api/v1/auth/guest-login", json={})
    payload = r.json()
    token = payload.get("access_token") or payload["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def test_api_returns_recall_after_days_away_and_none_for_active_user(client, monkeypatch):
    h = _guest(client)
    client.post("/api/v1/seasons/onboarding/complete", json={"help_goal": "睡得更好"}, headers=h)
    assert client.post("/api/v1/personalization/action/complete", json={"action_type": "sleep", "completed": True}, headers=h).status_code == 200
    real_now = datetime.now(SH)
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: real_now)
    today = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert today["recall"] is None and today["milestone"]["reached"] == 0 and today["week"][-1]["done"] is True
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: real_now + timedelta(days=8))
    later = client.get("/api/v1/seasons/home/dashboard", headers=h).json()
    assert later["recall"]["tier"] == "week" and later["recall"]["delivery"] == "in_app_only"
    assert later["milestone"]["reached"] == 0
