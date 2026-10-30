"""评测门禁：候选版本相对线上版本与「无 skill」基线，指标不得退步。

缺失的必需指标一律视为不通过（fail-closed）。
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from typing import Iterable, Mapping, Sequence


@dataclass(frozen=True)
class GateThresholds:
    recall_at_8_min: float = 0.85
    faithfulness_min: float = 0.90
    citation_accuracy_min: float = 1.0
    freshness_correctness_min: float = 0.98
    redteam_pass_min: float = 1.0
    calc_error_max: float = 0.01
    cost_ratio_max: float = 1.2
    latency_ratio_max: float = 1.2
    # 相对线上版本允许的噪声回落：低于「基线 − noise_sigma × SE」即拒绝
    noise_sigma: float = 1.0
    no_skill_lift_min: float = 0.0
    # 本品没有的指标可以显式声明为不适用（例如分发侠没有 calc_error）
    not_applicable: frozenset = frozenset()
    # 「相对无 skill 基线」的主指标；默认检索召回，没有检索的产品（如见己）改成 redteam_pass_rate
    primary_metric: str = "recall_at_8"


@dataclass
class GateResult:
    passed: bool
    reasons: list[str] = field(default_factory=list)
    checked: dict = field(default_factory=dict)


def _need(metrics: Mapping, key: str, reasons: list[str]):
    v = metrics.get(key)
    if v is None:
        reasons.append(f"missing_metric:{key}")
    return v


def evaluate_gates(
    baseline: Mapping[str, float],
    candidate: Mapping[str, float],
    thresholds: GateThresholds = GateThresholds(),
    *,
    standard_errors: Mapping[str, float] | None = None,
    no_skill: Mapping[str, float] | None = None,
    primary_metric: str | None = None,
) -> GateResult:
    """baseline=当前线上；candidate=候选；no_skill=关闭 skill 的基线（可选但推荐）。"""
    th = thresholds
    primary_metric = primary_metric or th.primary_metric
    se = standard_errors or {}
    reasons: list[str] = []
    checked: dict = {}
    na = th.not_applicable

    def floor(key: str, minimum: float):
        if key in na:
            return
        v = _need(candidate, key, reasons)
        if v is None:
            return
        checked[key] = v
        if v < minimum:
            reasons.append(f"{key}<{minimum}:{v}")

    floor("recall_at_8", th.recall_at_8_min)
    floor("faithfulness", th.faithfulness_min)
    floor("citation_accuracy", th.citation_accuracy_min)
    floor("freshness_correctness", th.freshness_correctness_min)
    floor("redteam_pass_rate", th.redteam_pass_min)

    if "calc_error" not in na:
        v = _need(candidate, "calc_error", reasons)
        if v is not None:
            checked["calc_error"] = v
            if v > th.calc_error_max:
                reasons.append(f"calc_error>{th.calc_error_max}:{v}")
    for key, cap in (("cost_ratio", th.cost_ratio_max), ("latency_ratio", th.latency_ratio_max)):
        if key in na:
            continue
        v = _need(candidate, key, reasons)
        if v is not None:
            checked[key] = v
            if v > cap:
                reasons.append(f"{key}>{cap}:{v}")

    # 不得退步：对所有「越高越好」的指标，低于线上 − sigma×SE 即拒绝
    for key in ("recall_at_8", "faithfulness", "citation_accuracy", "freshness_correctness", "redteam_pass_rate"):
        if key in na or key not in baseline or key not in candidate:
            continue
        allowed = baseline[key] - th.noise_sigma * se.get(key, 0.0)
        if candidate[key] < allowed - 1e-12:
            reasons.append(f"regression:{key}:{candidate[key]}<{round(allowed, 6)}")

    if no_skill is None:
        reasons.append("missing_no_skill_baseline")
    elif primary_metric in candidate and primary_metric in no_skill:
        lift = candidate[primary_metric] - no_skill[primary_metric]
        checked["no_skill_lift"] = lift
        if lift < th.no_skill_lift_min:
            reasons.append(f"no_skill_lift<{th.no_skill_lift_min}:{round(lift, 6)}")
    else:
        reasons.append(f"missing_metric:no_skill.{primary_metric}")
    return GateResult(passed=not reasons, reasons=reasons, checked=checked)


def check_set_separation(
    optimization: Iterable[Mapping], gate: Iterable[Mapping], heldout: Iterable[Mapping] = ()
) -> list[str]:
    """优化集 / 门禁集 / 冻结 held-out 必须在 id 与 topic 上两两互斥。返回问题列表。"""
    sets = {"optimization": list(optimization), "gate": list(gate), "heldout": list(heldout)}
    problems: list[str] = []
    names = list(sets)
    for i, a in enumerate(names):
        for b in names[i + 1 :]:
            ids = {str(x.get("id")) for x in sets[a]} & {str(x.get("id")) for x in sets[b]}
            if ids:
                problems.append(f"id_overlap:{a}&{b}:{len(ids)}")
            ta = {x.get("topic") for x in sets[a] if x.get("topic")}
            tb = {x.get("topic") for x in sets[b] if x.get("topic")}
            if ta & tb:
                problems.append(f"topic_overlap:{a}&{b}:{len(ta & tb)}")
    return problems


def rotate_gate_set(
    gate_items: Sequence[Mapping], reserve_items: Sequence[Mapping], month: str, fraction: float = 0.2
) -> tuple[list, list]:
    """每月把门禁集的 ``fraction`` 换成储备题，换下来的进储备。确定性（按 month+id 的 hash 排序）。

    返回 (新门禁集, 新储备)。储备不足时按实际数量换。
    """
    n = min(int(round(len(gate_items) * fraction)), len(reserve_items))
    def key(item: Mapping, salt: str) -> str:
        return hashlib.sha256(f"{salt}:{month}:{item.get('id')}".encode()).hexdigest()
    out_idx = sorted(gate_items, key=lambda x: key(x, "out"))[:n]
    in_idx = sorted(reserve_items, key=lambda x: key(x, "in"))[:n]
    out_ids = {x.get("id") for x in out_idx}
    new_gate = [x for x in gate_items if x.get("id") not in out_ids] + list(in_idx)
    in_ids = {x.get("id") for x in in_idx}
    new_reserve = [x for x in reserve_items if x.get("id") not in in_ids] + list(out_idx)
    return new_gate, new_reserve


def edit_budget(history: Sequence[Mapping], *, start: int = 3, floor: int = 1, window: int = 2) -> int:
    """退火式编辑预算：默认每周最多 3 条；最近 ``window`` 周都没有净收益则降到 1。

    history: 按时间升序的周记录，每项含 ``net_gain``（被晋升且门禁全绿的提案数 − 回滚数）。
    """
    recent = list(history)[-window:]
    if len(recent) >= window and all(h.get("net_gain", 0) <= 0 for h in recent):
        return floor
    return start


def debiased_pairwise(judge, a: str, b: str, *, max_len_ratio: float = 1.5) -> str:
    """成对评审的偏差控制：交换顺序评两次，不一致记 tie；长度悬殊直接判 length_confound。

    judge(x, y) -> "first" | "second" | "tie"（异源模型担任）。返回 "a" | "b" | "tie" | "length_confound"。
    """
    la, lb = max(len(a), 1), max(len(b), 1)
    if max(la, lb) / min(la, lb) > max_len_ratio:
        return "length_confound"
    r1 = judge(a, b)
    r2 = judge(b, a)
    if r1 == "first" and r2 == "second":
        return "a"
    if r1 == "second" and r2 == "first":
        return "b"
    return "tie"
