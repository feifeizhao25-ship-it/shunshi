"""PostgreSQL database connection for new PRD tables."""
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, scoped_session
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://shunshi:shunshi2026@localhost:5432/shunshi"
)

engine = create_engine(DATABASE_URL, pool_size=5, max_overflow=10, pool_pre_ping=True)
_session_factory = sessionmaker(bind=engine)
_PgSession = scoped_session(_session_factory)

def get_pg_db():
    db = _PgSession()
    try:
        yield db
    finally:
        db.close()
