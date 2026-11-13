"""首页「今日推荐」。

只给当下节气的日常饮食和作息，用白话。不展示药效、主治、毒性，也不展示穴位主治。
季节按北京时间的节气表，不用公历月份（11 月立冬后是冬，不是秋）。
孕期 / 哺乳期排除名单直接读现有的 FORBIDDEN_HERBS_DATA、孕期名单和哺乳期忌口，不改那些表。
一条内容写不出安全的白话，就丢掉，改用下面的日常建议。
"""

from __future__ import annotations

import json
from datetime import date
from typing import Any

from ..safety.contraindications import flags_from_profile, names_for
from ..utils import solar_term_calendar

# 首页上不能出现的药效、主治、毒性用语。命中就整条丢掉，不截半句来凑。
EFFICACY_TERMS = (
    "补血",
    "活血",
    "调经",
    "止痛",
    "通乳",
    "乳汁",
    "有毒",
    "炮制",
    "功效",
    "疗效",
    "主治",
    "禁用",
    "慎用",
    "本草",
    "穴位",
    "温补肾阳",
)

_ACUPOINT_TYPES = frozenset({"acupressure", "acupoint", "穴位"})
_FOOD_REST_TYPES = frozenset({"food_therapy", "recipe", "food", "tea", "sleep_tip", "sleep", "rest", "tips"})
_VAGUE_FOODS = ("辛辣", "油腻", "咖啡因", "酒精", "腌制", "烧烤", "冷饮", "冰镇")

# 白话的饮食 / 作息。不含药效，也不点名禁忌食材。
PLAIN_BY_SEASON: dict[str, tuple[dict[str, str], ...]] = {
    "spring": (
        {"id": "home-spring-greens", "type": "food", "category": "饮食", "title": "午饭加一盘青菜", "description": "午饭加一盘应季绿叶菜，少放油和盐。"},
        {"id": "home-spring-walk", "type": "rest", "category": "作息", "title": "午后走一走", "description": "午后出去走十分钟，回来喝杯温水。"},
        {"id": "home-spring-sleep", "type": "rest", "category": "作息", "title": "今晚早一点睡", "description": "今晚把灯调暗，比平时早一点上床。"},
    ),
    "summer": (
        {"id": "home-summer-water", "type": "food", "category": "饮食", "title": "多喝白水", "description": "天热时多喝白水，少喝冰的。"},
        {"id": "home-summer-rest", "type": "rest", "category": "作息", "title": "午饭后歇一会儿", "description": "午饭后闭眼歇二十分钟。"},
        {"id": "home-summer-shade", "type": "rest", "category": "作息", "title": "避开正午晒", "description": "外出带水，把走动放在早上或傍晚。"},
    ),
    "autumn": (
        {"id": "home-autumn-water", "type": "food", "category": "饮食", "title": "白天喝温水", "description": "空气干，白天多喝几口温水。"},
        {"id": "home-autumn-layer", "type": "rest", "category": "作息", "title": "早晚加一件衣服", "description": "早晚凉，出门加一件外套。"},
        {"id": "home-autumn-pear", "type": "food", "category": "饮食", "title": "晚饭后可以吃一点梨", "description": "晚饭后可以吃一点梨，或者喝温水。"},
    ),
    "winter": (
        {"id": "home-winter-porridge", "type": "food", "category": "饮食", "title": "晚饭喝一碗热粥", "description": "晚饭喝一碗热粥或热面条，别吃得太晚。"},
        {"id": "home-winter-sleep", "type": "rest", "category": "作息", "title": "今晚早点休息", "description": "天黑得早，今晚早点放下手机休息。"},
        {"id": "home-winter-warm", "type": "rest", "category": "作息", "title": "出门把脖子和脚盖暖", "description": "出门把脖子和脚盖暖，路上走慢一点。"},
    ),
}

_SEASON_EN = {"春": "spring", "夏": "summer", "秋": "autumn", "冬": "winter"}


def season_on(day: date) -> str:
    """节气季节。立冬起算冬，不按「11 月 = 秋」。"""
    term = solar_term_calendar.term_on(day)
    return _SEASON_EN[solar_term_calendar.season_of(term)]


def recommend_day(request: Any = None, settings: Any = None) -> date:
    """北京时间的今天。测试环境的 X-Shunshi-Test-Now 与首页卡片用同一个钟。"""
    pinned = None
    if request is not None and settings is not None:
        from .personal_home_service import test_clock

        pinned = test_clock(request, settings)
    if pinned is None:
        return solar_term_calendar.beijing_today()
    return pinned.astimezone(solar_term_calendar.BEIJING).date()


