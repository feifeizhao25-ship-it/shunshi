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

# 条目状态（可选字段，缺省按 in_force 处理）。
# draft_consultation = 征求意见稿：可以被检索到，但绝不能当现行规则回答，回答必须带 DRAFT_NOTICE_ZH。
STATUSES = ("in_force", "draft_consultation", "superseded", "expired")
DRAFT_NOTICE_ZH = "（征求意见稿，尚未生效，仅供参考，以官方正式文件为准）"
_TIER_RANK = {"official": 4, "standard": 3, "academic": 2, "internal": 1, "legacy_unverified": 0}


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
    st = entry.get("status")
    if st and st not in STATUSES:
        problems.append(f"bad_status:{st}")
    if st == "draft_consultation" and not entry.get("url"):
        problems.append("missing:url")
    if tier in ("official", "standard") and not entry.get("url"):
        problems.append("missing:url")
    return problems


def retrievable(entry: Mapping, today: date) -> tuple[bool, str]:
    """能否进入检索。返回 (是否, 原因)。过期、被取代、系统生成、字段缺失一律否。"""
    if entry.get("origin") == "generated":
        return False, "origin_generated"
    if entry.get("superseded_by") or entry.get("status") == "superseded":
        return False, "superseded"
    if entry.get("status") == "expired":
        return False, "expired"
    if entry.get("status") == "draft_consultation":
        # 征求意见稿：可检索、可引用，但必须带 DRAFT_NOTICE_ZH，且 fact_allowed 为 False
        return True, "draft_consultation"
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
    if entry.get("status") in ("draft_consultation", "superseded", "expired"):
        return False
    return entry.get("source_tier") in FACT_TIERS and not entry.get("superseded_by")


def entry_status(entry: Mapping, today: date) -> str:
    """推导当前状态：被取代 > 过期 > 征求意见稿 > 现行。"""
    if entry.get("superseded_by") or entry.get("status") == "superseded":
        return "superseded"
    vu = parse_day(entry.get("valid_until")) if entry.get("valid_until") else None
    if entry.get("status") == "expired" or (vu and today > vu):
        return "expired"
    if entry.get("status") == "draft_consultation":
        return "draft_consultation"
    return "in_force"


def answer_notice(entry: Mapping) -> str:
    """回答里必须附带的状态提示；现行条目为空串。"""
    return DRAFT_NOTICE_ZH if entry.get("status") == "draft_consultation" else ""


def resolve_conflict(a: Mapping, b: Mapping) -> dict:
    """两条互相矛盾的证据（常见于中英文来源）如何取舍。只给结论与规则，不改条目。

    顺序：现行 > 征求意见稿 > 被取代/过期；其次来源层级（official > standard > academic > internal）；
    同层级时中文来源优先于英文来源并标注；仍无法区分 → escalate_human（交人工）。
    """
    def rank_status(e: Mapping) -> int:
        st = e.get("status") or ("superseded" if e.get("superseded_by") else "in_force")
        return {"in_force": 2, "draft_consultation": 1}.get(st, 0)
    for rule, key in (("status", rank_status), ("source_tier", lambda e: _TIER_RANK.get(e.get("source_tier"), -1))):
        ka, kb = key(a), key(b)
        if ka != kb:
            w = a if ka > kb else b
            return {"winner": w.get("id"), "rule": rule, "annotate": True}
    def is_zh(e: Mapping) -> bool:
        return str(e.get("lang", "")).lower()[:2] in ("zh", "cn")
    if is_zh(a) != is_zh(b):
        w = a if is_zh(a) else b
        return {"winner": w.get("id"), "rule": "prefer_zh_official", "annotate": True}
    return {"winner": None, "rule": "escalate_human", "annotate": True}


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
