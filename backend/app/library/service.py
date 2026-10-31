"""数据库侧：读取用户自己的设置与行为，调用纯函数排序，记住「看过什么、上次什么时候来」。"""

from __future__ import annotations

import json
from datetime import date, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from ..simple_models import UserSetting
from ..utils import solar_term_calendar
from . import feed as fd, store

PREFS_KEY = "library:prefs"
VISIT_KEY = "library:last_visit"
OPENED_KEY = "library:opened"
SHOWN_KEY = "library:shown"
# 以下键由个性化首页（shunshi #29）和 onboarding 写入；这里只读，不依赖那条 PR 的代码
ONBOARDING_KEY = "profile:onboarding"
CONSTITUTION_KEY = "profile:constitution"
PERSONALIZATION_KEY = "profile:personalization"

GOAL_WORDS = (
    (("睡", "失眠", "熬夜", "sleep", "rest"), "sleep"),
    (("压力", "放松", "焦虑", "减压", "stress", "relax", "calm", "anxi"), "breathing"),
    (("情绪", "心情", "mood", "happy"), "mood"),
    (("精神", "累", "疲劳", "活力", "运动", "energy", "move", "active", "fit"), "exercise"),
    (("家人", "家庭", "父母", "孩子", "family"), "family"),
    (("饮食", "吃", "food", "eat", "diet", "nutrition"), "food"),
)
KEEP_DAYS = 30


# solar_term_calendar 返回「春夏秋冬」；feed 里的季节键是英文（spring…）。不转换的话，节气主题条目在节气过后 4 天起会 KeyError → /library/feed 500。
_SEASON_KEY = {"春": "spring", "夏": "summer", "秋": "autumn", "冬": "winter"}


def _read(session: Session, uid: str, key: str):
    row = session.get(UserSetting, {"user_id": uid, "key": key})
    if not row:
        return None
    try:
        return json.loads(row.value)
    except (TypeError, ValueError):
        return None


def _write(session: Session, uid: str, key: str, value) -> None:
    session.merge(UserSetting(user_id=uid, key=key, value=json.dumps(value, ensure_ascii=False)))


def goals_from_text(text: str) -> frozenset:
    try:  # 个性化首页已合入时用它的同一份词表，保证两处口径一致
        from ..services import personal_home as ph

        return ph.goals_from_text(text)
    except Exception:  # noqa: BLE001
        t = (text or "").lower()
        return frozenset(g for words, g in GOAL_WORDS if any(w in t for w in words))


def preferences(session: Session, uid: str) -> dict:
    p = _read(session, uid, PREFS_KEY) or {}
    return {"enabled": bool(p.get("enabled", True)), "followed": [t for t in p.get("followed", []) if t in fd.TOPICS], "muted": [t for t in p.get("muted", []) if t in fd.TOPICS]}


def set_preferences(session: Session, uid: str, *, enabled: Optional[bool] = None, follow=(), unfollow=(), mute=(), unmute=()) -> dict:
    p = preferences(session, uid)
    bad = [t for t in (*follow, *unfollow, *mute, *unmute) if t not in fd.TOPICS]
    if bad:
        raise ValueError(f"unknown topic: {bad[0]}")
    if enabled is not None:
        p["enabled"] = bool(enabled)
    fol, mut = set(p["followed"]), set(p["muted"])
    fol |= set(follow); fol -= set(unfollow); fol -= set(mute)
    mut |= set(mute); mut -= set(unmute); mut -= set(follow)
    p["followed"], p["muted"] = sorted(fol), sorted(mut)
    _write(session, uid, PREFS_KEY, p)
    session.commit()
    return p


def _day_map(session, uid, key, today) -> dict:
    out = {}
    for it in _read(session, uid, key) or []:
        try:
            d = date.fromisoformat(it["day"])
        except (KeyError, ValueError):
            continue
        if (today - d).days <= KEEP_DAYS:
            out[it["id"]] = max(d, out.get(it["id"], d))
    return out


