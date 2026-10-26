"""顺时 AI 安全守卫。

叶子模块（例如 efficacy）被别的包导入时，不能在这里建审计表。
内容库的初始化会往标准输出打 [DB]，管理员会话校验这类不相干的导入不该触发它。
守卫本身仍在 app.safety.guard 里，第一次用到 SafetyGuard 时才加载。
"""

__all__ = [
    "SafetyGuard",
    "SafetyLevel",
    "SafetyResult",
    "SafetyAuditLog",
    "SAFETY_CONFIG",
]


def __getattr__(name: str):
    if name in {"SafetyGuard", "SafetyLevel", "SafetyResult"}:
        from app.safety.guard import SafetyGuard, SafetyLevel, SafetyResult

        return {
            "SafetyGuard": SafetyGuard,
            "SafetyLevel": SafetyLevel,
            "SafetyResult": SafetyResult,
        }[name]
    if name == "SafetyAuditLog":
        from app.safety.audit import SafetyAuditLog

        return SafetyAuditLog
    if name == "SAFETY_CONFIG":
        from app.safety.config import SAFETY_CONFIG

        return SAFETY_CONFIG
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
