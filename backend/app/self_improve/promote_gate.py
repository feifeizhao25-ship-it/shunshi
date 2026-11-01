"""“变好才上线”闸门：暂存区候选条目要变成用户可见的资料，必须先过这一关（离线、确定性、不调用模型）。

四道检查，缺一不可：
  1. 证据分 evidence ≥ 0.85  —— 来源等级（A 官方原文=1.0 / B 转载或摘要=0.8 / C=0.5 / D 社媒线索=0）与完整度取较小者；
                                B 级只有写明 second_source（另一份独立来源）才按 0.9 算。
  2. 安全分 safety   ≥ 0.85  —— compliance.check 词族（医疗化、绝对化、投资建议、命运定论等）+ 条目自带的 caution 必须存在；任一命中即 0。
  3. 对照评测 impact = keep —— 条目自带的 probes（口语问法）在“加入后”的检索里能命中本条（Hit@3 ≥ 2/3，且至少 2 个问法），
                                 同时已有条目的探针命中不能变差（零退步）。
  4. 不重复 —— 同来源链接 / 同文号不能已经在工作文档里。
闸门只给结论，不改任何东西；真正上线（approve）仍然必须有人名。默认不强制：LIBRARY_PROMOTE_GATE=1 时 review_cli approve 才要求 keep。
参考：Skill-V（版本化可证伪契约 + 非退步回放，arXiv 2610.11781）、SkillSandbox（with/without 对照、Keep/Reject，2610.10088）、SkillForge（试用→正式、带迟滞，2610.09832）。
"""

from __future__ import annotations

import os
import re
from datetime import date, datetime
from typing import Iterable, Optional
from urllib.parse import urlparse

from . import compliance
from ..rag import hybrid

THRESHOLD = 0.85
TIER_SCORE = {"A": 1.0, "B": 0.8, "C": 0.5, "D": 0.0}
HIT_K = 3
MIN_PROBES = 2
MIN_PROBE_RATE = 2 / 3


def enforced(env=None) -> bool:
    env = os.environ if env is None else env
    return str(env.get("LIBRARY_PROMOTE_GATE", "0")).strip().lower() in ("1", "true", "yes", "on")


def entry_text(e: dict) -> str:
    return "\n".join([e.get("title", ""), e.get("summary", ""), *e.get("points", []), e.get("plain_tip", ""), e.get("caution", "")])


def _index_text(e: dict) -> tuple[str, str]:
    return (e.get("title", "") + " " + " ".join(e.get("tags", [])), "\n".join([e.get("summary", ""), *e.get("points", []), e.get("plain_tip", "")]))


# ------------------------------------------------------------------ 1 证据
def evidence_score(e: dict, today: date, *, domain_ok=None) -> tuple[float, list[str]]:
    src = e.get("source") or {}
    why: list[str] = []
    tier = (src.get("tier") or "D").upper()[:1]
    tier_score = TIER_SCORE.get(tier, 0.0)
    if tier == "B" and e.get("second_source"):
        tier_score = 0.9
    elif tier == "B":
        why.append("B 级来源，需要第二份独立来源（second_source）才能上线")
    checks = {
        "https 链接": str(src.get("url", "")).startswith("https://"),
        "出处名称+发布机构": bool(src.get("title")) and bool(src.get("publisher")),
        "读到的范围（全文/摘要）": bool(src.get("read_scope")),
        "发布日期": bool(e.get("publish_date")),
        "核对日期": bool(e.get("retrieved_at")),
    }
    if domain_ok is not None and checks["https 链接"]:
        checks["来源域名在白名单"] = bool(domain_ok(urlparse(src["url"]).hostname or ""))
    for k, ok in checks.items():
        if not ok:
            why.append(f"缺少或不合格：{k}")
    completeness = sum(checks.values()) / len(checks)
    try:
        age = (today - date.fromisoformat(str(e.get("retrieved_at"))[:10])).days
        if age > 120:
            why.append(f"来源核对已 {age} 天，需要重新核对")
            completeness *= 0.8
    except ValueError:
        pass
    return round(min(tier_score, completeness), 4), why


# ------------------------------------------------------------------ 2 安全
_DISCLAIMER = re.compile(r"(不能|不可以?|不得|不要|不应|并非|不是|无法|不会|不宜|切勿|请勿)(用来|用于|视为|当作)?(替代|取代)(医生|药物|药品|就医|医嘱|专业)[^，。；\n]{0,8}")


def safety_score(e: dict, families: Optional[Iterable[str]] = None) -> tuple[float, list[str]]:
    why: list[str] = []
    # 明确的否定式免责声明（“不能替代医生的诊断和治疗”）是我们要的写法，不算命中；其它写法仍照常检查
    r = compliance.check(_DISCLAIMER.sub("", entry_text(e)), families)
    if not r.ok:
        why += [f"合规词族命中：{f}（{m}）" for f, m in r.hits]
    if not (e.get("caution") or "").strip():
        why.append("缺少“注意/边界”说明（caution）")
    return (1.0 if not why else 0.0), why


