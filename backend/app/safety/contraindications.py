"""Drop recommendation text that the repo already marks as unsuitable for a
declared pregnancy or breastfeeding flag.

Sources (quoted, not extended):

- docs/knowledge-base/顺时知识库_补充篇_中文版.md, 「孕早期」禁忌食材:
  山楂（活血化瘀，可致宫缩）、薏苡仁（滑胎）、螃蟹（寒凉、活血）、甲鱼（活血散瘀）、
  芦荟（泻下）、红花、藏红花（活血化瘀）、益母草（活血调经）.
- backend/app/router/maternity.py FORBIDDEN_HERBS_DATA, each row's own reason.
- backend/app/router/maternity.py BREASTFEEDING_AVOID_FOODS, each row's own reason.
  Only the named foods are used. Vague groups such as 「辛辣刺激物」are not,
  because they are not a single item.
- backend/app/router/herbal_knowledge.py: 当归 and 山楂 already say 孕妇慎用.
  Those names are already in the lists above.

麦冬 is recommended for 阴虚 (constitution tea, recommendation tags) but none of
these sources name it as unsuitable in pregnancy or breastfeeding. It is not
added here.
"""

from __future__ import annotations

import re

# 补充篇 uses 薏苡仁; the app copy says 薏米 for the same grain.
_PREGNANCY = (
    "山楂",
    "薏苡仁",
    "薏米",
    "螃蟹",
    "甲鱼",
    "芦荟",
    "红花",
    "藏红花",
    "益母草",
    "桃仁",
    "三棱",
    "莪术",
    "丹参",
    "赤芍",
    "黄芪",
    "当归",
    "肉桂",
    "干姜",
    "附子",
    "麝香",
    "冰片",
    "薄荷",
)

_BREASTFEEDING = (
    "螃蟹",
    "薏米",
    "山楂",
    "柚子",
    "鸭肉",
    "薄荷",
    "人参",
)

_PREGNANCY_MARKERS = ("怀孕", "孕妇", "孕期", "孕早", "孕中", "孕晚", "pregnant", "pregnancy")
_BREASTFEEDING_MARKERS = ("哺乳", "母乳", "breastfeed", "breastfeeding", "lactation")


def names_for(flags: frozenset[str]) -> tuple[str, ...]:
    names: list[str] = []
    if "pregnancy" in flags:
        names.extend(_PREGNANCY)
    if "breastfeeding" in flags:
        names.extend(_BREASTFEEDING)
    # Longest first so 藏红花 is seen before 红花, and 干姜 is not confused with 姜.
    return tuple(sorted(set(names), key=len, reverse=True))


def flags_from_profile(
    *,
    life_stage: str | None = None,
    health_concerns: list[str] | None = None,
) -> frozenset[str]:
    """Read the flags the profile already stores. 备孕 contains 孕 but is not pregnancy."""
    bits = [life_stage or ""]
    bits.extend(health_concerns or [])
    blob = " ".join(bits).lower()
    flags: set[str] = set()
    if any(marker in blob for marker in _PREGNANCY_MARKERS):
        flags.add("pregnancy")
    if any(marker in blob for marker in _BREASTFEEDING_MARKERS):
        flags.add("breastfeeding")
    return frozenset(flags)


def filter_text(text: str, flags: frozenset[str]) -> str:
    names = names_for(flags)
    if not text or not names:
        return text
    pieces = re.split(r"([、，,；;\n])", text)
    kept: list[str] = []
    index = 0
    while index < len(pieces):
        segment = pieces[index]
        delimiter = pieces[index + 1] if index + 1 < len(pieces) else ""
        if segment.strip() and not any(name in segment for name in names):
            kept.append(segment)
            if delimiter:
                kept.append(delimiter)
        index += 2
    result = "".join(kept)
    result = re.sub(r"[、，,；;]{2,}", "、", result)
    result = re.sub(r"（\s*）", "", result)
    return result.strip("、，,；; \n")
