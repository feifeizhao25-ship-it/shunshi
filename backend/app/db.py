"""数据库连接：SQLite / PostgreSQL 双兼容，启动时建表（对齐见己 init_db 惯例）。"""

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from .database.pool import postgres_pool_timeout
from .simple_models import Base


def make_engine(database_url: str) -> Engine:
    connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
    kwargs = {"connect_args": connect_args, "pool_pre_ping": True}
    # SQLite uses a non-queue pool. PostgreSQL otherwise waits the 30s default
    # once pool_size (5) and max_overflow are checked out.
    if not database_url.startswith("sqlite"):
        kwargs["pool_timeout"] = postgres_pool_timeout()
    return create_engine(database_url, **kwargs)


def make_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db(engine: Engine) -> None:
    """启动建表；后续结构演进再引入 alembic。"""
    Base.metadata.create_all(engine)


def ping(engine: Engine) -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False
