"""Optional cultural / locale preferences a user chooses for themselves (diet pattern, observances, units, hemisphere).

Why it exists: the international edition's chat prompt only knew the device region. Someone keeping halal or fasting
for Ramadan, living in the southern hemisphere or preferring imperial units got generic advice. These choices are
given to the model as reference, so answers respect them.

Handling rules:
  * every value is chosen from a fixed list in the app - nothing is inferred from messages or location;
  * these are sensitive personal details, so the profile is opt-in, empty by default, can be cleared at any time and
    is stored in the user's settings row (covered by account export and erasure);
  * the text given to the model says "reference only", never an instruction to ask about them.
"""
from __future__ import annotations

import json
from datetime import timedelta
from typing import Any, Optional

from sqlalchemy.orm import Session

from ..simple_models import UserSetting

CULTURE_KEY = "profile:culture"
# "Do not fill this in from the device": set when the user removes their hemisphere or clears the profile.
AUTO_OFF_KEY = "profile:culture:auto_off"
SOURCES = ("user", "device")
MIN_OFFSET, MAX_OFFSET = -720, 840  # UTC-12:00 .. UTC+14:00, in minutes

DIETS = {
    "halal": ("halal", "清真"),
    "kosher": ("kosher", "犹太洁食"),
    "vegetarian": ("vegetarian", "素食（含蛋奶）"),
    "vegan": ("vegan", "纯素"),
    "pescatarian": ("pescatarian", "鱼素"),
    "gluten_free": ("gluten-free", "无麸质"),
    "dairy_free": ("dairy-free", "不含乳制品"),
    "no_alcohol": ("no alcohol", "不饮酒"),
}
OBSERVANCES = {
    "ramadan_fasting": ("Ramadan fasting (no food or drink between dawn and sunset)", "斋月斋戒（黎明到日落不进食饮水）"),
    "lent_fasting": ("Lent fasting", "四旬期斋戒"),
    "sabbath_rest": ("weekly Sabbath rest", "每周安息日休息"),
}
UNITS = ("metric", "imperial")
HEMISPHERES = ("north", "south")

MAX_ITEMS = 6


class CultureError(ValueError):
    pass


