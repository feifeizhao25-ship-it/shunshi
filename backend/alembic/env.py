"""
Alembic env.py — 顺时后端数据库迁移
运行时从环境变量 DATABASE_URL 读取数据库连接。
"""
import os
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

# 确保项目根目录在 sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Alembic Config 对象
config = context.config

# 设置日志
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 覆盖 sqlalchemy.url（优先使用环境变量）
database_url = os.getenv("DATABASE_URL")
if database_url:
    config.set_main_option("sqlalchemy.url", database_url)

# 导入 Base.metadata — 用于 autogenerate 支持
from app.models.base import Base  # noqa: E402

# 强制导入所有模型以注册到 metadata
# 通过导入各子模块确保所有表注册到 Base.metadata
import app.models  # noqa: F401
import app.models.tea  # noqa: F401
import app.models.journal  # noqa: F401
import app.models.wellness_tracking  # noqa: F401
import app.models.exercise  # noqa: F401
import app.models.acupoint as _acupoint  # noqa: F401
import app.models.audio as _audio  # noqa: F401
import app.models.recipe as _recipe  # noqa: F401
import app.models.membership as _membership  # noqa: F401
import app.models.gamification as _gamification  # noqa: F401
import app.models.article as _article  # noqa: F401
import app.models.reminder as _reminder  # noqa: F401

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (generate SQL without connecting)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (connect to database)."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
