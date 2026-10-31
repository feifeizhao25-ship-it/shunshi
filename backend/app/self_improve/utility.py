"""技能 / 知识条目的效用账本与「退役名单」（只靠标准库）。

思路来自 Selm（arXiv 2610.24630）的三件事：按效用重排检索、验证门（本仓已有 gates）、名字级退役名单。
论文里的数值（容量 30、EMA α=0.4）只是起点，**必须用本产品自己的评测集离线校准**，这里全部可配置。

只记录、排序、给出建议；**不会自动删除或改动任何线上内容**。用户可见的改动仍走企业微信审批。
"""

from __future__ import annotations

import json
import os
import re
import tempfile
import unicodedata
from dataclasses import dataclass, asdict
from datetime import date
from pathlib import Path
from typing import Callable, Iterable, Mapping, Sequence

DEFAULT_ALPHA = 0.4
DEFAULT_UTILITY = 0.5  # 没有观测时的中性先验


def normalize_name(name: str) -> str:
    """名字级匹配：NFKC、小写、去掉空白与标点，避免靠改个标点/全半角让同名复活。"""
    s = unicodedata.normalize("NFKC", str(name or "")).lower()
    return re.sub(r"[\s\W_]+", "", s, flags=re.UNICODE)


@dataclass
class UtilityRecord:
    ema: float = DEFAULT_UTILITY
    n: int = 0
    last_seen: str = ""


class UtilityLedger:
    """目录布局：``utility_ledger.json``（EMA 与计数）。写入走临时文件 + 原子替换。"""

    def __init__(self, root: str | os.PathLike, *, alpha: float = DEFAULT_ALPHA, capacity: int | None = None, clock: Callable[[], str] | None = None):
        if not 0.0 < alpha <= 1.0:
            raise ValueError("alpha_out_of_range")
        self.root = Path(root)
        self.alpha, self.capacity = alpha, capacity
        self._clock = clock or (lambda: date.today().isoformat())
        self._path = self.root / "utility_ledger.json"

    # ---------- 持久化 ----------
    def _load(self) -> dict:
        if not self._path.exists():
            return {"records": {}, "graveyard": {}}
        data = json.loads(self._path.read_text("utf-8"))
        data.setdefault("records", {})
        data.setdefault("graveyard", {})
        return data

    def _save(self, data: dict) -> None:
        self.root.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=str(self.root), prefix=".tmp-")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        os.replace(tmp, self._path)

    # ---------- 效用 ----------
    def record(self, name: str, outcome: float) -> UtilityRecord:
        """记一次观测（0..1，1=有用/通过）。EMA：新值 = α·观测 + (1-α)·旧值；首次观测直接取观测值。"""
        if not 0.0 <= float(outcome) <= 1.0:
            raise ValueError("outcome_out_of_range")
        key = normalize_name(name)
        if not key:
            raise ValueError("empty_name")
        data = self._load()
        rec = UtilityRecord(**data["records"].get(key, {}))
        rec.ema = float(outcome) if rec.n == 0 else self.alpha * float(outcome) + (1 - self.alpha) * rec.ema
        rec.n += 1
        rec.last_seen = self._clock()
        data["records"][key] = asdict(rec)
        self._save(data)
        return rec

    def get(self, name: str) -> UtilityRecord:
        return UtilityRecord(**self._load()["records"].get(normalize_name(name), {}))

    def utility(self, name: str, default: float = DEFAULT_UTILITY) -> float:
        rec = self._load()["records"].get(normalize_name(name))
        return default if not rec or rec.get("n", 0) == 0 else float(rec["ema"])

    def rank(self, items: Iterable[tuple[str, float]], *, weight: float = 0.3) -> list[tuple[str, float]]:
        """效用感知的重排：score = (1-w)·相关度 + w·效用。weight=0 即回到纯相关度。稳定排序。"""
        if not 0.0 <= weight <= 1.0:
            raise ValueError("weight_out_of_range")
        data = self._load()["records"]
        def u(n: str) -> float:
            r = data.get(normalize_name(n))
            return DEFAULT_UTILITY if not r or r.get("n", 0) == 0 else float(r["ema"])
        scored = [(n, (1 - weight) * float(rel) + weight * u(n)) for n, rel in items]
        return sorted(scored, key=lambda x: -x[1])

    # ---------- 退役名单（名字级） ----------
    def bury(self, name: str, reason: str, today: str | None = None) -> None:
        key = normalize_name(name)
        if not key or not reason:
            raise ValueError("name_and_reason_required")
        data = self._load()
        data["graveyard"][key] = {"name": str(name), "reason": reason, "date": today or self._clock()}
        self._save(data)

    def is_buried(self, name: str) -> bool:
        return normalize_name(name) in self._load()["graveyard"]

    def graveyard(self) -> dict:
        return dict(self._load()["graveyard"])

    def unbury(self, name: str, reviewer: str, can_approve: Callable[[str], bool]) -> bool:
        """名单内的名字只有「有权批准的人」才能放回；名单为空时无人可放（沿用 POLICY_REVIEWERS 语义）。"""
        if not can_approve(reviewer):
            raise PermissionError("reviewer_not_authorised")
        data = self._load()
        gone = data["graveyard"].pop(normalize_name(name), None)
        if gone is not None:
            self._save(data)
        return gone is not None

    # ---------- 清点建议（只给名单） ----------
    def retire_candidates(self, *, min_obs: int = 5, below: float = 0.3) -> list[str]:
        """观测够多且效用仍低 → 建议退役。返回规范化名字，由调用方走审批后再执行。"""
        recs = self._load()["records"]
        return sorted(k for k, r in recs.items() if r.get("n", 0) >= min_obs and r.get("ema", 1.0) < below)

    def prune_plan(self, names: Sequence[str]) -> list[str]:
        """超过容量时，建议合并或删除的名字（效用最低的优先）。不超容量返回空。只能合并/删除，不能凭空新增。"""
        if not self.capacity or len(names) <= self.capacity:
            return []
        order = sorted(names, key=lambda n: (self.utility(n), str(n)))
        return order[: len(names) - self.capacity]
