"""
顺时 ShunShi — Sentry 错误追踪集成

使用方法:
    在 main.py 启动时调用 init_sentry()

环境变量:
    SENTRY_DSN — Sentry 项目 DSN
    SENTRY_ENVIRONMENT — 环境标签 (production/staging/development)
    SENTRY_RELEASE — 版本标签
"""
import os
import logging

logger = logging.getLogger(__name__)

_sentry_initialized = False


def init_sentry():
    """初始化 Sentry SDK"""
    global _sentry_initialized
    
    dsn = os.getenv("SENTRY_DSN")
    if not dsn:
        logger.info("[Sentry] SENTRY_DSN 未设置，跳过初始化")
        return
    
    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.starlette import StarletteIntegration
        from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
        
        sentry_sdk.init(
            dsn=dsn,
            environment=os.getenv("SENTRY_ENVIRONMENT", "production"),
            release=os.getenv("SENTRY_RELEASE", "shunshi@2.0.0"),
            traces_sample_rate=float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
            profiles_sample_rate=float(os.getenv("SENTRY_PROFILES_SAMPLE_RATE", "0.05")),
            integrations=[
                StarletteIntegration(transaction_style="endpoint"),
                FastApiIntegration(transaction_style="endpoint"),
                SqlalchemyIntegration(),
            ],
            before_send=before_send,
            ignore_errors=[
                "HTTPException",  # 4xx 错误通常不需要追踪
            ],
        )
        _sentry_initialized = True
        logger.info("[Sentry] 初始化成功")
        
    except ImportError:
        logger.warning("[Sentry] sentry-sdk 未安装，跳过初始化。pip install sentry-sdk[fastapi]")


def before_send(event, hint):
    """发送前过滤敏感信息"""
    # 移除请求体中的敏感字段
    if "request" in event and "data" in event["request"]:
        data = event["request"]["data"]
        if isinstance(data, dict):
            for key in ["password", "token", "secret", "api_key", "credit_card"]:
                if key in data:
                    data[key] = "[FILTERED]"
    
    # 移除用户数据中的敏感信息
    if "user" in event:
        user = event["user"]
        if "email" in user:
            user["email"] = user["email"].split("@")[0] + "@***"
    
    return event


def capture_message(message: str, level: str = "info"):
    """发送消息到 Sentry"""
    if _sentry_initialized:
        import sentry_sdk
        sentry_sdk.capture_message(message, level=level)


def capture_exception(error: Exception):
    """发送异常到 Sentry"""
    if _sentry_initialized:
        import sentry_sdk
        sentry_sdk.capture_exception(error)


def set_user_context(user_id: str, email: str = None, **kwargs):
    """设置用户上下文（用于追踪用户相关的错误）"""
    if _sentry_initialized:
        import sentry_sdk
        sentry_sdk.set_user({
            "id": user_id,
            "email": email,
            **kwargs,
        })
