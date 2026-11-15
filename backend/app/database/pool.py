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
