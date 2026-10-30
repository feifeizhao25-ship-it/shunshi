"""顺时的评测：检索（从知识库标题自动生成，主题互斥切分）+ 安全红队（固定集）。

只依赖已加载的知识库与 SafetyGuard，离线、确定性、不调用模型。
指标（与 gates.GateThresholds 同名）：
- recall_at_8            检索：金标准 chunk 是否在前 8
- faithfulness           抽取式：top1 结果是否包含该主题名（有据可依）
- citation_accuracy      verified_official 的片段是否都带来源链接与复核日期
- freshness_correctness  返回的 verified 片段全部在有效期内
- redteam_pass_rate      安全红队（不含已登记的 known_gaps）
- cost_ratio / latency_ratio  检索耗时相对基线（无模型调用，成本比恒为 1.0）
"""

from __future__ import annotations

import hashlib
import json
import re
import time
from datetime import date
from pathlib import Path
from typing import Iterable

DATA = Path(__file__).with_name("data")
_NUM = re.compile(r"^\s*(?:第[一二三四五六七八九十]+章[:：]\s*|[一二三四五六七八九十]+、\s*|\d+\.\s*)")
_PAREN = re.compile(r"[（(].*?[）)]")


def topic_name(heading: str) -> str:
    return _PAREN.sub("", _NUM.sub("", heading or "")).strip()


def split_of(topic: str) -> str:
    """按主题（不是按题目）切分，优化集 / 门禁集 / held-out 主题互斥。"""
    b = int(hashlib.sha256(topic.encode("utf-8")).hexdigest()[:8], 16) % 10
    return "optimization" if b < 5 else "gate" if b < 8 else "heldout"


def uid(chunk_id: str, metadata: dict) -> str:
    """chunk_id 在三份文稿里各自从 cn_0001 开始编号，会重复；评测用「文件:编号」作唯一键。"""
    return f"{metadata.get('source_file', '?')}:{chunk_id}"


TEMPLATES = ("{t}怎么养生调理", "{t}有哪些注意事项", "想了解{t}")


def build_retrieval_cases(chunks: Iterable) -> list[dict]:
    """每个三级标题 chunk 生成 3 个问法。同一主题的题目只会落在同一个集合。"""
    cases = []
    for ch in chunks:
        hp = list(ch.heading_path)
        if len(hp) < 3:
            continue
        t = topic_name(hp[-1])
        if len(t) < 2 or len(t) > 12:
            continue
        for i, tpl in enumerate(TEMPLATES):
            cases.append({
                "id": f"ss-rt-{uid(ch.chunk_id, ch.metadata)}-{i}",
                "topic": t,
                "query": tpl.format(t=t),
                "gold_chunk_id": uid(ch.chunk_id, ch.metadata),
                "split": split_of(t),
            })
    return cases


def run_retrieval(cases: list[dict], retrieve_fn, *, k: int = 8, today: date | None = None) -> dict:
    today = today or date.today()
    hit = ground = 0
    cited = cited_ok = fresh = fresh_ok = 0
    t0 = time.perf_counter()
    for c in cases:
        res = retrieve_fn(c["query"], k)
        ids = [uid(r["chunk_id"], r.get("metadata", {})) for r in res]
        hit += c["gold_chunk_id"] in ids
        ground += bool(res) and c["topic"] in (res[0]["content"] + " ".join(res[0].get("heading_path", [])))
        for r in res:
            m = r.get("metadata", {})
            if m.get("evidence_status") == "verified_official":
                cited += 1
                cited_ok += bool(m.get("reviewed_at")) and ("http" in r.get("content", "") or bool(m.get("url")))
                fresh += 1
                fresh_ok += date.fromisoformat(m["valid_until"]) >= today if m.get("valid_until") else 0
    n = max(len(cases), 1)
    return {
        "n": len(cases),
        "recall_at_8": hit / n,
        "faithfulness": ground / n,
        "citation_accuracy": (cited_ok / cited) if cited else 1.0,
        "freshness_correctness": (fresh_ok / fresh) if fresh else 1.0,
        "latency_s": time.perf_counter() - t0,
    }


def _passes(expect: str, r) -> bool:
    lvl = r.level.value
    if expect == "crisis":
        return lvl == "crisis" and r.should_block
    if expect == "distress":
        return lvl in ("emotional_distress", "crisis")
    if expect == "block":
        return bool(r.should_block) or lvl == "crisis"
    return (not r.should_block) and lvl == "normal"  # allow


def run_safety(guard=None, cases: list[dict] | None = None, known_gaps: Iterable[str] = ()) -> dict:
    from app.safety.guard import SafetyGuard

    guard = guard or SafetyGuard()
    cases = cases if cases is not None else json.loads((DATA / "safety_eval_v1.json").read_text("utf-8"))
    gaps = set(known_gaps)
    scored = failed = 0
    failures, by_topic = [], {}
    for c in cases:
        ok = _passes(c["expect"], guard.check_input(c["text"], {"user_id": "sil-eval"}))
        t = by_topic.setdefault(c["topic"], [0, 0])
        t[1] += 1
        t[0] += ok
        if c["id"] in gaps:
            continue
        scored += 1
        if not ok:
            failed += 1
            failures.append(c["id"])
    return {"n": len(cases), "scored": scored, "redteam_pass_rate": (scored - failed) / max(scored, 1),
            "failures": failures, "by_topic": {k: v[0] / v[1] for k, v in by_topic.items()}}


def evaluate_all(retrieve_fn=None, *, today: date | None = None) -> dict:
    """返回按 split 汇总的指标。门禁只看 gate 集；optimization 用于提案阶段；heldout 仅季度使用。"""
    from app.rag.knowledge_base import cn_kb, load_knowledge_bases
    from app.rag.retriever import retrieve

    load_knowledge_bases()
    cases = build_retrieval_cases(cn_kb.chunks)
    fn = retrieve_fn or (lambda q, k: retrieve(q, lang="cn", top_k=k))
    out = {"splits": {}}
    for sp in ("optimization", "gate", "heldout"):
        out["splits"][sp] = run_retrieval([c for c in cases if c["split"] == sp], fn, today=today)
    out["safety"] = run_safety(known_gaps=json.loads((DATA / "eval_baseline.json").read_text("utf-8")).get("safety_known_gaps", []))
    return out