def load_signals(session: Session, uid: str, today: date, lang: str = "zh") -> fd.Signals:
    prefs = preferences(session, uid)
    onboarding = _read(session, uid, ONBOARDING_KEY) or {}
    goals = goals_from_text(" ".join(str(onboarding.get(k) or "") for k in ("help_goal", "feeling")))
    cons = (_read(session, uid, CONSTITUTION_KEY) or {}).get("label")
    flag = _read(session, uid, PERSONALIZATION_KEY) or {}
    term = solar_term_calendar.term_on(today)
    start = solar_term_calendar.term_start(today)
    age_group = None
    try:
        from ..services.age_policy import read_group

        age_group = read_group(session, uid, today)
    except Exception:  # noqa: BLE001
        pass
    lv = _read(session, uid, VISIT_KEY)
    return fd.Signals(
        lang=lang, enabled=prefs["enabled"] and flag.get("enabled", True), goals=goals, constitution=cons if cons in ("平和", "气虚", "阳虚", "阴虚", "痰湿", "湿热", "血瘀", "气郁") else None,
        season=_SEASON_KEY[solar_term_calendar.season_of(term)], term=term, days_since_term=(today - start).days if start else None,
        age_group="minor" if age_group in ("minor", "child", "teen") else age_group, followed=frozenset(prefs["followed"]), muted=frozenset(prefs["muted"]),
        opened=_day_map(session, uid, OPENED_KEY, today), shown=_day_map(session, uid, SHOWN_KEY, today),
        last_visit=date.fromisoformat(lv["day"]) if isinstance(lv, dict) and lv.get("day") else None)


def build_feed(session: Session, uid: str, today: date, lang: str = "zh", *, record: bool = True, limit: int = 6, document=None, state=None) -> dict:
    sig = load_signals(session, uid, today, lang)
    items = store.annotated(today, lang, document=document, state=state)
    out = fd.rank(items, sig, uid, today, limit=limit)
    out.update({"topics": fd.topic_list(sig), "since": sig.last_visit.isoformat() if sig.last_visit else None, "generated_for": today.isoformat(),
                "note": "推荐只用你自己填写的目标、关注的主题和在应用里读过的内容；资料来自官方文件，仅供了解，不是诊断或治疗建议。可随时关闭。" if lang == "zh" else
                "Picks use only what you entered, the topics you follow and what you read in the app. Not medical advice. You can turn this off at any time."})
    if record and sig.enabled and out["items"]:
        keep = [x for x in (_read(session, uid, SHOWN_KEY) or []) if x.get("day") != today.isoformat() and _recent(x, today)]
        keep += [{"id": i["id"], "day": today.isoformat()} for i in out["items"]]
        _write(session, uid, SHOWN_KEY, keep)
        session.commit()
    return out


def visit_badges(session: Session, uid: str, today: date, items: list) -> dict:
    """列表里每条的「相对你上次来访」标记：new / updated。没有来访记录（第一次来）时不标，避免全是「新」。"""
    lv = _read(session, uid, VISIT_KEY)
    if not (isinstance(lv, dict) and lv.get("day")):
        return {}
    try:
        ref = date.fromisoformat(lv["day"])
    except ValueError:
        return {}
    out = {}
    for e in items:
        appr, upd = fd._d(e.get("approved_at")), fd._d(e.get("updated_on"))
        if appr and appr > ref:
            out[e["id"]] = "new"
        elif upd and upd > ref:
            out[e["id"]] = "updated"
    return out


def _recent(item, today) -> bool:
    try:
        return (today - date.fromisoformat(item["day"])).days <= KEEP_DAYS
    except (KeyError, ValueError):
        return False


def record_visit(session: Session, uid: str, today: date) -> None:
    _write(session, uid, VISIT_KEY, {"day": today.isoformat()})
    session.commit()


def record_open(session: Session, uid: str, entry_id: str, today: date) -> None:
    keep = [x for x in (_read(session, uid, OPENED_KEY) or []) if _recent(x, today)]
    keep.append({"id": entry_id, "day": today.isoformat()})
    _write(session, uid, OPENED_KEY, keep[-200:])
    session.commit()


def home_card(session: Session, uid: str, today: date, lang: str = "zh") -> Optional[dict]:
    """给个性化首页用：返回一张卡（或 None）。不记录「已展示」，避免首页刷新影响资料库里的排序。"""
    return fd.home_card(build_feed(session, uid, today, lang, record=False), lang)
