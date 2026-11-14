"""首页「今日推荐」。

只给当下节气的日常饮食和作息，用白话。名单按允许来：节气白话条目，
再加上明确标了 home_safe 的内容。没有这道标记的种子内容不会进首页。
药效说法和克数、剂量是第二道：命中就整条丢掉，不截半句来凑。
季节按北京时间的节气表，不用公历月份（11 月立冬后是冬，不是秋）。
孕期 / 哺乳期排除名单直接读现有的 FORBIDDEN_HERBS_DATA、孕期名单和哺乳期忌口，不改那些表。
这两类人生阶段里，没核对过的条目（茶饮、带配料、说不清安不安全）直接丢掉。
句子里写了茶，也整句丢掉，和时辰表一样，不改写成新文案。
热粥这类白话、又没有点到禁忌食材的，保留。
"""

from __future__ import annotations

import json
import re
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
    "补中益气",
    "滋补",
    "固精",
    "润肠",
    "通便",
    "感冒",
    "尤宜",
    "引火归元",
    "滋养气血",
    "运化",
    "清心导浊",
)

# 补X / 滋X / 益X，以及同一类药效说法。词表没写全的句子也靠这里丢掉。
_EFFICACY_CLASS = re.compile(
    r"补[\u4e00-\u9fff]|滋[\u4e00-\u9fff]|益[\u4e00-\u9fff]"
    r"|固精|润肠|通便|感冒|尤宜|引火归元|滋养气血|运化|清心导浊"
)
# 克数和剂量。时长（10分钟）不算。
_DOSAGE = re.compile(r"\d+\s*(?:mg|ml|g|毫克|毫升|克|片|颗|枚|勺)", re.IGNORECASE)

_TEA_WORD = re.compile(r"\btea\b", re.IGNORECASE)
_ACUPOINT_TYPES = frozenset({"acupressure", "acupoint", "穴位"})
_FOOD_REST_TYPES = frozenset({"food_therapy", "recipe", "food", "tea", "sleep_tip", "sleep", "rest", "tips"})
_VAGUE_FOODS = ("辛辣", "油腻", "咖啡因", "酒精", "腌制", "烧烤", "冷饮", "冰镇")
_HOME_SAFE_FLAGS = frozenset({"1", "true", "yes"})

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


def text_has_tea_wording(text: str) -> bool:
    """茶，或英文单词 tea。时辰表对孕期 / 哺乳期也不留茶饮说法。"""
    if not text:
        return False
    if "茶" in text:
        return True
    return _TEA_WORD.search(text) is not None


def text_blocked_for_stage(text: str, life_stage: str | None) -> bool:
    flags = flags_from_profile(life_stage=life_stage)
    if not flags or not text:
        return False
    if any(name in text for name in exclusion_names(flags)):
        return True
    return text_has_tea_wording(text)


def _is_acupoint(item: dict) -> bool:
    kind = str(item.get("type") or item.get("category") or "")
    title = str(item.get("title") or "")
    return kind in _ACUPOINT_TYPES or title.endswith("穴")


def _as_list(value: Any) -> list:
    if isinstance(value, list):
        return value
    if isinstance(value, str) and value.strip():
        try:
            parsed = json.loads(value)
        except (TypeError, ValueError, json.JSONDecodeError):
            return [value]
        if isinstance(parsed, list):
            return parsed
    return []


def _pieces(item: dict) -> list[str]:
    parts: list[str] = []
    for key in ("title", "description", "subtitle", "effect", "reason", "method"):
        value = item.get(key)
        if isinstance(value, str) and value:
            parts.append(value)
    for key in ("benefits", "tags", "ingredients", "steps"):
        for piece in _as_list(item.get(key)):
            if piece:
                parts.append(str(piece))
    return parts


def _blob(item: dict) -> str:
    return "".join(_pieces(item))


def _has_efficacy(text: str) -> bool:
    if not text:
        return False
    if any(term in text for term in EFFICACY_TERMS):
        return True
    return _EFFICACY_CLASS.search(text) is not None


def _has_dosage(text: str) -> bool:
    return bool(text) and _DOSAGE.search(text) is not None


def _curated_ids(season: str) -> frozenset[str]:
    return frozenset(row["id"] for row in PLAIN_BY_SEASON.get(season, ()))


def _is_curated(item: dict, season: str) -> bool:
    return str(item.get("id") or "") in _curated_ids(season)


def _marked_home_safe(item: dict) -> bool:
    """内容要进首页，必须显式标成 home_safe。节气白话条目不用这道标记。"""
    flag = item.get("home_safe")
    if flag is True or flag == 1:
        return True
    if isinstance(flag, str) and flag.strip().lower() in _HOME_SAFE_FLAGS:
        return True
    return any(str(tag) == "home_safe" for tag in _as_list(item.get("tags")))


def _allowlisted(item: dict, season: str) -> bool:
    return _is_curated(item, season) or _marked_home_safe(item)


def _item_season(item: dict) -> str | None:
    for key in ("season_tag", "season"):
        value = item.get(key)
        if isinstance(value, str) and value in PLAIN_BY_SEASON:
            return value
    return None


def _looks_like_tea(item: dict) -> bool:
    kind = f"{item.get('type') or ''}{item.get('category') or ''}"
    title = str(item.get("title") or "")
    return kind in {"tea", "茶", "茶饮"} or "tea" in kind or "茶" in kind or "茶" in title


def _has_ingredients(item: dict) -> bool:
    return any(str(piece).strip() for piece in _as_list(item.get("ingredients")))


def _stage_allows(item: dict, blob: str, life_stage: str | None, *, curated: bool) -> bool:
    """孕期 / 哺乳期：点到禁忌名就丢。不是节气白话、又像茶饮或带了配料，算没核对过，也丢。

    热粥这种没有点名禁忌食材的白话留下。
    """
    flags = flags_from_profile(life_stage=life_stage)
    if not flags:
        return True
    if text_blocked_for_stage(blob, life_stage):
        return False
    if curated:
        return True
    if _looks_like_tea(item) or _has_ingredients(item) or _has_efficacy(blob) or _has_dosage(blob):
        return False
    return True


def _plain_copy(item: dict, season: str) -> dict | None:
    """不在允许名单里、写了药效或剂量、是穴位、季节不对，都不返回。"""
    if not _allowlisted(item, season):
        return None
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
    if _has_efficacy(blob) or _has_dosage(blob):
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
        "home_safe": True,
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
    """当前节气的白话饮食和作息。只收允许名单里的条目，不够也不用种子茶饮去补。"""
    season = season_on(day)
    picked: list[dict] = []
    seen: set[str] = set()

    def take(item: dict, rank: int) -> None:
        if len(picked) >= limit:
            return
        curated = _is_curated(item, season)
        safe = _plain_copy(item, season)
        if safe is None:
            return
        blob = _blob(item) + f"{safe['title']}{safe['description']}"
        if not _stage_allows(item, blob, life_stage, curated=curated):
            return
        key = str(safe["id"] or safe["title"])
        if key in seen:
            return
        seen.add(key)
        picked.append({**safe, "_rank": rank})

    for plain in PLAIN_BY_SEASON[season]:
        take({**plain, "season": season}, 0)
    for item in items:
        take(item, 1)
    picked.sort(key=lambda row: (row["_rank"], str(row["id"])))
    out = []
    for row in picked[:limit]:
        row.pop("_rank", None)
        out.append(row)
    return out
