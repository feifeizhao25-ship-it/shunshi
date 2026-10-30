"""知识条目新鲜度与退役。

统一字段：valid_from / valid_until / superseded_by / source_tier / license /
reviewer / reviewed_at / content_hash / origin。
``origin == "generated"``（系统自己生成的内容）永远不得进入检索索引，防自我投毒。
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Iterable, Mapping

SOURCE_TIERS = ("official", "standard", "academic", "internal", "legacy_unverified")
REQUIRED_FIELDS = (
    "id",
    "source_tier",
    "license",
    "valid_from",
    "valid_until",
    "content_hash",
    "origin",
)
# 这些层级可作「事实陈述」；legacy_unverified 只能当参考，并须显式标注。
FACT_TIERS = frozenset({"official", "standard", "academic", "internal"})


def parse_day(value: str | date | None) -> date | None:
    if value is None or value == "":
        return None
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return datetime.strptime(str(value)[:10], "%Y-%m-%d").date()


def content_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def validate_entry(entry: Mapping) -> list[str]:
    """返回问题列表，空列表表示合格。"""
    problems = [f"missing:{f}" for f in REQUIRED_FIELDS if entry.get(f) in (None, "")]
    tier = entry.get("source_tier")
    if tier and tier not in SOURCE_TIERS:
        problems.append(f"bad_tier:{tier}")
    try:
        vf, vu = parse_day(entry.get("valid_from")), parse_day(entry.get("valid_until"))
        if vf and vu and vu < vf:
            problems.append("valid_until_before_valid_from")
    except ValueError:
        problems.append("bad_date")
    if entry.get("origin") == "generated":
        problems.append("origin_generated_not_indexable")
    if tier in ("official", "standard") and not entry.get("url"):
        problems.append("missing:url")
    return problems


def retrievable(entry: Mapping, today: date) -> tuple[bool, str]:
    """能否进入检索。返回 (是否, 原因)。过期、被取代、系统生成、字段缺失一律否。"""
    if entry.get("origin") == "generated":
        return False, "origin_generated"
    if entry.get("superseded_by"):
        return False, "superseded"
    try:
        vf, vu = parse_day(entry.get("valid_from")), parse_day(entry.get("valid_until"))
    except ValueError:
        return False, "bad_date"
    if vu is None:
        return False, "no_valid_until"
    if vf and today < vf:
        return False, "not_yet_valid"
    if today > vu:
        return False, "expired"
    return True, "ok"


def fact_allowed(entry: Mapping) -> bool:
    """能否作为事实陈述引用（legacy_unverified 只能作参考）。"""
    return entry.get("source_tier") in FACT_TIERS and not entry.get("superseded_by")


@dataclass
class RetirementReport:
    expired: list[str] = field(default_factory=list)
    superseded: list[str] = field(default_factory=list)
    idle: list[str] = field(default_factory=list)
    expiring_soon: list[str] = field(default_factory=list)

    @property
    def retire_ids(self) -> list[str]:
        return sorted(set(self.expired) | set(self.superseded) | set(self.idle))


def retirement_scan(
    entries: Iterable[Mapping],
    today: date,
    *,
    hits_90d: Mapping[str, int] | None = None,
    idle_days_threshold: int = 90,
    warn_days: int = 30,
) -> RetirementReport:
    """每月清点：过期 / 被取代 / 90 天无命中 → 降级为 deprecated（由调用方执行）。

    只给出名单，不删除任何东西；即将到期的条目提前 ``warn_days`` 天预警。
    """
    hits_90d = hits_90d or {}
    rep = RetirementReport()
    soon = today + timedelta(days=warn_days)
    for e in entries:
        eid = str(e.get("id"))
        ok, why = retrievable(e, today)
        if why == "expired":
            rep.expired.append(eid)
        elif why == "superseded":
            rep.superseded.append(eid)
        elif ok:
            vu = parse_day(e.get("valid_until"))
            if vu and vu <= soon:
                rep.expiring_soon.append(eid)
            if eid in hits_90d and hits_90d[eid] == 0 and idle_days_threshold:
                rep.idle.append(eid)
    return rep
