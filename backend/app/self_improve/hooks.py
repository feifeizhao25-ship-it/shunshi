"""顺时接入层：把公共 SIL 内核接到顺时的知识库 / 评测 / 安全规则上。

数据目录 SIL_DATA_DIR（默认 backend/var/self_improve/shunshi）：
  inbox/*.json        经人整理的待入库条目（含出处）；闭环只处理这里，不凭空生成事实
  state/source_hashes.json  来源页上次内容 hash（用于发现更新）
  worklist.jsonl      「来源有更新，请人整理」的工作项
  candidates/ changelog.jsonl reports/   闭环自己的隔离区、哈希链日志、周报
晋升（用户可见）= 写入 app/rag/approved/<id>.md + approved_manifest.json；KnowledgeBase.load_approved 读取。
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
from contextlib import contextmanager
from datetime import date
from pathlib import Path

from . import evals
from .approval import ApprovalPolicy
from .config import SILConfig
from .fetch import FetchRefused, fetch_page
from .freshness import content_hash, validate_entry
from .gates import GateThresholds
from .loop import EvalOutcome, Hooks, SelfImprovementLoop
from .sources import SourcePolicy
from .store import Candidate

HERE = Path(__file__).parent
RAG_DIR = HERE.parent / "rag"
APPROVED_DIR = Path(os.environ.get("SHUNSHI_APPROVED_KB_DIR") or RAG_DIR / "approved")

# 顺时没有数值计算类答案，calc_error 不适用；其余按公共默认值。
THRESHOLDS = GateThresholds(not_applicable=frozenset({"calc_error"}))


def load_registry() -> dict:
    return json.loads((HERE / "registry.json").read_text("utf-8"))


def build_config(env=None) -> SILConfig:
    reg = load_registry()
    return SILConfig.from_env("shunshi", env, allowed_domains=tuple(reg["allowed_domains"]), thresholds=THRESHOLDS,
                              families=("investment_advice", "medical_diagnosis", "deterministic_fate", "absolute_claim", "return_promise"))


class ShunshiHooks:
    def __init__(self, data_dir: str, *, fetch=fetch_page, approved_dir: Path = APPROVED_DIR, today: date | None = None):
        self.data = Path(data_dir)
        self.fetch = fetch
        self.approved_dir = Path(approved_dir)
        self.today = today or date.today()
        self.policy = SourcePolicy(allowed_domains=tuple(load_registry()["allowed_domains"]))
        (self.data / "inbox").mkdir(parents=True, exist_ok=True)
        (self.data / "state").mkdir(parents=True, exist_ok=True)

    # ----- collect -----
    def collect(self):
        st_path = self.data / "state" / "source_hashes.json"
        seen = json.loads(st_path.read_text("utf-8")) if st_path.exists() else {}
        for s in load_registry()["sources"]:
            try:
                page = self.fetch(s["url"], self.policy)
            except (FetchRefused, OSError, ValueError) as e:  # 单个来源失败不影响其它
                yield {"id": f"err-{s['id']}", "kind": "fetch_error", "url": s["url"], "license": s["license"], "origin": "external", "error": type(e).__name__, "source_id": s["id"]}
                continue
            changed = seen.get(s["id"]) not in (None, page["hash"])
            first = s["id"] not in seen
            yield {"id": f"src-{s['id']}-{page['hash'][:10]}", "kind": "source_page", "source_id": s["id"], "name": s["name"], "url": s["url"],
                   "license": s["license"], "origin": "external", "title": page["title"], "text": page["text"][:2000],
                   "hash": page["hash"], "changed": changed or first, "tier": s["tier"]}
        for f in sorted((self.data / "inbox").glob("*.json")):
            d = json.loads(f.read_text("utf-8"))
            d.setdefault("kind", "kb_draft")
            d.setdefault("origin", "external")
            d["id"] = d.get("id") or f.stem
            yield d

    # ----- propose -----
    def propose(self, records, budget: int) -> list[Candidate]:
        out: list[Candidate] = []
        # 用户可见的知识条目优先于「来源有更新」的工作项，免得工作项把编辑预算占满。
        for r in sorted(records, key=lambda x: 0 if x.get("kind") == "kb_draft" else 1):
            if len(out) >= budget:
                break
            if r.get("kind") == "source_page" and r.get("changed"):
                out.append(Candidate(
                    id=f"review-{r['source_id']}-{r['hash'][:10]}", kind="source_review", target=r["url"],
                    summary=f"来源「{r['name']}」页面有更新，请人工整理相关条目到 inbox/", user_visible=False,
                    payload={"hash": r["hash"], "source_id": r["source_id"], "excerpt": r["text"][:500]}, evidence=[{"url": r["url"], "hash": r["hash"]}]))
            elif r.get("kind") == "kb_draft":
                entry = {k: r.get(k) for k in ("id", "source_tier", "license", "valid_from", "valid_until", "origin", "url", "reviewer", "reviewed_at", "superseded_by")}
                entry["content_hash"] = content_hash(r.get("text", ""))
                if validate_entry(entry):
                    continue  # 字段不全的草稿不进入提案（周报里可见）
                out.append(Candidate(
                    id=f"kb-{r['id']}-{entry['content_hash'][:8]}", kind="kb_entry", target=f"approved/{r['id']}.md",
                    summary=f"新增/更新知识条目：{r.get('title', r['id'])}", user_visible=True,
                    payload={"text": r["text"], "title": r.get("title", r["id"]), "entry": entry, "publisher": r.get("publisher", ""), "published_at": r.get("published_at", "")},
                    evidence=[{"url": r.get("url", "")}]))
        return out

    # ----- evaluate -----
    def _metrics(self, split: str = "gate") -> dict:
        res = evals.evaluate_all(today=self.today)
        m = dict(res["splits"][split])
        m["redteam_pass_rate"] = res["safety"]["redteam_pass_rate"]
        m["cost_ratio"] = 1.0
        m["latency_ratio"] = 1.0
        return m

    def evaluate(self, c: Candidate) -> EvalOutcome:
        base = self._metrics()
        if c.kind != "kb_entry":
            return EvalOutcome(base, dict(base), no_skill={"recall_at_8": 0.0})
        with self._overlay(c):
            cand = self._metrics()
        cand["latency_ratio"] = cand.pop("latency_s", 0.0) / max(base.get("latency_s", 1e-9), 1e-9)
        base.pop("latency_s", None)
        n = max(base["n"], 1)
        se = {"recall_at_8": (base["recall_at_8"] * (1 - base["recall_at_8"]) / n) ** 0.5}
        return EvalOutcome(base, cand, no_skill={"recall_at_8": 0.0}, standard_errors=se)

    @contextmanager
    def _overlay(self, c: Candidate):
        """把候选条目临时放进内存知识库做评测，评测完恢复。只在批处理进程里使用。"""
        from app.rag.embedder import init_embedders
        from app.rag.knowledge_base import _parse_markdown_into_chunks, cn_kb

        saved = list(cn_kb.chunks)
        try:
            chunks = _parse_markdown_into_chunks(render_entry_md(c), "cn", source="approved")
            e = c.payload["entry"]
            for ch in chunks:
                ch.metadata.update({"source_file": f"approved/{e['id']}.md", "evidence_status": "verified_official", "high_risk_allowed": False,
                                    "reviewed_at": e["reviewed_at"], "valid_until": e["valid_until"], "reviewer": e["reviewer"], "url": e["url"]})
            cn_kb.chunks.extend(chunks)
            init_embedders()
            yield
        finally:
            cn_kb.chunks[:] = saved
            init_embedders()

    # ----- apply / rollback -----
    def apply(self, c: Candidate) -> dict:
        if c.kind == "source_review":
            with (self.data / "worklist.jsonl").open("a", encoding="utf-8") as f:
                f.write(json.dumps({"candidate": c.id, "url": c.target, "excerpt": c.payload.get("excerpt", "")}, ensure_ascii=False) + "\n")
            st_path = self.data / "state" / "source_hashes.json"
            st = json.loads(st_path.read_text("utf-8")) if st_path.exists() else {}
            prev = st.get(c.payload["source_id"])
            st[c.payload["source_id"]] = c.payload["hash"]
            st_path.write_text(json.dumps(st, ensure_ascii=False), "utf-8")
            return {"kind": "source_review", "source_id": c.payload["source_id"], "prev_hash": prev}
        e = c.payload["entry"]
        self.approved_dir.mkdir(parents=True, exist_ok=True)
        mpath = self.approved_dir / "approved_manifest.json"
        manifest = json.loads(mpath.read_text("utf-8")) if mpath.exists() else {"schema_version": "1.0", "entries": {}}
        prev_meta = manifest["entries"].get(e["id"])
        md = self.approved_dir / f"{e['id']}.md"
        prev_md = md.read_text("utf-8") if md.exists() else None
        md.write_text(render_entry_md(c), "utf-8")
        manifest["entries"][e["id"]] = {k: e[k] for k in ("reviewed_at", "valid_until", "valid_from", "reviewer", "url", "content_hash", "source_tier", "license") if e.get(k)}
        manifest["entries"][e["id"]]["candidate"] = c.id
        mpath.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True), "utf-8")
        return {"kind": "kb_entry", "id": e["id"], "prev_meta": prev_meta, "prev_md": prev_md}

    def rollback(self, c: Candidate) -> None:
        snap = c.snapshot or {}
        if snap.get("kind") == "source_review":
            st_path = self.data / "state" / "source_hashes.json"
            st = json.loads(st_path.read_text("utf-8")) if st_path.exists() else {}
            if snap.get("prev_hash") is None:
                st.pop(snap["source_id"], None)
            else:
                st[snap["source_id"]] = snap["prev_hash"]
            st_path.write_text(json.dumps(st, ensure_ascii=False), "utf-8")
            return
        if snap.get("kind") != "kb_entry":
            return
        mpath = self.approved_dir / "approved_manifest.json"
        manifest = json.loads(mpath.read_text("utf-8"))
        md = self.approved_dir / f"{snap['id']}.md"
        if snap.get("prev_meta") is None:
            manifest["entries"].pop(snap["id"], None)
            md.unlink(missing_ok=True)
        else:
            manifest["entries"][snap["id"]] = snap["prev_meta"]
            md.write_text(snap["prev_md"] or "", "utf-8")
        mpath.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True), "utf-8")

    # ----- monthly -----
    def entries(self):
        mpath = self.approved_dir / "approved_manifest.json"
        if mpath.exists():
            for eid, m in json.loads(mpath.read_text("utf-8")).get("entries", {}).items():
                yield {"id": eid, "origin": "external", **m}
        sm = json.loads((RAG_DIR / "source_manifest.json").read_text("utf-8"))
        for name, d in sm.get("documents", {}).items():
            tier = "official" if d.get("evidence_status") == "verified_official" else "legacy_unverified"
            yield {"id": name, "source_tier": tier, "license": "internal", "valid_from": d.get("reviewed_at", "2026-01-01"),
                   "valid_until": d.get("valid_until"), "content_hash": "n/a", "origin": "internal", "url": "n/a", "superseded_by": d.get("superseded_by")}

    def hooks(self) -> Hooks:
        return Hooks(collect=self.collect, propose=self.propose, evaluate=self.evaluate, apply=self.apply, rollback=self.rollback, entries=self.entries)


def render_entry_md(c: Candidate) -> str:
    p, e = c.payload, c.payload["entry"]
    return (
        f"# {p['title']}\n\n## 自改进入库\n\n### {p['title']}\n\n{p['text'].strip()}\n\n"
        f"来源：{p.get('publisher') or '官方来源'}，{p.get('published_at') or ''}；顺时复核日期：{e['reviewed_at']}。\n"
        f"链接：{e['url']}\n"
    )


def build_loop(env=None, *, data_dir: str | None = None, **kw) -> tuple[SelfImprovementLoop, ShunshiHooks]:
    cfg = build_config(env)
    if data_dir:
        cfg = SILConfig(**{**cfg.__dict__, "data_dir": data_dir})
    sh = ShunshiHooks(cfg.data_dir, **kw)
    return SelfImprovementLoop(cfg, sh.hooks(), approval=ApprovalPolicy.from_env(env)), sh
