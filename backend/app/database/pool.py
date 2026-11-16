"""Shared pool wait used by the request engines.

Kept separate from engine.py so importing the request engine does not pull in
the async driver.
"""

import os


def postgres_pool_timeout() -> float:
    """How long a request may wait for a pooled connection.

    The driver default is 30 seconds. A saturated pool then hangs callers
    instead of failing fast. Non-positive or non-numeric values fall back to 2s.
    """
    raw = os.getenv("SHUNSHI_DB_POOL_TIMEOUT", "2")
    try:
        value = float(raw)
    except ValueError:
        return 2.0
    return value if value > 0 else 2.0


def is_memory_sqlite(database_url: str) -> bool:
    """In-memory SQLite uses SingletonThreadPool, which rejects pool_timeout."""
    if not database_url.startswith("sqlite"):
        return False
    base = database_url.split("?", 1)[0]
    return base in {"sqlite://", "sqlite:///:memory:"} or base.endswith("/:memory:")


def queue_pool_timeout_kwargs(database_url: str) -> dict[str, float]:
    """Checkout wait for every QueuePool this process creates.

    PostgreSQL is always a QueuePool. File SQLite is one too (SQLAlchemy 2);
    leaving it unset keeps the 30s default and bypasses SHUNSHI_DB_POOL_TIMEOUT.
    The timeout value itself is unchanged.
    """
    if is_memory_sqlite(database_url):
        return {}
    return {"pool_timeout": postgres_pool_timeout()}
