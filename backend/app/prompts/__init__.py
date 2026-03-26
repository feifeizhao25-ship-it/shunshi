"""
顺时 AI - Prompt 版本管理系统

功能：
- DB 持久化的 Prompt 版本管理
- 灰度发布（集成 Feature Flag）
- 一键回滚
- 变量模板预览
- 不影响现有 chat 流程（降级到默认 prompt）

使用示例:
    from app.prompts import prompt_store

    # 获取 prompt（自动处理灰度）
    system_prompt = prompt_store.get_prompt("chat.system")

    # 带用户上下文
    system_prompt = prompt_store.get_prompt("chat.system", user_id="user-123")

作者: Claw 🦅
日期: 2026-03-18
"""

from app.prompts.store import (
    prompt_store,
    PromptStore,
    PromptVersion,
    PromptInfo,
    PRESET_PROMPTS,
)

__all__ = [
    "prompt_store",
    "PromptStore",
    "PromptVersion",
    "PromptInfo",
    "PRESET_PROMPTS",
]
