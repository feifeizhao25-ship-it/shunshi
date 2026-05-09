"""
顺时 AI 统一配置中心
使用 pydantic-settings 管理所有环境变量
"""
from pydantic_settings import BaseSettings
from typing import List, Optional


class Settings(BaseSettings):
    # === 应用 ===
    APP_NAME: str = "ShunShi AI"
    APP_ENV: str = "development"  # development / staging / production
    DEBUG: bool = False

    # === 安全 ===
    JWT_SECRET: str = ""
    JWT_SECRET_PREVIOUS: str = ""
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TTL: int = 3600  # 1小时
    JWT_REFRESH_TTL: int = 86400 * 30  # 30天

    # === 数据库 ===
    DATABASE_URL: str = "sqlite:///./shunshi.db"

    # === Redis ===
    REDIS_URL: str = "redis://localhost:6379/0"

    # === LLM ===
    SILICONFLOW_API_KEY: str = ""
    OPENAI_API_KEY: str = ""
    DEEPSEEK_API_KEY: str = ""
    DEFAULT_LLM_MODEL: str = "deepseek-chat"

    # === LLM配额 ===
    LLM_DAILY_FREE_LIMIT: int = 10
    LLM_DAILY_PAID_LIMIT: int = 100

    # === 支付 ===
    STRIPE_SECRET_KEY: str = ""
    STRIPE_WEBHOOK_SECRET: str = ""
    ALIPAY_PRIVATE_KEY: str = ""
    ALIPAY_APP_ID: str = ""

    # === 推送 ===
    FCM_SERVER_KEY: str = ""
    APNS_KEY_ID: str = ""

    # === CORS ===
    CORS_ALLOWED_ORIGINS: str = "https://shunshi.app"
    CORS_ALLOW_LOCALHOST: bool = False

    # === 限流 ===
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_AUTH_PER_MINUTE: int = 10
    RATE_LIMIT_CHAT_PER_MINUTE: int = 20
    RATE_LIMIT_AI_PER_DAY_FREE: int = 10
    RATE_LIMIT_AI_PER_DAY_PAID: int = 100

    # === 日志 ===
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # json / text

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"  # 忽略 .env 中未声明的变量


settings = Settings()
