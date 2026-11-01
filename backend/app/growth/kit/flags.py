"""Feature flags. All default OFF. Only the owner changes them on the server; OpenClaw has no permission to."""
from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Mapping


def _on(env: Mapping[str, str], key: str) -> bool:
    return str(env.get(key, "0")).strip().lower() in ("1", "true", "yes", "on")


@dataclass(frozen=True)
class GrowthFlags:
    growth_loop: bool = False   # GROWTH_LOOP_ENABLED
    referral: bool = False      # REFERRAL_ENABLED
    sharecard: bool = False     # SHARECARD_ENABLED
    seo_pages: bool = False     # SEO_PAGES_ENABLED

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> "GrowthFlags":
        env = os.environ if env is None else env
        return cls(
            growth_loop=_on(env, "GROWTH_LOOP_ENABLED"),
            referral=_on(env, "REFERRAL_ENABLED"),
            sharecard=_on(env, "SHARECARD_ENABLED"),
            seo_pages=_on(env, "SEO_PAGES_ENABLED"),
        )
