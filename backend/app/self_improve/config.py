"""自改进配置。默认全部关闭；对照比例不可配置（见 cohort.py）。"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Mapping

from .gates import GateThresholds


def _flag(env: Mapping[str, str], key: str, default: bool = False) -> bool:
    return str(env.get(key, "1" if default else "0")).strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class SILConfig:
    product: str
    enabled: bool = False  # SIL_ENABLED，默认关
    auto_promote_internal: bool = False  # 仅「用户不可见」且门禁全绿的改动才可自动晋升；默认也关
    max_proposals_per_week: int = 3
    data_dir: str = "var/self_improve"
    approval_timeout_hours: int = 72
    thresholds: GateThresholds = field(default_factory=GateThresholds)
    allowed_domains: tuple = ()
    families: tuple | None = None  # None = 全部词族

    @classmethod
    def from_env(cls, product: str, env: Mapping[str, str] | None = None, **overrides) -> "SILConfig":
        env = os.environ if env is None else env
        base = dict(
            product=product,
            enabled=_flag(env, "SIL_ENABLED"),
            auto_promote_internal=_flag(env, "SIL_AUTO_PROMOTE_INTERNAL"),
            max_proposals_per_week=min(int(env.get("SIL_MAX_PROPOSALS", "3")), 3),  # 上限写死 3
            data_dir=env.get("SIL_DATA_DIR", f"var/self_improve/{product}"),
            approval_timeout_hours=int(env.get("SIL_APPROVAL_TIMEOUT_HOURS", "72")),
        )
        base.update(overrides)
        return cls(**base)
