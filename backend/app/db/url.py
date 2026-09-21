"""数据库连接串的归一化与解析。

## 为什么要有这个文件

这套后端有两套 SQLAlchemy 模型，各自一个 engine：

- 核心模型（``app.simple_models``：users / messages / entitlements …）
  读 ``SHUNSHI_DATABASE_URL``（``app/config.py``，带前缀）；
- 产品模型（``app.models.*`` 与 ``app.db.database.Base``：体质、日记、社区 …）
  原来读**不带前缀**的 ``DATABASE_URL``，缺省值写死成
  ``postgresql://shunshi:shunshi2026@localhost:5432/shunshi``。

生产上这会同时踩三个坑：

1. compose 与 ``backend/.env.example`` 只给了 ``SHUNSHI_DATABASE_URL``，
   产品模型于是去连容器里的 localhost——那里没有数据库；
2. ``postgresql://`` 让 SQLAlchemy 选 psycopg2 驱动，而 requirements 装的是
   psycopg（3）。模块导入时就建 engine，所以**进程直接起不来**
   （``ModuleNotFoundError: No module named 'psycopg2'``）；
3. 即使手工把两个变量指到同一个库，两套模型都有 ``users`` 表而且列不同，
   产品模型建外键时报 ``DatatypeMismatch``，启动同样失败（已在真实 PostgreSQL 16 上复现）。

现在：
- 连接串一律归一化为 psycopg（3）驱动；
- 产品模型优先用显式的 ``SHUNSHI_PRODUCT_DATABASE_URL``（兼容旧名 ``DATABASE_URL``）；
  没给时复用 ``SHUNSHI_DATABASE_URL``，但放进独立的 PostgreSQL schema
  ``shunshi_product``，两套 ``users`` 互不相见；
- 生产环境一个都没给时拒绝启动；开发环境回落到本地 SQLite 文件。
"""

from __future__ import annotations

import os
from pathlib import Path

PRODUCT_SCHEMA = "shunshi_product"
_DEV_SQLITE = Path(__file__).resolve().parents[2] / "shunshi_product_dev.db"


def normalize_database_url(url: str) -> str:
    """把 PostgreSQL 连接串统一到已安装的 psycopg（3）驱动。"""
    url = url.strip()
    for prefix in ("postgres://", "postgresql://", "postgresql+psycopg2://"):
        if url.startswith(prefix):
            return "postgresql+psycopg://" + url[len(prefix):]
    return url


def is_postgres(url: str) -> bool:
    return url.startswith("postgresql")


def resolve_product_database(env: dict | None = None) -> tuple[str, str | None]:
    """返回 (连接串, schema)。schema 为 None 表示不需要单独的 schema。"""
    env = os.environ if env is None else env
    explicit = env.get("SHUNSHI_PRODUCT_DATABASE_URL") or env.get("DATABASE_URL")
    if explicit:
        return normalize_database_url(explicit), None
    core = env.get("SHUNSHI_DATABASE_URL", "").strip()
    if core and is_postgres(normalize_database_url(core)):
        return normalize_database_url(core), PRODUCT_SCHEMA
    if env.get("SHUNSHI_ENV") == "production" or env.get("APP_ENV") == "production":
        raise RuntimeError(
            "生产环境必须配置 PostgreSQL：SHUNSHI_DATABASE_URL"
            "（产品模型会放在其中的 shunshi_product schema），"
            "或显式的 SHUNSHI_PRODUCT_DATABASE_URL"
        )
    return f"sqlite:///{_DEV_SQLITE}", None
