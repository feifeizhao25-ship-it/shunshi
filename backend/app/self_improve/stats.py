"""统计工具：Wilson 区间、噪声下限。只依赖标准库。"""

from __future__ import annotations

import math


def wilson_interval(successes: int, total: int, z: float = 1.96) -> tuple[float, float]:
    """Wilson 得分区间 (下限, 上限)。样本为 0 或参数非法时返回 (0, 1)：什么都不能证明。"""
    if total <= 0 or successes < 0 or successes > total:
        return 0.0, 1.0
    p = successes / total
    z2 = z * z
    denom = 1 + z2 / total
    centre = p + z2 / (2 * total)
    margin = z * math.sqrt((p * (1 - p) + z2 / (4 * total)) / total)
    return max(0.0, (centre - margin) / denom), min(1.0, (centre + margin) / denom)


def wilson_lower(successes: int, total: int, z: float = 1.96) -> float:
    return wilson_interval(successes, total, z)[0]


def wilson_superior(
    cand_successes: int,
    cand_total: int,
    ctl_successes: int,
    ctl_total: int,
    *,
    min_total: int = 100,
    z: float = 1.96,
) -> bool:
    """候选组 Wilson 下限高于对照组 Wilson 上限才算更优（保守判定）。

    任一组样本低于 ``min_total`` 一律判否：样本不够就不要晋升。
    """
    if cand_total < min_total or ctl_total < min_total:
        return False
    cand_lo, _ = wilson_interval(cand_successes, cand_total, z)
    _, ctl_hi = wilson_interval(ctl_successes, ctl_total, z)
    return cand_lo > ctl_hi


def proportion_se(p: float, n: int) -> float:
    """比例的标准误。n<=0 时返回 1（等于不可信）。"""
    if n <= 0:
        return 1.0
    p = min(max(p, 0.0), 1.0)
    return math.sqrt(p * (1 - p) / n)
