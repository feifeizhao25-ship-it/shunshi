"""自家渠道的分流。15% 对照由哈希桶固定，不提供配置项。"""

from __future__ import annotations

import hashlib
import random

from app.growth.constants import BUCKET_SLOTS, CONTROL_SLOTS


def assign_bucket(unit_id: str, experiment_key: str) -> str:
    digest = hashlib.sha256(f"{experiment_key}\n{unit_id}".encode()).hexdigest()
    slot = int(digest[:8], 16) % BUCKET_SLOTS
    return "control" if slot < CONTROL_SLOTS else "treatment"


def thompson_sample(alpha: float, beta: float) -> float:
    """只在自家渠道的候选之间抽样。alpha/beta 来自已观测的成败次数。"""
    if alpha <= 0 or beta <= 0:
        return 0.0
    return random.betavariate(alpha, beta)


def judge_outcome(
    control_success: int,
    control_total: int,
    treatment_success: int,
    treatment_total: int,
    *,
    eval_ok: bool,
) -> str:
    from app.growth.experiments.wilson import wilson_lower

    if not eval_ok:
        return "rollback"
    if control_total < 1 or treatment_total < 1:
        return "no_change"
    treatment_bound = wilson_lower(treatment_success, treatment_total)
    control_bound = wilson_lower(control_success, control_total)
    if treatment_bound > control_bound:
        return "promote"
    if treatment_bound < control_bound:
        return "rollback"
    return "no_change"
