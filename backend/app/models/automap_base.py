"""Auto-generate SQLAlchemy models from existing PostgreSQL tables."""
from __future__ import annotations

from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from app.db.database import engine, Session as ScopedSession

Base = automap_base()


def init_automap():
    """Reflect all tables from PostgreSQL into model classes."""
    Base.prepare(engine, reflect=True)
    return Base
