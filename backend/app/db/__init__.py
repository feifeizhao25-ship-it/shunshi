"""Database package boundary.

The repository also contains a legacy ``app/db.py`` module.  Making this
directory an explicit package prevents that file from shadowing the ORM
database and model modules used by the full production routers, while keeping
the lightweight application factory API available to ``app.main``.
"""

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.simple_models import Base


def make_engine(database_url: str) -> Engine:
    from app.db.url import normalize_database_url

    # postgresql:// 与 postgresql+psycopg2:// 都会选到没安装的 psycopg2，统一到 psycopg（3）。
    database_url = normalize_database_url(database_url)
    connect_args = {"check_same_thread": False} if database_url.startswith("sqlite") else {}
    kwargs = {"connect_args": connect_args, "pool_pre_ping": True}
    # QueuePool's default wait is 30s (pool_size defaults to 5). Fail fast instead.
    if not database_url.startswith("sqlite"):
        from app.database.pool import postgres_pool_timeout

        kwargs["pool_timeout"] = postgres_pool_timeout()
    return create_engine(database_url, **kwargs)


def make_session_factory(engine: Engine) -> sessionmaker[Session]:
    return sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def init_db(engine: Engine) -> None:
    from app import growth as _growth_models  # noqa: F401  注册增长表

    Base.metadata.create_all(engine)


def ping(engine: Engine) -> bool:
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


__all__ = ["init_db", "make_engine", "make_session_factory", "ping"]