# ------------------------------------------------------------------ 3 对照
def _rank_of(idx: hybrid.BM25Index, ids: list[str], query: str, target: str) -> Optional[int]:
    from ..rag import aliases

    res = idx.query(aliases.expand(query, idx.lang), top_k=10)
    for rank, (i, _s) in enumerate(res, 1):
        if ids[i] == target:
            return rank
    return None


def impact(candidate: dict, doc_entries: list[dict], lang: str = "cn") -> dict:
    """with/without 对照：候选的探针命中 + 已有条目的探针不退步。"""
    probes = [p for p in candidate.get("probes", []) if str(p).strip()]
    base_ids = [e["id"] for e in doc_entries]
    with_entries = doc_entries + [candidate]
    without = hybrid.BM25Index([_index_text(e) for e in doc_entries], lang) if doc_entries else None
    withc = hybrid.BM25Index([_index_text(e) for e in with_entries], lang)
    with_ids = base_ids + [candidate["id"]]
    hits = sum(1 for p in probes if (_rank_of(withc, with_ids, p, candidate["id"]) or 99) <= HIT_K)
    regress: list[dict] = []
    checked = 0
    for e in doc_entries:
        for p in e.get("probes", []) or [e.get("title", "")]:
            if not p:
                continue
            checked += 1
            before = _rank_of(without, base_ids, p, e["id"]) if without else None
            after = _rank_of(withc, with_ids, p, e["id"])
            if before is not None and before <= HIT_K and (after is None or after > HIT_K):
                regress.append({"entry": e["id"], "probe": p, "before": before, "after": after})
    rate = hits / len(probes) if probes else 0.0
    why = []
    if len(probes) < MIN_PROBES:
        why.append(f"probes 太少：{len(probes)} < {MIN_PROBES}（无法证明变好）")
    if probes and rate < MIN_PROBE_RATE:
        why.append(f"候选自己的口语问法只命中 {hits}/{len(probes)}，低于 {MIN_PROBE_RATE:.2f}")
    if regress:
        why.append(f"已有条目退步 {len(regress)} 处")
    return {"probes": len(probes), "hit_at_3": hits, "hit_rate": round(rate, 4), "regression_checked": checked, "regressions": regress,
            "decision": "keep" if not why else "reject", "why": why}


# ------------------------------------------------------------------ 4 重复
def duplicates(candidate: dict, doc_entries: list[dict]) -> list[str]:
    url = (candidate.get("source") or {}).get("url")
    no = (candidate.get("source") or {}).get("doc_no")
    out = []
    for e in doc_entries:
        s = e.get("source") or {}
        if e.get("id") == candidate.get("id"):
            out.append(f"id 已存在：{e['id']}")
        elif url and s.get("url") == url:
            out.append(f"同一来源链接已在 {e['id']}")
        elif no and s.get("doc_no") == no:
            out.append(f"同一文号已在 {e['id']}")
    return out


def evaluate(candidate: dict, doc_entries: list[dict], *, today: Optional[date] = None, lang: str = "cn", domain_ok=None, families=None) -> dict:
    today = today or date.today()
    ev, ev_why = evidence_score(candidate, today, domain_ok=domain_ok)
    sf, sf_why = safety_score(candidate, families)
    im = impact(candidate, doc_entries, lang)
    dups = duplicates(candidate, doc_entries)
    reasons = []
    if ev < THRESHOLD:
        reasons += [f"证据分 {ev} < {THRESHOLD}", *ev_why]
    if sf < THRESHOLD:
        reasons += [f"安全分 {sf} < {THRESHOLD}", *sf_why]
    if im["decision"] != "keep":
        reasons += im["why"]
    reasons += dups
    return {"id": candidate.get("id"), "title": candidate.get("title"), "decision": "keep" if not reasons else "reject", "evidence": ev, "safety": sf, "impact": im,
            "duplicates": dups, "reasons": reasons, "evaluated_at": datetime.now().astimezone().isoformat(timespec="seconds")}


def evaluate_all(staged: list[dict], doc_entries: list[dict], **kw) -> dict:
    rows = [evaluate(c, doc_entries, **kw) for c in staged if c.get("id") not in {e["id"] for e in doc_entries}]
    return {"n": len(rows), "keep": [r["id"] for r in rows if r["decision"] == "keep"], "reject": [r["id"] for r in rows if r["decision"] != "keep"], "rows": rows}


def render_md(rep: dict) -> str:
    lines = ["# 候选条目闸门报告", "", f"共 {rep['n']} 条；可交人工审核（keep）{len(rep['keep'])} 条，暂不通过（reject）{len(rep['reject'])} 条。", "",
             "闸门只给结论，不上线任何东西；上线仍需人工 approve 并写审核人姓名。", ""]
    for r in rep["rows"]:
        lines.append(f"## {r['id']} {r['title']} — {r['decision']}")
        lines.append(f"- 证据分 {r['evidence']}；安全分 {r['safety']}；探针命中 {r['impact']['hit_at_3']}/{r['impact']['probes']}；已有条目退步 {len(r['impact']['regressions'])}")
        lines += [f"- ✗ {x}" for x in r["reasons"]]
        lines.append("")
    return "\n".join(lines)
