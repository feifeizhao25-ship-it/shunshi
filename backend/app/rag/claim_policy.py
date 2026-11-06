"""高风险说法不能只靠过期或待审核来源。两分钟练习不得把 Balban 2023 当成同等证据。"""

from __future__ import annotations

import re
from datetime import date

PENDING = {"待审核", "pending", "pending_review"}
BALBAN_DOI = "10.1016/j.xcrm.2022.100895"
# CDC 页面上的健康收益清单。SEASONS 只保留时长和习惯，这些词不得出现在作息文稿里。
CDC_BENEFIT_PHRASES = (
    "get sick less",
    "less likely to get sick",
    "heart disease",
    "heart attack",
    "live longer",
    "immune system",
    "type 2 diabetes",
)
HIGH_RISK_QUERY = re.compile(
    r"治疗|治愈|诊断|处方|疗效|降血糖|降血压|降血脂|cure|diagnos|prescri|treat my",
    re.IGNORECASE,
)
EFFICACY_QUERY = re.compile(r"功效|能治|治疗|治愈|降血糖|降血压")


def two_minute_may_cite(source: str) -> bool:
    """Balban 2023 的试验是每天 5 分钟。两分钟练习不能引用它作为同等效果。"""
    text = source or ""
    if BALBAN_DOI in text:
        return False
    return "balban" not in text.lower()


def is_pending_or_expired(detail: dict, today: date | None = None) -> bool:
    status = str(detail.get("review_status") or "")
    evidence = str(detail.get("evidence_status") or "")
    if status in PENDING or evidence in PENDING:
        return True
    if detail.get("freshness") == "expired":
        return True
    until = detail.get("valid_until")
    if not until:
        return False
    try:
        return date.fromisoformat(str(until)) < (today or date.today())
    except ValueError:
        return True


def sole_basis_blocks_high_risk(details: list[dict], today: date | None = None) -> bool:
    """没有一条现行、已核验来源时，不能把待审核或过期来源当成高风险结论的唯一依据。"""
    usable = [
        item for item in details
        if item.get("evidence_status") == "verified_official" and not is_pending_or_expired(item, today)
    ]
    return not usable


def ground_high_risk(
    query: str,
    context: str,
    sources: list[str],
    details: list[dict],
    today: date | None = None,
) -> tuple[str, list[str], list[dict]]:
    """高风险或功效问题若只剩待审核/过期/一般原则来源，就不把这些来源交给模型。"""
    asks_efficacy = bool(EFFICACY_QUERY.search(query or ""))
    asks_high_risk = bool(HIGH_RISK_QUERY.search(query or ""))
    if not asks_efficacy and not asks_high_risk:
        return context, sources, details
    usable = []
    for item in details:
        if is_pending_or_expired(item, today):
            continue
        if item.get("evidence_status") not in (None, "", "verified_official"):
            continue
        if asks_efficacy and item.get("principle_only"):
            continue
        usable.append(item)
    if not usable:
        return "", [], []
    if len(usable) == len(details):
        return context, sources, details
    kept = {item.get("chunk_id") for item in usable}
    # 来源句子和详情按原顺序收紧。上下文无法按块拆开时，宁可不附带来源。
    return "", [sources[i] for i, item in enumerate(details) if item.get("chunk_id") in kept and i < len(sources)], usable
