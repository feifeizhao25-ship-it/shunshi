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
from typing import Any, Optional

from sqlalchemy.orm import Session

from ..simple_models import UserSetting

CULTURE_KEY = "profile:culture"

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


def read(session: Session, user_id: str) -> dict[str, Any]:
    raw = _read(session, user_id)
    return {
        "diet": [d for d in raw.get("diet", []) if d in DIETS],
        "observances": [o for o in raw.get("observances", []) if o in OBSERVANCES],
        "units": raw.get("units") if raw.get("units") in UNITS else None,
        "hemisphere": raw.get("hemisphere") if raw.get("hemisphere") in HEMISPHERES else None,
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
    value = clean(payload)
    if not (value["diet"] or value["observances"] or value["units"] or value["hemisphere"]):
        row = session.get(UserSetting, {"user_id": user_id, "key": CULTURE_KEY})
        if row is not None:
            session.delete(row)  # an empty profile leaves no row behind
    else:
        session.merge(UserSetting(user_id=user_id, key=CULTURE_KEY, value=json.dumps(value, ensure_ascii=False)))
    session.commit()
    return value


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
    day = now.strftime("%Y-%m-%d")
    hemisphere = read(session, user_id)["hemisphere"]
    if hemisphere:
        return (f" Today's date is {day} (UTC; the user's local date may differ by a day). For this user "
                f"({hemisphere}ern hemisphere) it is {season_for(now.month, hemisphere)}.")
    return (f" Today's date is {day} (UTC; the user's local date may differ by a day). The user's hemisphere is not "
            "known, so do not state a season unless they tell you where they live.")


def date_line_zh(now) -> str:
    return f"今天是{now.year}年{now.month}月{now.day}日（北京时间）。"
