"""Database side of the personalised home: reads what the user entered/did, calls the pure engine, remembers what was shown."""

from __future__ import annotations

import json
from datetime import date, datetime, timedelta, timezone
from typing import Optional
from zoneinfo import ZoneInfo

from sqlalchemy.orm import Session

from ..simple_models import UserSetting
from ..utils import cn_calendar, solar_term_calendar
from . import home_cards, personal_home as ph

SEEN_KEY = "behavior:seen_cards"
PERSONALIZATION_KEY = "profile:personalization"
CONSTITUTION_KEY = "profile:constitution"
SEEN_KEEP_DAYS = 30
CN_TZ = ZoneInfo("Asia/Shanghai")


def _read(session: Session, user_id: str, key: str):
    row = session.get(UserSetting, {"user_id": user_id, "key": key})
    if not row:
        return None
    try:
        return json.loads(row.value)
    except (TypeError, ValueError):
        return None


def _write(session: Session, user_id: str, key: str, value) -> None:
    session.merge(UserSetting(user_id=user_id, key=key, value=json.dumps(value, ensure_ascii=False)))


def set_preferences(session: Session, user_id: str, *, enabled: Optional[bool] = None, constitution: Optional[str] = None,
                    clear_constitution: bool = False) -> dict:
    if enabled is not None:
        _write(session, user_id, PERSONALIZATION_KEY, {"enabled": bool(enabled)})
    if clear_constitution:
        session.merge(UserSetting(user_id=user_id, key=CONSTITUTION_KEY, value="null"))
    elif constitution is not None:
        if constitution not in ph.CONSTITUTIONS:
            raise ValueError("unknown constitution label")
        _write(session, user_id, CONSTITUTION_KEY, {"label": constitution})
    session.commit()
    return preferences(session, user_id)


def preferences(session: Session, user_id: str) -> dict:
    flag = _read(session, user_id, PERSONALIZATION_KEY) or {}
    cons = (_read(session, user_id, CONSTITUTION_KEY) or {}).get("label")
    return {"personalization_enabled": flag.get("enabled", True), "constitution": cons,
            "constitution_options": list(ph.CONSTITUTIONS)}


def local_now(is_global: bool, tz_name: Optional[str], now_utc: Optional[datetime] = None) -> datetime:
    now_utc = now_utc or datetime.now(timezone.utc)
    if not is_global:
        return now_utc.astimezone(CN_TZ)
    try:
        return now_utc.astimezone(ZoneInfo(tz_name)) if tz_name else now_utc
    except Exception:
        return now_utc


def load_profile(session: Session, user_id: str, *, lang: str, is_global: bool, day: date, hemisphere: str) -> ph.Profile:
    onboarding = _read(session, user_id, home_cards.ONBOARDING_KEY) or {}
    goals = ph.goals_from_text(" ".join(str(onboarding.get(k) or "") for k in ("help_goal", "feeling")))
    flag = _read(session, user_id, PERSONALIZATION_KEY) or {}
    cons = None if is_global else (_read(session, user_id, CONSTITUTION_KEY) or {}).get("label")
    if is_global:
        season = ph.season_of(day, hemisphere)
    else:
        season = ph.season_of(day)
    from .age_policy import read_group

    return ph.Profile(
        lang=lang, goals=goals, support_time=ph.time_from_text(str(onboarding.get("support_time") or "")),
        constitution=cons if cons in ph.CONSTITUTIONS else None, life_stage=onboarding.get("life_stage"),
        age_group=read_group(session, user_id, day), season=season, enabled=flag.get("enabled", True),
    )


def load_activity(session: Session, user_id: str, tz) -> ph.Activity:
    log = _read(session, user_id, home_cards.ACTION_LOG_KEY) or []
    completed = []
    for item in log:
        if item.get("completed") and item.get("at"):
            cat = str(item.get("action_type") or "")
            completed.append((_category(cat), datetime.fromtimestamp(item["at"], tz)))
    seen = []
    for item in _read(session, user_id, SEEN_KEY) or []:
        try:
            seen.append((item["id"], date.fromisoformat(item["day"])))
        except (KeyError, ValueError):
            continue
    return ph.Activity(completed=completed, seen=seen)


def _category(action_type: str) -> str:
    t = action_type.lower()
    for words, g in ph.GOAL_WORDS:
        if any(w in t for w in words):
            return {"sleep": "sleep", "breathing": "breathing", "exercise": "exercise", "family": "family", "mood": "mood", "food": "food"}[g]
    return t or "other"


def remember_shown(session: Session, user_id: str, day: date, card_ids: list) -> None:
    kept = []
    for item in _read(session, user_id, SEEN_KEY) or []:
        try:
            if item["day"] != day.isoformat() and (day - date.fromisoformat(item["day"])).days <= SEEN_KEEP_DAYS:
                kept.append(item)
        except (KeyError, ValueError):
            continue
    kept += [{"id": cid, "day": day.isoformat()} for cid in card_ids if cid in ph.BY_ID]
    _write(session, user_id, SEEN_KEY, kept)
    session.commit()


def build(session: Session, user_id: str, *, lang: str, is_global: bool, hemisphere: str = "north",
          tz_name: Optional[str] = None, now_utc: Optional[datetime] = None, record: bool = True) -> dict:
    now = local_now(is_global, tz_name, now_utc)
    day = now.date()
    profile = load_profile(session, user_id, lang=lang, is_global=is_global, day=day, hemisphere=hemisphere)
    activity = load_activity(session, user_id, now.tzinfo)
    anchors: list = []
    daytype = "weekend" if day.weekday() >= 5 else "weekday"
    if not is_global:
        base = home_cards.build_dashboard(session, user_id, day)
        anchors = [c for c in base["suggestions"] if c["id"] in ("day_makeup", "day_back_to_work", "day_holiday", "day_first_workday", "term", "region")]
        kind, _ = cn_calendar.day_kind(day)
        daytype = "weekend" if kind in (cn_calendar.HOLIDAY, "weekend") else "weekday"
        if not profile.enabled:
            anchors = base["suggestions"]
    board = ph.compose(profile, activity, user_id, now, daytype, extra_cards=anchors)
    if record and profile.enabled:
        remember_shown(session, user_id, day, [c["id"] for c in board["cards"]])
    board["date"] = day.isoformat()
    board["time_of_day"] = ph.time_bucket(now.hour)
    return board