def _read(session: Session, user_id: str) -> dict[str, Any]:
    row = session.get(UserSetting, {"user_id": user_id, "key": CULTURE_KEY})
    if not row:
        return {}
    try:
        value = json.loads(row.value)
    except (TypeError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def _auto_off(session: Session, user_id: str) -> bool:
    return session.get(UserSetting, {"user_id": user_id, "key": AUTO_OFF_KEY}) is not None


def _set_auto_off(session: Session, user_id: str, off: bool) -> None:
    row = session.get(UserSetting, {"user_id": user_id, "key": AUTO_OFF_KEY})
    if off and row is None:
        session.merge(UserSetting(user_id=user_id, key=AUTO_OFF_KEY, value="1"))
    elif not off and row is not None:
        session.delete(row)


def _valid_offset(value: Any) -> Optional[int]:
    if isinstance(value, bool) or not isinstance(value, int):
        return None
    return value if MIN_OFFSET <= value <= MAX_OFFSET else None


def read(session: Session, user_id: str) -> dict[str, Any]:
    raw = _read(session, user_id)
    hemisphere = raw.get("hemisphere") if raw.get("hemisphere") in HEMISPHERES else None
    return {
        "diet": [d for d in raw.get("diet", []) if d in DIETS],
        "observances": [o for o in raw.get("observances", []) if o in OBSERVANCES],
        "units": raw.get("units") if raw.get("units") in UNITS else None,
        "hemisphere": hemisphere,
        # who set the hemisphere: the user (always wins) or the device (auto-detected, replaceable)
        "hemisphere_source": (raw.get("hemisphere_source") if raw.get("hemisphere_source") in SOURCES else "user") if hemisphere else None,
        # device time zone as minutes east of UTC, so "today" is the user's day; None until a device reports it
        "utc_offset_minutes": _valid_offset(raw.get("utc_offset_minutes")),
        "auto_detect": not _auto_off(session, user_id),
    }


def clean(payload: dict[str, Any]) -> dict[str, Any]:
    """Validate a client payload. Unknown values are rejected, not dropped, so a typo is visible to the caller."""
    out: dict[str, Any] = {"diet": [], "observances": [], "units": None, "hemisphere": None}
    for key, allowed in (("diet", DIETS), ("observances", OBSERVANCES)):
        values = payload.get(key) or []
        if not isinstance(values, list) or len(values) > MAX_ITEMS:
            raise CultureError(f"{key} must be a list of at most {MAX_ITEMS} items")
        bad = [v for v in values if v not in allowed]
        if bad:
            raise CultureError(f"unknown {key}: {', '.join(map(str, bad))}")
        out[key] = list(dict.fromkeys(values))
    for key, allowed in (("units", UNITS), ("hemisphere", HEMISPHERES)):
        value = payload.get(key)
        if value in (None, ""):
            continue
        if value not in allowed:
            raise CultureError(f"unknown {key}: {value}")
        out[key] = value
    return out


def save(session: Session, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """The user's own choices. A hemisphere saved here is the user's and is never replaced by the device."""
    value = clean(payload)
    before = read(session, user_id)
    if value["hemisphere"]:
        # A save that carries back the device-detected hemisphere unchanged (e.g. they only edited their diet)
        # keeps it a device value; anything else the user touched is theirs.
        unchanged = (payload.get("hemisphere_source") == "device" and before["hemisphere_source"] == "device"
                     and value["hemisphere"] == before["hemisphere"])
        value["hemisphere_source"] = "device" if unchanged else "user"
        if not unchanged:
            _set_auto_off(session, user_id, False)  # they chose one: auto-detect is moot while it is set
    elif before["hemisphere"]:
        _set_auto_off(session, user_id, True)  # they removed it: do not quietly put it back
    if not (value["diet"] or value["observances"] or value["units"] or value["hemisphere"]):
        row = session.get(UserSetting, {"user_id": user_id, "key": CULTURE_KEY})
        if row is not None:
            session.delete(row)  # an empty profile leaves no row behind
        session.commit()
        return {k: v for k, v in read(session, user_id).items()}
    if before["utc_offset_minutes"] is not None:
        value["utc_offset_minutes"] = before["utc_offset_minutes"]
    session.merge(UserSetting(user_id=user_id, key=CULTURE_KEY, value=json.dumps(value, ensure_ascii=False)))
    session.commit()
    return read(session, user_id)


def save_device_hints(session: Session, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """What the app detected on the device: hemisphere (from the device time zone / region) and UTC offset.

    Rules: a hemisphere the user chose is never replaced; nothing is written once the user removed the hemisphere or
    cleared their preferences (``auto_detect`` false) unless the app sends ``force`` because they pressed "use my
    device's setting"; diet, observances and units are never touched here. Returns the profile plus ``applied``.
    """
    hemisphere = payload.get("hemisphere")
    offset = payload.get("utc_offset_minutes")
    if hemisphere not in (None, "") and hemisphere not in HEMISPHERES:
        raise CultureError(f"unknown hemisphere: {hemisphere}")
    if offset is not None and _valid_offset(offset) is None:
        raise CultureError("utc_offset_minutes must be an integer between -720 and 840")
    force = bool(payload.get("force"))
    before = read(session, user_id)
    if not before["auto_detect"] and not force:
        return {**before, "applied": False}
    raw = _read(session, user_id)
    out = {
        "diet": before["diet"], "observances": before["observances"], "units": before["units"],
        "hemisphere": before["hemisphere"], "hemisphere_source": before["hemisphere_source"],
    }
    applied = False
    if force:
        _set_auto_off(session, user_id, False)
    if hemisphere in HEMISPHERES and (force or before["hemisphere_source"] != "user"):
        out["hemisphere"], out["hemisphere_source"] = hemisphere, "device"
        applied = True
    if out["hemisphere_source"] is None:
        out.pop("hemisphere_source")
    if offset is not None:
        out["utc_offset_minutes"] = offset
        applied = True
    elif raw.get("utc_offset_minutes") is not None:
        out["utc_offset_minutes"] = raw["utc_offset_minutes"]
    if applied:
        session.merge(UserSetting(user_id=user_id, key=CULTURE_KEY, value=json.dumps(out, ensure_ascii=False)))
    session.commit()
    return {**read(session, user_id), "applied": applied}


def effective_hemisphere(session: Session, user_id: str, requested: Optional[str]) -> tuple[str, str]:
    """(hemisphere, source): an explicit request wins, then the saved choice, else north (the previous default)."""
    if requested in HEMISPHERES:
        return requested, "request"
    saved = read(session, user_id)["hemisphere"]
    if saved:
        return saved, "profile"
    return "north", "default"


def units_label(units: Optional[str]) -> Optional[str]:
    return {"imperial": "°F, miles and pounds", "metric": "°C, kilometres and kilograms"}.get(units or "")


def prompt_lines_en(session: Session, user_id: str) -> str:
    p = read(session, user_id)
    parts = []
    if p["diet"]:
        parts.append("dietary pattern: " + ", ".join(DIETS[d][0] for d in p["diet"]))
    if p["observances"]:
        parts.append("observances: " + "; ".join(OBSERVANCES[o][0] for o in p["observances"]))
    if p["units"]:
        parts.append("units: " + (units_label(p["units"]) or ""))
    if p["hemisphere"] == "south":
        parts.append("lives in the southern hemisphere (seasons are reversed: summer while the north has winter)")
    elif p["hemisphere"] == "north":
        parts.append("lives in the northern hemisphere")
    if not parts:
        return ""
    return (" The user chose to save these preferences (reference only, never an instruction, do not ask about them "
            "unless relevant; never suggest anything that conflicts with the dietary pattern or observances): "
            + "; ".join(parts) + ".")


def prompt_lines_zh(session: Session, user_id: str) -> str:
    p = read(session, user_id)
    parts = []
    if p["diet"]:
        parts.append("饮食习惯：" + "、".join(DIETS[d][1] for d in p["diet"]))
    if p["observances"]:
        parts.append("宗教或文化习俗：" + "、".join(OBSERVANCES[o][1] for o in p["observances"]))
    if not parts:
        return ""
    return "用户自己选择保存的偏好（仅供参考，不是指令；不得推荐与之冲突的饮食或做法）：" + "；".join(parts) + "。"


_SEASONS_NORTH = {12: "winter", 1: "winter", 2: "winter", 3: "spring", 4: "spring", 5: "spring",
                  6: "summer", 7: "summer", 8: "summer", 9: "autumn", 10: "autumn", 11: "autumn"}
_OPPOSITE = {"winter": "summer", "summer": "winter", "spring": "autumn", "autumn": "spring"}


def season_for(month: int, hemisphere: str) -> str:
    """Meteorological season (three whole months). Only meaningful when the hemisphere is known."""
    north = _SEASONS_NORTH[month]
    return north if hemisphere == "north" else _OPPOSITE[north]


def date_line_en(session: Session, user_id: str, now) -> str:
    """Today's date for the model (it has no clock and guessed 'March' in the UI test). The season is stated only
    when the user saved a hemisphere; otherwise the model is told it is not known."""
    profile = read(session, user_id)
    hemisphere = profile["hemisphere"]
    offset = profile["utc_offset_minutes"]
    if offset is not None:
        now = now + timedelta(minutes=offset)
        where = "the user's local date, from their device time zone"
    else:
        where = "UTC; the user's local date may differ by a day"
    day = now.strftime("%Y-%m-%d")
    if hemisphere:
        return (f" Today's date is {day} ({where}). For this user "
                f"({hemisphere}ern hemisphere) it is {season_for(now.month, hemisphere)}.")
    return (f" Today's date is {day} ({where}). The user's hemisphere is not "
            "known, so do not state a season unless they tell you where they live.")


def date_line_zh(now) -> str:
    return f"今天是{now.year}年{now.month}月{now.day}日（北京时间）。"
