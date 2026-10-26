"""Wilson 下限，用来决定对照和实验谁更好。样本不够就不要晋升。"""

from __future__ import annotations

import math


def wilson_lower(successes: int, total: int, z: float = 1.96) -> float:
    if total <= 0 or successes < 0 or successes > total:
        return 0.0
    proportion = successes / total
    z2 = z * z
    denom = 1 + z2 / total
    centre = proportion + z2 / (2 * total)
    margin = z * math.sqrt((proportion * (1 - proportion) + z2 / (4 * total)) / total)
    return max(0.0, (centre - margin) / denom)
