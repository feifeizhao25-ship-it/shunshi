"""
顺时 AI - Feature Flag 系统

轻量级 Feature Flag，支持:
- Prompt / Skill / 支付 / 内容灰度
- 百分比灰度（基于 user_id hash）
- 用户白名单
- A/B 测试变体选择
- SQLite 持久化 + 内存缓存（延迟 < 1ms）

使用示例:
    from app.feature_flags import flag_store

    if flag_store.is_enabled("prompt.v2_enabled", user_id):
        prompt = build_v2_prompt(...)
    else:
        prompt = build_v1_prompt(...)

    variant = flag_store.get_variant("ab.test_new_ui", user_id, variants=["control", "v2", "v3"])

作者: Claw 🦅
日期: 2026-03-18
"""

from app.feature_flags.store import flag_store, FlagStore, FlagValue, PRESET_FLAGS
from app.feature_flags.middleware import feature_flag_middleware

__all__ = [
    "flag_store",
    "FlagStore",
    "FlagValue",
    "PRESET_FLAGS",
    "feature_flag_middleware",
]
