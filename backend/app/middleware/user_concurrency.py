"""Cap in-flight HTTP requests per caller so one burst cannot sit on the DB pool.

The core engine's queue waits pool_timeout seconds (historically the 30s
default) once every connection is checked out. Extra requests from the same
account or address are rejected immediately with 429 instead.
"""

from __future__ import annotations

import hashlib
import os
import threading

from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Receive, Scope, Send


def max_inflight_per_user() -> int:
    # Above the parallel SMS guesses the login tests already send (20), and
    # well under a 100-request burst. Combined with the short pool timeout,
    # extras return 429/503 instead of waiting out the old 30s checkout.
    raw = os.getenv("SHUNSHI_MAX_INFLIGHT_PER_USER", "24")
    try:
        value = int(raw)
    except ValueError:
        return 24
    return value if value > 0 else 24


def _caller_key(scope: Scope) -> str:
    headers = {
        name.decode("latin-1").lower(): value.decode("latin-1")
        for name, value in scope.get("headers") or ()
    }
    authorization = headers.get("authorization", "")
    if authorization.lower().startswith("bearer "):
        token = authorization[7:].strip()
        if token:
            digest = hashlib.sha256(token.encode()).hexdigest()[:24]
            return f"tok:{digest}"
    real_ip = headers.get("x-real-ip", "").strip()
    if real_ip:
        return f"ip:{real_ip}"
    client = scope.get("client")
    host = client[0] if client else "unknown"
    return f"ip:{host}"


class InflightGate:
    def __init__(self, limit: int) -> None:
        self.limit = limit
        self._lock = threading.Lock()
        self._counts: dict[str, int] = {}

    def acquire(self, key: str) -> bool:
        with self._lock:
            current = self._counts.get(key, 0)
            if current >= self.limit:
                return False
            self._counts[key] = current + 1
            return True

    def release(self, key: str) -> None:
        with self._lock:
            current = self._counts.get(key, 0) - 1
            if current <= 0:
                self._counts.pop(key, None)
            else:
                self._counts[key] = current


class UserConcurrencyMiddleware:
    """Reject a caller's excess in-flight requests before they touch the database."""

    def __init__(self, app: ASGIApp, limit: int | None = None) -> None:
        self.app = app
        self.gate = InflightGate(max_inflight_per_user() if limit is None else limit)

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        path = scope.get("path") or ""
        if path == "/health" or path.startswith(("/health", "/metrics", "/docs", "/openapi", "/api/health")):
            await self.app(scope, receive, send)
            return
        key = _caller_key(scope)
        if not self.gate.acquire(key):
            response = JSONResponse(
                status_code=429,
                content={"detail": "请求过于密集，请稍后再试"},
                headers={"Retry-After": "1"},
            )
            await response(scope, receive, send)
            return
        try:
            await self.app(scope, receive, send)
        finally:
            self.gate.release(key)
