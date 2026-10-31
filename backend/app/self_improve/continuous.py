"""持续改进任务（顺时）：金标准评测、陈旧扫描、雷达线索暂存、月报。全部默认关闭（SIL_ENABLED=0 时只返回 disabled）。

  python -m app.self_improve.run golden          [--force]   每周日 03:30：金标准问答，对比上次，退步的题进工作清单
  python -m app.self_improve.run stale           [--force]   每日 02:30：资料库/知识库/金标准出处的陈旧扫描（只读）
  python -m app.self_improve.run radar           [--force]   每周三 05:00：研究雷达（只写摘要 + 结构化线索，不入库）
  python -m app.self_improve.run radar-stage     [--force]   每周三 06:00：把相关线索暂存成资料库“待审核候选”（永不自动通过）
  python -m app.self_improve.run monthly-report  [--force]   每月 1 日 05:00：上月改了什么 / 评测分数 / 陈旧项 / 等人审核的候选（md + pdf + json）
--force 只用于人工手动跑一次，不改变任何开关。所有任务只写 SIL_DATA_DIR 下的文件，不改知识库条目、不发消息。
"""

from __future__ import annotations

import json
import os
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Optional

from . import golden as G
from . import monthly_report as MR
from . import radar, radar_stage as RS
from . import stale as S
from .scheduler import TZ
from .store import CandidateStore

HERE = Path(__file__).parent
GOLDEN_FILE = HERE / "data" / "golden_shunshi_zh.jsonl"
EDITION = "zh"  # 国内版题库；国际版题库放 golden_shunshi_en.jsonl，同一套引擎
SLOTS = {
    "golden_eval": "weekly:SUN@03:30",
    "stale_scan": "daily@02:30",
    "radar": radar.RADAR_SCHEDULE,  # weekly:WED@05:00
    "radar_stage": "weekly:WED@06:00",
    "monthly_report": "monthly:1@05:00",
}
DOMAIN_SKILLS = ("kb-food-medicine-homology", "kb-exercise-sleep", "kb-solar-terms", "kb-constitution", "kb-verified-basics", "safety-medical-boundary")
TERMS = ("中医", "tcm", "traditional chinese medicine", "wellness", "health", "solar term", "节气", "diet", "nutrition", "sleep", "food", "herbal", "constitution", "体质", "养生", "食养")


def _cfg():
    from .hooks import build_config

    return build_config()


def _enabled(force: bool, cfg=None) -> bool:
    return force or bool((cfg or _cfg()).enabled)


def _data_dir(cfg=None) -> Path:
    return Path((cfg or _cfg()).data_dir)


def skill_ids() -> list[str]:
    from app.growth.skills.catalog import SKILLS

    return [s.name for s in SKILLS] + list(DOMAIN_SKILLS)


def library_entries() -> list[dict]:
    """资料库全部条目：已有 + 暂存区（暂存区条目也要被陈旧扫描和金标准覆盖到，但永远不会展示给用户）。"""
    from ..library import store

    out = list(store.load_document()["entries"])
    out += store.load_staged()
    return out


def manifest_entries() -> list[dict]:
    """RAG 来源清单里的文档当作条目扫：legacy 文档 2026-11-30 到期就会在这里被看到。"""
    p = HERE.parent / "rag" / "source_manifest.json"
    if not p.exists():
        return []
    m = json.loads(p.read_text("utf-8"))
    return [{"id": f"rag:{name}", "title": name, "status": d.get("evidence_status", ""), "review_status": "已审核" if d.get("evidence_status") == "verified_official" else "待审核",
             "reviewed_at": d.get("reviewed_at"), "valid_until": d.get("valid_until"), "retrieved_at": d.get("reviewed_at"),
             "source": {"url": "https://local/rag/" + name}} for name, d in m.get("documents", {}).items() if d.get("locale", "zh-CN").startswith("zh")]  # 国内版只扫中文文档，国际版文档由国际版任务扫


# ---------------------------------------------------------------- 答案来源（按题的 channel）
def _grams(s: str) -> set:
    s = "".join(ch for ch in s if ch.isalnum())
    return {s[i:i + 2] for i in range(len(s) - 1)}


