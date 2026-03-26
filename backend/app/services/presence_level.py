"""
顺时 - 在线感知等级 (Presence Level)

根据对话频率自动计算用户活跃程度:
- present (主动): 1小时内多次对话，用户正在活跃交互
- normal (适时): 正常间隔，常规交互
- retreating (退让): 长时间未对话，不宜主动打扰

作者: Claw
日期: 2026-03-17
"""

import logging
from datetime import datetime, timedelta
from typing import List, Optional

logger = logging.getLogger(__name__)


class PresenceLevel:
    """在线感知等级"""

    PRESENT = "present"      # 主动 - 用户正在活跃交互
    NORMAL = "normal"        # 适时 - 正常间隔
    RETREATING = "retreating"  # 退让 - 长时间未对话

    ALL = [PRESENT, NORMAL, RETREATING]


def calculate_presence_level(
    message_timestamps: Optional[List[str]] = None,
    current_time: Optional[datetime] = None,
) -> str:
    """
    根据对话时间戳计算 presence_level

    Args:
        message_timestamps: 该用户最近的对话时间戳列表 (ISO format)
        current_time: 当前时间（用于测试注入）

    Returns:
        presence_level: "present" | "normal" | "retreating"
    """
    now = current_time or datetime.now()

    if not message_timestamps or len(message_timestamps) == 0:
        return PresenceLevel.RETREATING

    # 解析时间戳，过滤无效的
    timestamps = []
    for ts in message_timestamps:
        try:
            if isinstance(ts, datetime):
                timestamps.append(ts)
            else:
                timestamps.append(datetime.fromisoformat(ts))
        except (ValueError, TypeError):
            continue

    if not timestamps:
        return PresenceLevel.RETREATING

    # 按时间倒序
    timestamps.sort(reverse=True)
    most_recent = timestamps[0]

    # 计算距最近一条消息的时间差
    time_since_last = (now - most_recent).total_seconds()

    if time_since_last > 24 * 3600:  # > 24小时
        return PresenceLevel.RETREATING

    if time_since_last > 4 * 3600:  # > 4小时
        return PresenceLevel.RETREATING

    # 统计最近1小时内的消息数
    one_hour_ago = now - timedelta(hours=1)
    recent_count = sum(1 for ts in timestamps if ts >= one_hour_ago)

    if recent_count >= 3:
        return PresenceLevel.PRESENT

    if recent_count >= 1:
        return PresenceLevel.NORMAL

    # 1~4小时内只有旧消息
    if time_since_last <= 2 * 3600:  # <= 2小时
        return PresenceLevel.NORMAL

    return PresenceLevel.RETREATING


def get_presence_config(level: str) -> dict:
    """
    根据 presence_level 返回前端配置

    Returns:
        dict: 包含前端可用的展示配置
    """
    configs = {
        PresenceLevel.PRESENT: {
            "show_suggestions": True,
            "max_suggestions": 5,
            "show_quick_replies": True,
            "proactive_greeting": False,  # 已在对话中，不需要问候
            "ui_density": "full",
        },
        PresenceLevel.NORMAL: {
            "show_suggestions": True,
            "max_suggestions": 3,
            "show_quick_replies": True,
            "proactive_greeting": True,
            "ui_density": "normal",
        },
        PresenceLevel.RETREATING: {
            "show_suggestions": False,
            "max_suggestions": 0,
            "show_quick_replies": True,  # 保留快捷回复按钮方便触发
            "proactive_greeting": True,
            "ui_density": "minimal",
        },
    }

    return configs.get(level, configs[PresenceLevel.NORMAL])