def exclusion_names(flags: frozenset[str]) -> tuple[str, ...]:
    """孕期读 FORBIDDEN_HERBS_DATA 和已有孕期名单；哺乳期读忌口表。不改这些表。"""
    names = list(names_for(flags))
    if "pregnancy" in flags:
        from ..router.maternity import FORBIDDEN_HERBS_DATA

        names.extend(str(row["name"]) for row in FORBIDDEN_HERBS_DATA if row.get("name"))
    if "breastfeeding" in flags:
        from ..router.maternity import BREASTFEEDING_AVOID_FOODS

        for row in BREASTFEEDING_AVOID_FOODS:
            food = str(row.get("food") or "")
            head = food.split("（")[0].strip()
            if not head or any(vague in head for vague in _VAGUE_FOODS):
                continue
            parts = [part.strip() for part in head.split("、")]
            names.extend(part for part in parts if part and not any(vague in part for vague in _VAGUE_FOODS))
    return tuple(sorted({name for name in names if name}, key=len, reverse=True))


def text_blocked_for_stage(text: str, life_stage: str | None) -> bool:
    flags = flags_from_profile(life_stage=life_stage)
    if not flags or not text:
        return False
    return any(name in text for name in exclusion_names(flags))


def _is_acupoint(item: dict) -> bool:
    kind = str(item.get("type") or item.get("category") or "")
    title = str(item.get("title") or "")
    return kind in _ACUPOINT_TYPES or title.endswith("穴")


def _pieces(item: dict) -> list[str]:
    parts: list[str] = []
    for key in ("title", "description", "subtitle", "effect", "reason"):
        value = item.get(key)
        if isinstance(value, str) and value:
            parts.append(value)
    for key in ("benefits", "tags", "ingredients"):
        value = item.get(key)
        if isinstance(value, str):
            parts.append(value)
        elif isinstance(value, list):
            parts.extend(str(piece) for piece in value if piece)
    return parts


def _blob(item: dict) -> str:
    return "".join(_pieces(item))


def _has_efficacy(text: str) -> bool:
    return any(term in text for term in EFFICACY_TERMS)


def _item_season(item: dict) -> str | None:
    for key in ("season_tag", "season"):
        value = item.get(key)
        if isinstance(value, str) and value in PLAIN_BY_SEASON:
            return value
    return None


def _plain_copy(item: dict, season: str) -> dict | None:
    """没有安全白话就不返回。药效、穴位主治、季不对、禁忌名都丢掉。"""
    if _is_acupoint(item):
        return None
    kind = str(item.get("type") or "")
    if kind and kind not in _FOOD_REST_TYPES and kind not in {"饮食", "作息"}:
        return None
    item_season = _item_season(item)
    if item_season != season:
        return None
    description = str(item.get("description") or item.get("subtitle") or "").strip()
    title = str(item.get("title") or "").strip()
    if not title or not description:
        return None
    blob = _blob(item)
    if _has_efficacy(blob):
        return None
    category = item.get("category") if item.get("category") in {"饮食", "作息"} else ("饮食" if kind in {"food", "food_therapy", "recipe", "tea"} else "作息")
    return {
        "id": item.get("id"),
        "title": title,
        "description": description,
        "type": "food" if category == "饮食" else "rest",
        "category": category,
        "season": season,
        "tags": [],
        "benefits": [],
        "effect": None,
    }


def life_stage_for(session: Any, user_id: str | None) -> str | None:
    if session is None or not user_id:
        return None
    try:
        from ..simple_models import UserSetting
        from .home_cards import ONBOARDING_KEY

        row = session.get(UserSetting, {"user_id": user_id, "key": ONBOARDING_KEY})
        if not row or not row.value:
            return None
        data = json.loads(row.value)
    except (TypeError, ValueError, json.JSONDecodeError):
        return None
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    stage = data.get("life_stage")
    return str(stage) if stage else None


def select_home_items(
    items: list[dict],
    day: date,
    life_stage: str | None = None,
    limit: int = 6,
) -> list[dict]:
    """当前节气的白话饮食和作息。不安全的条目丢掉，不够就用日常建议补上。"""
    season = season_on(day)
    flags = flags_from_profile(life_stage=life_stage)
    blocked = exclusion_names(flags)

    def allowed(text: str) -> bool:
        return not any(name in text for name in blocked)

    picked: list[dict] = []
    seen: set[str] = set()

    def take(item: dict, rank: int) -> None:
        if len(picked) >= limit:
            return
        safe = _plain_copy(item, season)
        if safe is None:
            return
        blob = f"{safe['title']}{safe['description']}"
        if not allowed(blob):
            return
        key = str(safe["id"] or safe["title"])
        if key in seen:
            return
        seen.add(key)
        picked.append({**safe, "_rank": rank})

    for plain in PLAIN_BY_SEASON[season]:
        take({**plain, "season": season}, 0)
    for item in items:
        kind = str(item.get("type") or "")
        rank = 1 if kind in {"food_therapy", "recipe", "food", "tea", "sleep_tip", "sleep", "rest"} else 2
        take(item, rank)
    picked.sort(key=lambda row: (row["_rank"], str(row["id"])))
    out = []
    for row in picked[:limit]:
        row.pop("_rank", None)
        out.append(row)
    return out
