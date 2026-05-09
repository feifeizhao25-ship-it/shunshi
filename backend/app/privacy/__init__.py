"""
顺时 反监控系统 / 隐私保护系统
Anti-Surveillance & Privacy Protection System

核心原则：
1. 父母知情与同意机制
2. 可关闭家庭共享入口
3. 家庭成员可见信息分层
4. 紧急状态才升级

作者: Claw 🦅
日期: 2026-04-29
"""

from .consent_manager import consent_manager, ConsentStatus
from .visibility_layers import visibility_engine, VisibilityLevel

__all__ = [
    "consent_manager",
    "ConsentStatus",
    "visibility_engine",
    "VisibilityLevel",
]
