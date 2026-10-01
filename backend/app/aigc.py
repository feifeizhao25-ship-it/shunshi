"""AI 生成内容的显式标识（国内版）。

《人工智能拟人化互动服务管理暂行办法》（2026-07-15 施行）与顺时红线要求：
AI 生成的内容要有显式标识，且不得删除、隐藏；对话界面要常驻「你在和人工智能对话，不是真人」的提示。

界面由客户端画，但客户端只能显示后端给的东西——所以每个 AI 出口的响应都带这三项，
文案只在这里定义一份，改措辞不用满仓库找。
"""

from __future__ import annotations

from typing import Any

AI_LABEL = "AI 生成"
AI_IDENTITY_NOTICE = "你在和人工智能对话，不是真人"


def ai_disclosure() -> dict[str, Any]:
    return {
        "ai_generated": True,
        "ai_label": AI_LABEL,
        "ai_notice": AI_IDENTITY_NOTICE,
    }


# 音频没有可见的面，用响应头做隐式标识（可见的「AI 生成」由客户端在播放界面展示）。
AI_HEADERS = {"X-AI-Generated": "true"}

PROMPT_REFUSED = "这个内容无法生成，请换一个描述"


def ensure_prompt_allowed(text: str, user_id: str = "anonymous") -> None:
    """图片、视频、语音生成前的内容安全检查：命中禁止类内容（暴力、色情等）直接拒绝，不调用模型。"""
    from fastapi import HTTPException

    from .safety.guard import safety_guard

    result = safety_guard.check_input(text, {"user_id": user_id})
    if result.should_block and result.flag == "blocked":
        raise HTTPException(status_code=400, detail=PROMPT_REFUSED)
