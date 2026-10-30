"""永久对照组与灰度分桶。

对照比例写死在常量里，不随环境变量改变，避免被配成 0：
sha256(user_id) 取 10000 个桶，前 1500 个（15%）永久对照；
紧随其后的 ``CANARY_SLOTS`` 个桶是灰度组。对照组永不进入任何实验。
"""

from __future__ import annotations

import hashlib

BUCKET_SLOTS = 10000
CONTROL_SLOTS = 1500  # 15%，永久
CANARY_SLOTS = 1000  # 10%


def bucket(user_id: str) -> int:
    digest = hashlib.sha256(str(user_id).encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % BUCKET_SLOTS


def in_control(user_id: str) -> bool:
    return bucket(user_id) < CONTROL_SLOTS


def in_canary(user_id: str) -> bool:
    b = bucket(user_id)
    return CONTROL_SLOTS <= b < CONTROL_SLOTS + CANARY_SLOTS


def arm(user_id: str, *, canary_active: bool) -> str:
    """返回 'control' | 'canary' | 'stable'。灰度未开启时非对照用户一律 stable。"""
    if in_control(user_id):
        return "control"
    if canary_active and in_canary(user_id):
        return "canary"
    return "stable"
