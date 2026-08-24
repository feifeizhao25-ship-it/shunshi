"""配置管理：全部走环境变量，未配置的关键项 fail-closed（见各 router）。"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="SHUNSHI_", env_file=".env", extra="ignore")

    env: str = "development"  # development / test / production
    # 数据库：缺省用本地 SQLite 便于开发；生产必须显式给 PostgreSQL DSN
    database_url: str = "sqlite:///./shunshi_dev.db"
    redis_url: str = ""  # 未配置 → /api/health 中 redis 项 down
    jwt_secret: str = ""  # 未配置 → 签发/校验 JWT 一律 503（fail-closed）
    jwt_ttl_seconds: int = 604800  # 7 天
    model_router_url: str = ""  # 模型网关基址，未配置 → /api/v1/chat* 503
    sms_provider_url: str = ""
    sms_provider_token: str = ""
    payment_callback_secret: str = ""  # 未配置 → 购买回调 503 configured:false
    content_source_url: str = ""  # 内容源（CMS/音频）基址，未配置 → /api/v1/contents* 等 503
    cors_origins: str = ""  # 逗号分隔

    def cors_origin_list(self) -> list[str]:
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]
