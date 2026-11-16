"""Failed-login limit keyed by account and client IP.

Uses Redis when a URL is reachable. Otherwise an in-memory counter enforces
the same window, which is what tests and a single process use. Pass any
client with get/incr/expire/ttl/delete (including fakeredis) as ``store``.
"""

from __future__ import annotations

import threading
import time

from fastapi import HTTPException, Request

FAILURE_LIMIT = 8
WINDOW_SECONDS = 15 * 60
_RETRY_DETAIL = "登录失败次数过多，请稍后再试"


class MemoryLoginStore:
    """Fixed-window counter with the Redis methods this limiter calls."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._values: dict[str, tuple[int, float]] = {}

    def get(self, key: str):
        with self._lock:
            item = self._values.get(key)
            if item is None or item[1] <= time.time():
                return None
            return str(item[0])

    def incr(self, key: str) -> int:
        with self._lock:
            now = time.time()
            count, expires = self._values.get(key, (0, 0.0))
            if expires <= now:
                count = 0
                # Keep the new window valid before the matching expire() call.
                expires = now + WINDOW_SECONDS
            count += 1
            self._values[key] = (count, expires)
            return count

    def expire(self, key: str, seconds: int) -> bool:
        with self._lock:
            count, expires = self._values.get(key, (0, 0.0))
            if expires <= time.time():
                expires = time.time() + seconds
            self._values[key] = (count, expires)
            return True

    def ttl(self, key: str) -> int:
        with self._lock:
            item = self._values.get(key)
            if item is None:
                return -2
            remaining = int(item[1] - time.time())
            return remaining if remaining > 0 else -2

    def delete(self, key: str) -> int:
        with self._lock:
            return 1 if self._values.pop(key, None) is not None else 0

    def clear(self) -> None:
        with self._lock:
            self._values.clear()


memory_store = MemoryLoginStore()


def account_identity(email: str | None, phone: str | None) -> str:
    if email:
        return "email:" + email.strip().lower()
    return "phone:" + (phone or "").strip()


def client_ip(request: Request | None) -> str:
    """Trust the address nginx writes into X-Real-IP, otherwise the socket peer."""
    if request is None:
        return "unknown"
    real = (request.headers.get("x-real-ip") or "").strip()
    if real:
        return real
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


def _storage_key(account: str, ip: str) -> str:
    return f"login_fail:{account}|{ip}"


def _try_redis(redis_url: str):
    try:
        import redis
    except ImportError:
        return None
    try:
        client = redis.Redis.from_url(
            redis_url,
            socket_connect_timeout=0.3,
            socket_timeout=0.3,
            decode_responses=True,
        )
        client.ping()
        return client
    except Exception:
        return None


def _store(redis_url: str, store):
    if store is not None:
        return store
    if redis_url:
        client = _try_redis(redis_url)
        if client is not None:
            return client
    return memory_store


def _current(store, key: str) -> int:
    raw = store.get(key)
    if raw is None:
        return 0
    if isinstance(raw, bytes):
        raw = raw.decode()
    try:
        return int(raw)
    except (TypeError, ValueError):
        return 0


def _retry_after(store, key: str) -> int:
    try:
        ttl = int(store.ttl(key))
    except Exception:
        ttl = WINDOW_SECONDS
    if ttl < 1:
        return WINDOW_SECONDS
    return ttl


def assert_login_allowed(account: str, ip: str, *, redis_url: str = "", store=None) -> None:
    """Raise 429 once this account+IP pair has already failed too many times."""
    backend = _store(redis_url, store)
    key = _storage_key(account, ip)
    if _current(backend, key) >= FAILURE_LIMIT:
        retry = _retry_after(backend, key)
        raise HTTPException(
            status_code=429,
            detail=_RETRY_DETAIL,
            headers={"Retry-After": str(retry)},
        )


def record_login_failure(account: str, ip: str, *, redis_url: str = "", store=None) -> int:
    backend = _store(redis_url, store)
    key = _storage_key(account, ip)
    count = int(backend.incr(key))
    if count == 1:
        backend.expire(key, WINDOW_SECONDS)
    return count


def clear_login_failures(account: str, ip: str, *, redis_url: str = "", store=None) -> None:
    backend = _store(redis_url, store)
    backend.delete(_storage_key(account, ip))
