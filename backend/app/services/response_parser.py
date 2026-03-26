"""
顺时 - AI 响应解析器 (3级降级)

Level 1: 完整 JSON Schema
Level 2: Markdown 代码块中提取 JSON
Level 3: 纯文本降级

作者: Claw
日期: 2026-03-17
"""

import json
import re
import logging
from typing import Optional

logger = logging.getLogger(__name__)


def parse_ai_response(raw_text: str) -> dict:
    """
    3级降级解析 AI 输出

    AI 模型可能返回:
    1. 规范的 JSON Schema
    2. 包裹在 ```json ... ``` 中的 JSON
    3. 纯文本（降级兜底）
    """
    if not raw_text or not raw_text.strip():
        return _fallback_response("")

    # Level 1: 尝试解析完整 JSON
    result = _try_parse_json(raw_text)
    if result:
        logger.info("[ResponseParser] Level 1: 完整 JSON 解析成功")
        return result

    # Level 2: 尝试从 markdown 代码块中提取 JSON
    result = _try_parse_json_from_codeblock(raw_text)
    if result:
        logger.info("[ResponseParser] Level 2: 代码块 JSON 解析成功")
        return result

    # Level 3: 纯文本降级
    logger.warning("[ResponseParser] Level 3: 纯文本降级")
    return _fallback_response(raw_text.strip())


def _normalize_response(raw: dict) -> Optional[dict]:
    """将解析出的 JSON 规范化为标准响应格式"""
    if not isinstance(raw, dict):
        return None

    # 必须有 text 字段
    text = raw.get("text", "")
    if not text and isinstance(text, str):
        return None

    return {
        "text": str(text),
        "tone": raw.get("tone", "gentle"),
        "care_status": raw.get("care_status", "stable"),
        "follow_up": raw.get("follow_up", None),
        "safety_flag": raw.get("safety_flag", "none"),
        "offline_encouraged": raw.get("offline_encouraged", False),
    }


def _try_parse_json(raw_text: str) -> Optional[dict]:
    """Level 1: 直接 JSON 解析"""
    try:
        result = json.loads(raw_text)
        return _normalize_response(result)
    except (json.JSONDecodeError, TypeError, ValueError):
        return None


def _try_parse_json_from_codeblock(raw_text: str) -> Optional[dict]:
    """Level 2: 从 markdown 代码块提取 JSON"""
    # 匹配 ```json ... ``` 或 ``` ... ```
    patterns = [
        r"```json\s*(.*?)\s*```",
        r"```\s*(.*?)\s*```",
    ]

    for pattern in patterns:
        match = re.search(pattern, raw_text, re.DOTALL)
        if match:
            try:
                result = json.loads(match.group(1))
                normalized = _normalize_response(result)
                if normalized:
                    return normalized
            except (json.JSONDecodeError, TypeError, ValueError):
                continue

    return None


def _fallback_response(text: str) -> dict:
    """Level 3: 纯文本降级"""
    return {
        "text": text or "抱歉，我暂时无法回复，请稍后再试试~",
        "tone": "gentle",
        "care_status": "stable",
        "follow_up": None,
        "safety_flag": "none",
        "offline_encouraged": False,
    }
