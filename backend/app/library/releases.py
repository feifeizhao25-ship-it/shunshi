"""资料库版本发布与回滚：每次人工审核动作（promote/approve/update/repeal/rollback）都留一份完整快照，哈希串成链。

  releases/NNNN.json   {version, at, action, entry_id, reviewer, note, doc_sha256, prev_sha256, gate(可选), document}
  releases/index.jsonl 每行一条（不含 document），记录 sha256 链；任何一行被改都能查出来（verify）。
回滚 = 把工作文档恢复成某个旧版本的内容，并**追加**一条 rollback 发布（不删历史）。回滚同样要求审核人姓名。
这里不碰 RAG 知识库，也不碰用户数据。
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime
from pathlib import Path
from typing import Optional


class ReleaseError(ValueError):
    pass


def _sha(obj) -> str:
    return hashlib.sha256(json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()


def _dir(base: Path) -> Path:
    d = Path(base) / "releases"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _index(base: Path) -> list[dict]:
    p = _dir(base) / "index.jsonl"
    return [json.loads(x) for x in p.read_text("utf-8").splitlines() if x.strip()] if p.exists() else []


def list_releases(base: Path) -> list[dict]:
    return _index(base)


def record(base: Path, doc: dict, *, action: str, entry_id: str, reviewer: str, note: str = "", gate: Optional[dict] = None) -> dict:
    if not (reviewer or "").strip():
        raise ReleaseError("reviewer name is required")
    idx = _index(base)
    version = (idx[-1]["version"] + 1) if idx else 1
    rec = {"version": version, "at": datetime.now().astimezone().isoformat(timespec="seconds"), "action": action, "entry_id": entry_id, "reviewer": reviewer.strip(),
           "note": note, "doc_sha256": _sha(doc), "prev_sha256": idx[-1]["sha256"] if idx else "0" * 64}
    if gate:
        rec["gate"] = {k: gate[k] for k in ("decision", "evidence", "safety") if k in gate}
    rec["sha256"] = _sha(rec)
    d = _dir(base)
    (d / f"{version:04d}.json").write_text(json.dumps({**rec, "document": doc}, ensure_ascii=False, indent=1), "utf-8")
    with (d / "index.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    return rec


def verify(base: Path) -> dict:
    """检查哈希链 + 每份快照内容与记录一致。返回 {ok, problems[]}。"""
    problems = []
    prev = "0" * 64
    for r in _index(base):
        body = {k: v for k, v in r.items() if k != "sha256"}
        if _sha(body) != r["sha256"]:
            problems.append(f"v{r['version']}: 记录被改动")
        if r["prev_sha256"] != prev:
            problems.append(f"v{r['version']}: 链断开")
        prev = r["sha256"]
        snap = _dir(base) / f"{r['version']:04d}.json"
        if not snap.exists():
            problems.append(f"v{r['version']}: 快照缺失")
        else:
            doc = json.loads(snap.read_text("utf-8"))["document"]
            if _sha(doc) != r["doc_sha256"]:
                problems.append(f"v{r['version']}: 快照内容与记录不一致")
    return {"ok": not problems, "problems": problems}


def load_document(base: Path, version: int) -> dict:
    snap = _dir(base) / f"{version:04d}.json"
    if not snap.exists():
        raise ReleaseError(f"no such release: {version}")
    return json.loads(snap.read_text("utf-8"))["document"]


def rollback(base: Path, to_version: int, reviewer: str, note: str) -> dict:
    """返回恢复后的文档；调用方负责写回 reference_entries.json。先校验链完整，避免回滚到被篡改的快照。"""
    if not (note or "").strip():
        raise ReleaseError("note is required for rollback")
    v = verify(base)
    if not v["ok"]:
        raise ReleaseError("release chain broken: " + "; ".join(v["problems"]))
    doc = load_document(base, to_version)
    record(base, doc, action="rollback", entry_id=f"v{to_version}", reviewer=reviewer, note=note)
    return doc