def library_answer(question: str, entries: list[dict]) -> dict:
    qg = _grams(question)
    best, score = None, 0
    for e in entries:
        eg = _grams(e["title"] + " ".join(e.get("tags", [])))
        sc = len(qg & eg) * 3 + len(qg & _grams(e["summary"] + "".join(e["points"])))
        if sc > score:
            best, score = e, sc
    if not best:
        return {"text": ""}
    text = "\n".join([best["title"], best["summary"], *best["points"], best.get("plain_tip", ""), best.get("caution", "")])
    return {"text": text, "citations": [best["source"]["url"]]}


def make_answer_fn(entries: Optional[list[dict]] = None):
    entries = library_entries() if entries is None else entries
    kb_cache: dict = {}

    def fn(case: dict):
        ch = case.get("channel", "library")
        if ch == "library":
            return library_answer(case["question"], entries)
        if ch == "kb":
            if "fn" not in kb_cache:
                from app.rag.knowledge_base import load_knowledge_bases
                from app.rag.retriever import retrieve

                load_knowledge_bases()
                kb_cache["fn"] = G.retrieval_answer_fn(lambda q, k: retrieve(q, lang="cn", top_k=k))
            return kb_cache["fn"](case["question"], case["lang"])
        if ch == "growth":
            from app.growth.skills.drafts import render_draft

            i = case["input"]
            return {"text": render_draft(i["skill"], i["topic"], i["angle"], i["platform"])}
        if ch == "safety":
            from app.safety.guard import SafetyGuard

            kb_cache.setdefault("guard", SafetyGuard())
            r = kb_cache["guard"].check_input(case["question"], {"user_id": "sil-golden"})
            return {"text": "", "refused": bool(r.should_block) or r.level.value == "crisis"}
        raise ValueError(f"unknown_channel:{ch}")

    fn.wants_case = True
    return fn


