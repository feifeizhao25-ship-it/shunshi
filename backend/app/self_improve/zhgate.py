"""运行时「只输出中文」检查（国内版）：回答里不得出现未释义的英文单词。

规则沿用 zh-ui 门禁：专业缩写（如 AI、kWh、GB）可用，但英文词本身不能出现在正文里，除非在白名单；
带中文释义的写法（「碳排放权（CCER）」）允许括号内的白名单缩写。
这是**检查器**，用于评测门禁（`zh_only_rate` 指标）；不改写任何回答。
"""

from __future__ import annotations

import re
from typing import Iterable, Sequence

DEFAULT_ALLOW = frozenset(
    {
        "ai", "aigc", "app", "kw", "kwh", "mw", "mwh", "gw", "gwh", "tw", "twh", "kv", "v", "a", "hz",
        "gb", "mb", "kb", "pv", "cny", "rmb", "pdf", "url", "api", "id", "qr", "sku", "ip", "tcm",
        "ccer", "ev", "bms", "ems", "gps", "wecom", "co2", "co", "no", "so", "pm",
    }
)
_WORD = re.compile(r"[A-Za-z][A-Za-z\-']{1,}")


def english_words(text: str, allow: Iterable[str] = DEFAULT_ALLOW) -> list[str]:
    """返回不在白名单里的英文单词（≥2 字母）。带数字的型号（如 GB 50797、Q2）里的字母段按白名单规则处理。"""
    allow_l = {a.lower() for a in allow}
    # 去掉网址与邮箱：它们是引用，不是正文
    cleaned = re.sub(r"https?://\S+|\S+@\S+\.\S+", " ", text or "")
    return [w for w in _WORD.findall(cleaned) if w.lower() not in allow_l]


def zh_only_ok(text: str, allow: Iterable[str] = DEFAULT_ALLOW) -> bool:
    return not english_words(text, allow)


def zh_only_rate(answers: Sequence[str], allow: Iterable[str] = DEFAULT_ALLOW) -> float:
    """评测集上「回答不含未释义英文」的比例。空集返回 0.0（fail-closed）。"""
    if not answers:
        return 0.0
    return sum(1 for a in answers if zh_only_ok(a, allow)) / len(answers)
