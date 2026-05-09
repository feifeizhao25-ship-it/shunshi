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
else:
    DATABASE_URL = os.getenv(
        "DATABASE_URL",
        "postgresql://shunshi:shunshi2026@localhost:5432/shunshi"
    )

engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    echo=False,
)

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


def init_db():
    """Import all models to register them with Base."""
    from app.models import user, solar_term, constitution, recipe, tea, acupoint
    from app.models import exercise, chat, journal, article, audio, membership, reminder
    from app.models import content, conversation, diary, family, followup
    from app.models import gamification, notification, onboarding, subscription
    from app.models import wearable, wellness_tracking, audit
    Base.metadata.create_all(bind=engine)
