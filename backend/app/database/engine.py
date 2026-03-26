"""
顺时 ShunShi - 数据库连接管理
支持开发环境 (SQLite) 和生产环境 (PostgreSQL)

使用方法:
  开发: DATABASE_URL 未设置或为空 → 使用 SQLite
  生产: DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
  Docker: DATABASE_URL=postgresql+asyncpg://shunshi:shunshi123@postgres:5432/shunshi
"""
import os
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse

from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

# ==================== 配置 ====================

# SQLite 默认路径
DB_DIR = Path(__file__).resolve().parent.parent.parent / "data"
DB_PATH = DB_DIR / "shunshi.db"

# 从环境变量获取数据库 URL
DATABASE_URL_ENV = os.getenv("DATABASE_URL", "")


def get_database_url() -> str:
    """获取同步数据库 URL"""
    if not DATABASE_URL_ENV:
        DB_DIR.mkdir(parents=True, exist_ok=True)
        return f"sqlite:///{DB_PATH}"
    return DATABASE_URL_ENV


def get_async_database_url() -> str:
    """获取异步数据库 URL"""
    url = DATABASE_URL_ENV
    if not url:
        DB_DIR.mkdir(parents=True, exist_ok=True)
        return f"sqlite+aiosqlite:///{DB_PATH}"
    # postgresql+psycopg2 → postgresql+asyncpg
    if url.startswith("postgresql+psycopg2://"):
        url = url.replace("postgresql+psycopg2://", "postgresql+asyncpg://")
    elif url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://")
    return url


def is_postgresql() -> bool:
    """检查是否使用 PostgreSQL"""
    return "postgres" in get_database_url()


def is_sqlite() -> bool:
    """检查是否使用 SQLite"""
    return not is_postgresql()


# ==================== 引擎 (延迟创建) ====================

_engine = None
_async_engine = None


def get_engine():
    """获取同步引擎 (延迟创建)"""
    global _engine
    if _engine is None:
        url = get_database_url()
        connect_args = {"check_same_thread": False} if "sqlite" in url else {}
        _engine = create_engine(url, echo=False, pool_pre_ping=True, connect_args=connect_args)

        # SQLite 启用 WAL 模式和外键
        if "sqlite" in url:
            @event.listens_for(_engine, "connect")
            def _set_sqlite_pragma(dbapi_connection, connection_record):
                cursor = dbapi_connection.cursor()
                cursor.execute("PRAGMA journal_mode=WAL")
                cursor.execute("PRAGMA foreign_keys=ON")
                cursor.close()
    return _engine


def get_async_engine():
    """获取异步引擎 (延迟创建)"""
    global _async_engine
    if _async_engine is None:
        _async_engine = create_async_engine(
            get_async_database_url(),
            echo=False,
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=10,
        )
    return _async_engine


def get_session_local():
    """获取同步 SessionLocal"""
    return sessionmaker(
        bind=get_engine(),
        class_=Session,
        expire_on_commit=False,
    )


def get_async_session_local():
    """获取异步 AsyncSessionLocal"""
    return async_sessionmaker(
        bind=get_async_engine(),
        class_=AsyncSession,
        expire_on_commit=False,
    )


# ==================== 依赖注入 ====================

def get_db() -> Session:
    """FastAPI 依赖: 获取同步数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_async_db() -> AsyncSession:
    """FastAPI 依赖: 获取异步数据库会话"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
