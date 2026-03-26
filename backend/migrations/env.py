"""
顺时 ShunShi - Alembic 迁移环境配置
开发环境: SQLite (aiosqlite)
生产环境: PostgreSQL (asyncpg)

使用方法:
  开发: alembic upgrade head
  生产: alembic -x url=postgresql+asyncpg://... upgrade head
"""
from logging.config import fileConfig
import asyncio
from sqlalchemy.ext.asyncio import async_engine_from_config, create_async_engine
from alembic import context

# 导入所有模型，确保 Base.metadata 包含所有表
from app.models import Base, __all_models__
from app.database.db import get_database_url

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Alembic autogenerate 目标
target_metadata = Base.metadata


def get_url() -> str:
    """获取数据库 URL，优先使用命令行 -x url 参数"""
    url = context.get_x_argument(as_dictionary=True).get("url")
    if url:
        return url
    return get_database_url()


def run_migrations_offline() -> None:
    """离线迁移模式 - 生成 SQL 脚本"""
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    """执行迁移"""
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """异步执行迁移"""
    url = get_url()
    connectable = create_async_engine(url, pool_pre_ping=True)
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    """在线迁移模式"""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
