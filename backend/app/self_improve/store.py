"""候选提案的生命周期与不可篡改的变更日志（哈希链）。

状态机（只允许下列转移，其余一律拒绝）：
quarantined → evaluated → (pending_approval | auto_ready | rejected)
pending_approval → (approved | rejected | expired)
approved/auto_ready → promoted → rolled_back
quarantined/evaluated → rejected
"""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
import threading
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

TRANSITIONS: dict[str, frozenset] = {
    "quarantined": frozenset({"evaluated", "rejected"}),
    "evaluated": frozenset({"pending_approval", "auto_ready", "rejected"}),
    "pending_approval": frozenset({"approved", "rejected", "expired"}),
    "approved": frozenset({"promoted", "rejected"}),
    "auto_ready": frozenset({"promoted", "rejected"}),
    "promoted": frozenset({"rolled_back"}),
    "rejected": frozenset(),
    "expired": frozenset(),
    "rolled_back": frozenset(),
}
TERMINAL = frozenset(k for k, v in TRANSITIONS.items() if not v)


class IllegalTransition(Exception):
    pass


@dataclass
class Candidate:
    id: str
    kind: str  # kb_entry | prompt | skill | rule | index_param
    target: str  # 被改动的对象，如 skill 名 / 文件路径 / 条目 id
    summary: str
    payload: dict = field(default_factory=dict)
    evidence: list = field(default_factory=list)  # [{url, retrieved_at, hash}]
    user_visible: bool = True  # 默认按用户可见处理 → 必须走企业微信审批
    needs_expert: bool = False  # 需要真实专家签字；本系统永不代签
    origin: str = "external"
    state: str = "quarantined"
    created_at: str = ""
    updated_at: str = ""
    history: list = field(default_factory=list)
    snapshot: dict | None = None  # 晋升前的快照，用于回滚


class Ledger:
    """追加写 JSONL，每行带上一行的 hash；``verify`` 可发现篡改。"""

    def __init__(self, path: Path):
        self.path = Path(path)
        self._lock = threading.Lock()

    def _last_hash(self) -> str:
        if not self.path.exists():
            return "0" * 64
        last = ""
        with self.path.open("r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    last = line
        return json.loads(last)["hash"] if last else "0" * 64

    def append(self, event: dict) -> dict:
        with self._lock:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            body = {"event": event, "prev": self._last_hash()}
            raw = json.dumps(body, ensure_ascii=False, sort_keys=True)
            body["hash"] = hashlib.sha256(raw.encode("utf-8")).hexdigest()
            with self.path.open("a", encoding="utf-8") as f:
                f.write(json.dumps(body, ensure_ascii=False, sort_keys=True) + "\n")
            return body

    def entries(self) -> list[dict]:
        if not self.path.exists():
            return []
        return [json.loads(x) for x in self.path.read_text(encoding="utf-8").splitlines() if x.strip()]

    def verify(self) -> bool:
        prev = "0" * 64
        for row in self.entries():
            h = row.get("hash")
            body = {"event": row["event"], "prev": row["prev"]}
            raw = json.dumps(body, ensure_ascii=False, sort_keys=True)
            if row["prev"] != prev or hashlib.sha256(raw.encode("utf-8")).hexdigest() != h:
                return False
            prev = h
        return True


class CandidateStore:
    """目录布局：candidates/<id>.json（隔离区即这里，不进生产索引），changelog.jsonl。"""

    def __init__(self, root: str | os.PathLike, clock=None):
        self.root = Path(root)
        (self.root / "candidates").mkdir(parents=True, exist_ok=True)
        self.ledger = Ledger(self.root / "changelog.jsonl")
        self._clock = clock or _now_iso

    def set_clock(self, clock) -> None:
        self._clock = clock

    def _path(self, cid: str) -> Path:
        safe = "".join(c for c in cid if c.isalnum() or c in "-_.")
        if safe != cid or not cid:
            raise ValueError("bad_candidate_id")
        return self.root / "candidates" / f"{cid}.json"

    def _write(self, c: Candidate) -> None:
        p = self._path(c.id)
        fd, tmp = tempfile.mkstemp(dir=str(p.parent), prefix=".tmp-")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(asdict(c), f, ensure_ascii=False, indent=2, sort_keys=True)
        os.replace(tmp, p)

    def add(self, c: Candidate) -> Candidate:
        if self._path(c.id).exists():
            return self.get(c.id)  # 幂等：同 id 不重复入库
        c.state = "quarantined"
        c.created_at = c.updated_at = self._clock()
        self._write(c)
        self.ledger.append({"t": c.created_at, "id": c.id, "to": "quarantined", "target": c.target, "kind": c.kind})
        return c

    def get(self, cid: str) -> Candidate:
        return Candidate(**json.loads(self._path(cid).read_text(encoding="utf-8")))

    def list(self, state: str | None = None) -> list[Candidate]:
        out = []
        for p in sorted((self.root / "candidates").glob("*.json")):
            c = Candidate(**json.loads(p.read_text(encoding="utf-8")))
            if state is None or c.state == state:
                out.append(c)
        return out

    def transition(self, cid: str, new_state: str, **detail: Any) -> Candidate:
        c = self.get(cid)
        if new_state not in TRANSITIONS.get(c.state, frozenset()):
            raise IllegalTransition(f"{c.state}->{new_state}")
        now = self._clock()
        c.history.append({"t": now, "from": c.state, "to": new_state, **detail})
        c.state, c.updated_at = new_state, now
        if "snapshot" in detail:
            c.snapshot = detail["snapshot"]
        self._write(c)
        self.ledger.append({"t": now, "id": cid, "to": new_state, **{k: v for k, v in detail.items() if k != "snapshot"}})
        return c


def _now_iso() -> str:
    from datetime import datetime, timezone, timedelta

    return datetime.now(timezone(timedelta(hours=8))).isoformat(timespec="seconds")
