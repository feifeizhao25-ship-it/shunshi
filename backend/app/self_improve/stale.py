"""陈旧内容检测（离线、确定性、只读）：知识库/资料库条目 + 金标准题的出处，找出“该复核了”的东西。

只产出清单（findings），不改任何条目、不下线任何内容；处理由人审核。
检测项（kind）：
  expired            valid_until 已过
  review_overdue     已审核条目距上次审核超过 max_review_age_days
  pending_too_long   待审核条目放了超过 pending_age_days 还没人看
  draft_status_old   状态是“征求意见稿/待核实”超过 draft_age_days：需要核对是否已转正或失效
  superseded_live    写了 superseded_by 但仍在展示
  golden_source_old  金标准题的出处读取日期超过 golden_source_age_days，或题自带 valid_until 已过
  no_source          条目没有出处网址
  expiring_soon      valid_until 在 expiring_days（默认 45）天内到期：趁早安排复核，别等过期
"""

from __future__ import annotations

from datetime import date
from typing import Iterable, Mapping, Optional

DRAFT_STATUSES = ("征求意见稿", "待核实", "draft_consultation", "unverified")
PENDING = ("待审核", "pending", "pending_review", "Pending review")
REVIEWED = ("已审核", "reviewed", "approved", "Reviewed")


def _d(s) -> Optional[date]:
    try:
        return date.fromisoformat(str(s)[:10])
    except (TypeError, ValueError):
        return None


REASONS = {  # kind -> (中文, English)
    "expired": ("valid_until {vu} 已过", "valid_until {vu} has passed"),
    "expiring_soon": ("valid_until {vu}，还有 {n} 天到期", "valid_until {vu}, {n} days left"),
    "review_overdue": ("上次审核 {r}，已超过 {n} 天", "last reviewed {r}, more than {n} days ago"),
    "pending_too_long": ("待审核已 {n} 天", "pending review for {n} days"),
    "draft_status_old": ("状态“{st}”已 {n} 天，请核对是否已转正/失效", "status '{st}' for {n} days; check whether it was finalised or lapsed"),
    "superseded_live": ("已被 {by} 取代，但状态仍是“{st}”", "superseded by {by} but status is still '{st}'"),
    "no_source": ("没有出处网址", "no source URL"),
    "golden_expired": ("题的 valid_until {vu} 已过，答案可能已变", "case valid_until {vu} has passed; the answer may have changed"),
    "golden_old": ("出处最近一次读取已 {n} 天", "sources last read {n} days ago"),
}


def _r(lang: str, key: str, **kw) -> str:
    return REASONS[key][1 if lang == "en" else 0].format(**kw)


def _f(kind: str, ident: str, title: str, severity: str, reason: str, days: Optional[int] = None) -> dict:
    return {"kind": kind, "id": ident, "title": (title or "")[:60], "severity": severity, "reason": reason, "days": days}


def scan(entries: Iterable[Mapping], golden_cases: Iterable[Mapping] = (), *, today: Optional[date] = None,
         max_review_age_days: int = 180, pending_age_days: int = 45, draft_age_days: int = 30,
         golden_source_age_days: int = 180, expiring_days: int = 45, lang: str = "zh") -> dict:
    today = today or date.today()
    out: list[dict] = []
    n_entries = 0
    for e in entries:
        n_entries += 1
        eid, title = str(e.get("id", "?")), e.get("title", "")
        rs = e.get("review_status", "")
        vu = _d(e.get("valid_until"))
        if vu and vu < today:
            out.append(_f("expired", eid, title, "high", _r(lang, "expired", vu=vu), (today - vu).days))
        elif vu and (vu - today).days <= expiring_days:
            out.append(_f("expiring_soon", eid, title, "medium", _r(lang, "expiring_soon", vu=vu, n=(vu - today).days), (vu - today).days))
        if rs in REVIEWED:
            r = _d(e.get("reviewed_at") or e.get("reviewed_date"))
            if r and (today - r).days > max_review_age_days:
                out.append(_f("review_overdue", eid, title, "medium", _r(lang, "review_overdue", r=r, n=max_review_age_days), (today - r).days))
        if rs in PENDING:
            g = _d(e.get("retrieved_at") or e.get("created_at"))
            if g and (today - g).days > pending_age_days:
                out.append(_f("pending_too_long", eid, title, "low", _r(lang, "pending_too_long", n=(today - g).days), (today - g).days))
        if e.get("status") in DRAFT_STATUSES:
            g = _d(e.get("retrieved_at") or e.get("publish_date"))
            if g and (today - g).days > draft_age_days:
                out.append(_f("draft_status_old", eid, title, "medium", _r(lang, "draft_status_old", st=e.get("status"), n=(today - g).days), (today - g).days))
        if e.get("superseded_by") and e.get("status") not in ("已废止", "superseded", "repealed"):
            out.append(_f("superseded_live", eid, title, "high", _r(lang, "superseded_live", by=e["superseded_by"], st=e.get("status"))))
        src = e.get("source") or {}
        if not (src.get("url") or e.get("url")):
            out.append(_f("no_source", eid, title, "high", _r(lang, "no_source")))
    n_golden = 0
    for c in golden_cases:
        n_golden += 1
        cid = str(c.get("id", "?"))
        vu = _d(c.get("valid_until"))
        if vu and vu < today:
            out.append(_f("golden_source_old", cid, c.get("question", ""), "high", _r(lang, "golden_expired", vu=vu), (today - vu).days))
            continue
        ages = [(today - r).days for s in c.get("sources", []) if (r := _d(s.get("retrieved_at")))]
        if ages and min(ages) > golden_source_age_days:
            out.append(_f("golden_source_old", cid, c.get("question", ""), "medium", _r(lang, "golden_old", n=min(ages)), min(ages)))
    order = {"high": 0, "medium": 1, "low": 2}
    out.sort(key=lambda f: (order[f["severity"]], f["kind"], f["id"]))
    counts: dict[str, int] = {}
    for f in out:
        counts[f["kind"]] = counts.get(f["kind"], 0) + 1
    return {"scanned": {"entries": n_entries, "golden_cases": n_golden}, "today": today.isoformat(), "counts": counts, "findings": out}
