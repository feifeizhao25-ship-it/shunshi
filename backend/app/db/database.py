"""Database connection and session management."""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session
import os
from pathlib import Path

if os.environ.get("APP_ENV") == "testing":
    # 测试环境：确保 ORM 和原生 sqlite3 使用同一个数据库文件
    DB_PATH = Path(__file__).resolve().parent.parent.parent / "tests" / "test_shunshi.db"
    DATABASE_URL = f"sqlite:///{DB_PATH}"
    PRODUCT_SCHEMA = None
else:
    # 解析规则与原因见 app/db/url.py（原来这里写死了 localhost 与明文口令，
    # 且 postgresql:// 会选到没安装的 psycopg2，生产上导入即崩溃）。
    from app.db.url import resolve_product_database

    DATABASE_URL, PRODUCT_SCHEMA = resolve_product_database()

_engine_kwargs = {"pool_pre_ping": True, "echo": False}
if DATABASE_URL.startswith("postgresql"):
    _engine_kwargs.update(pool_size=10, max_overflow=20)
    if PRODUCT_SCHEMA:
        # 产品模型与核心模型都有 users 表（列不同），同库时必须分 schema。
        _engine_kwargs["connect_args"] = {"options": f"-csearch_path={PRODUCT_SCHEMA}"}
elif DATABASE_URL.startswith("sqlite"):
    _engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, **_engine_kwargs)

session_factory = sessionmaker(bind=engine)
Session = scoped_session(session_factory)

Base = declarative_base()


def get_db():
    """Get database session. Use as dependency in FastAPI."""
    db = Session()
    try:
        yield db
    finally:
        db.close()


def ensure_product_schema(bind=None):
    """PostgreSQL 上先建好产品模型专用的 schema（幂等）。"""
    bind = bind or engine
    if PRODUCT_SCHEMA and bind.dialect.name == "postgresql":
        from sqlalchemy import text

        with bind.begin() as connection:
            connection.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{PRODUCT_SCHEMA}"'))


def init_db():
    """Import all models to register them with Base."""
    ensure_product_schema()
    from app.models import user, solar_term, constitution, recipe, tea, acupoint
    from app.models import exercise, chat, journal, article, audio, membership, reminder
    from app.models import content, conversation, diary, family, followup
    from app.models import gamification, notification, onboarding, subscription
    from app.models import wearable, wellness_tracking, audit
    Base.metadata.create_all(bind=engine)
