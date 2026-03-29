"""Auto-generate SQLAlchemy models from existing PostgreSQL tables."""
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from app.db.database import engine, Session as ScopedSession

Base = automap_base()


def init_automap():
    """Reflect all tables from PostgreSQL into model classes."""
    Base.prepare(engine, reflect=True)
    return Base


# Lazy initialization - models are created on first access
def get_models():
    """Get all reflected model classes."""
    return {
        name: cls 
        for name, cls in Base._classes.items()
    }