# ---------------------------------------------------------------- 任务
def _worklist(data: Path, rows: list[dict]) -> None:
    if not rows:
        return
    data.mkdir(parents=True, exist_ok=True)
    with (data / "worklist.jsonl").open("a", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


def run_golden(now: Optional[datetime] = None, *, force: bool = False, cases=None, answer_fn=None, cfg=None) -> dict:
    cfg = cfg or _cfg()
    if not _enabled(force, cfg):
        return {"status": "disabled"}
    now = now or datetime.now(TZ)
    data = _data_dir(cfg)
    cases = cases if cases is not None else G.load(GOLDEN_FILE)
    res = G.run_golden(cases, answer_fn or make_answer_fn(), edition=EDITION, previous=G.load_last(data), now=now)
    G.save_result(res, data)
    _worklist(data, [{"candidate": f"golden-regression-{i}", "url": "", "excerpt": f"金标准题 {i} 上次通过、这次没通过，请看原因"} for i in res["regressions"]])
    cov = G.coverage(cases, skill_ids())
    return {"status": "ok", "n": res["n"], "pass_rate": round(res["pass_rate"], 4), "regressions": res["regressions"], "failures": [f["id"] for f in res["failures"]],
            "skipped_invalid": res["skipped_invalid"], "coverage_missing": cov["missing"], "coverage_thin": cov["thin"]}


def run_stale(now: Optional[datetime] = None, *, force: bool = False, cfg=None) -> dict:
    cfg = cfg or _cfg()
    if not _enabled(force, cfg):
        return {"status": "disabled"}
    data = _data_dir(cfg)
    today = (now or datetime.now(TZ)).date()
    rep = S.scan(library_entries() + manifest_entries(), G.load(GOLDEN_FILE), today=today)
    data.mkdir(parents=True, exist_ok=True)
    (data / "stale_report.json").write_text(json.dumps(rep, ensure_ascii=False, indent=1), "utf-8")
    prev = {f["kind"] + ":" + f["id"] for f in json.loads((data / "stale_prev.json").read_text("utf-8"))} if (data / "stale_prev.json").exists() else set()
    new_high = [f for f in rep["findings"] if f["severity"] == "high" and f["kind"] + ":" + f["id"] not in prev]
    _worklist(data, [{"candidate": f"stale-{f['kind']}-{f['id']}", "url": "", "excerpt": f"{f['title']}：{f['reason']}"} for f in new_high])
    (data / "stale_prev.json").write_text(json.dumps(rep["findings"], ensure_ascii=False), "utf-8")
    return {"status": "ok", "counts": rep["counts"], "new_high": [f["id"] for f in new_high]}


def run_radar(now: Optional[datetime] = None, *, force: bool = False, cfg=None, **kw) -> dict:
    cfg = cfg or _cfg()
    if not _enabled(force, cfg):
        return {"status": "disabled"}
    r = radar.run_radar(cfg.product, cfg.data_dir, now=now, **kw)
    return {"status": "ok", **r}


def run_radar_stage(now: Optional[datetime] = None, *, force: bool = False, cfg=None) -> dict:
    cfg = cfg or _cfg()
    if not _enabled(force, cfg):
        return {"status": "disabled"}
    data = _data_dir(cfg)
    known = [(e.get("source") or {}).get("url") for e in library_entries()]
    out = RS.stage(RS.load_items(data / "radar"), product=cfg.product, terms=TERMS, staged_path=data / "library_staged.jsonl", known_urls=known, now=now or datetime.now(TZ))
    return {"status": "ok", **out}


def run_monthly_report(now: Optional[datetime] = None, *, force: bool = False, month: Optional[str] = None, cfg=None, env=None) -> dict:
    cfg = cfg or _cfg()
    if not _enabled(force, cfg):
        return {"status": "disabled"}
    env = os.environ if env is None else env
    now = now or datetime.now(TZ)
    month = month or (now.replace(day=1) - timedelta(days=1)).strftime("%Y-%m")  # 默认报“上个月”
    y, m = map(int, month.split("-"))
    prev_month = f"{y - 1}-12" if m == 1 else f"{y}-{m - 1:02d}"
    data = _data_dir(cfg)
    runs = G.load_month(data, month)
    prev_runs = G.load_month(data, prev_month)
    entries = library_entries()
    from ..library import store as lib

    review_log = []
    rl = lib.data_dir() / "library_review_log.jsonl"
    if rl.exists():
        review_log = [json.loads(x) for x in rl.read_text("utf-8").splitlines() if x.strip()]
    stale = S.scan(entries + manifest_entries(), G.load(GOLDEN_FILE), today=now.date())
    radar_dir = data / "radar"
    digests = sorted(radar_dir.glob(f"digest_{month.replace('-', '')}*.md")) if radar_dir.exists() else []
    new_items = sum(len(json.loads(p.read_text("utf-8"))) for p in radar_dir.glob(f"items_{month.replace('-', '')}*.json")) if radar_dir.exists() else 0
    cands = [c.__dict__ for c in CandidateStore(data).list()] if (data / "candidates").exists() else []
    rep = MR.build_report(
        "顺时 ShunShi" if env.get("SIL_REPORT_LANG", "zh") == "zh" else "SEASONS", month, golden_runs=runs, previous_golden=prev_runs[-1] if prev_runs else None,
        ledger_events=CandidateStore(data).ledger.entries() if (data / "candidates").exists() else [], review_log=review_log, stale=stale, candidates=cands,
        staged=RS.load_staged(data / "library_staged.jsonl"), pending_entries=sum(1 for e in entries if e.get("review_status") == "待审核"),
        radar_digests=len(digests), radar_new_items=new_items, sil_enabled=bool(cfg.enabled), lang=env.get("SIL_REPORT_LANG", "zh"), today=now.date())
    out = MR.write_all(rep, data / "reports", env=env)
    return {"status": "ok", "month": month, **out, "advice": rep["advice"]}


def jobs() -> dict:
    """给 run.py serve 用：name -> (slot, fn(now))，与 SIL 其它任务同一个调度循环；每个任务自己判断开关。"""
    return {
        "golden_eval": (SLOTS["golden_eval"], run_golden), "stale_scan": (SLOTS["stale_scan"], run_stale), "radar": (SLOTS["radar"], run_radar),
        "radar_stage": (SLOTS["radar_stage"], run_radar_stage), "monthly_report": (SLOTS["monthly_report"], run_monthly_report),
    }
