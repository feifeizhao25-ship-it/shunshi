"""
顺时 — 限流中间件测试

注意：测试会临时修改内部计数器状态，使用 monkeypatch 隔离。
"""

import pytest
import time
from unittest.mock import patch
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.middleware.rate_limit import (
    RateLimitMiddleware,
    _get_client_key,
    _get_limit_for_path,
    _should_bypass,
    _SlidingWindowCounter,
)


# ─────────────────────────────────────────────────────────────────────────────
# 辅助：最小 FastAPI 应用（仅用于中间件测试）
# ─────────────────────────────────────────────────────────────────────────────

def _make_app(enabled: bool = True) -> tuple[FastAPI, TestClient]:
    app = FastAPI()

    @app.get("/api/v1/test")
    async def test_endpoint():
        return {"ok": True}

    @app.get("/api/v1/chat")
    async def chat_endpoint():
        return {"ok": True}

    @app.get("/health")
    async def health():
        return {"status": "ok"}

    with patch("app.middleware.rate_limit._ENABLED", enabled):
        app.add_middleware(RateLimitMiddleware)

    return app, TestClient(app, raise_server_exceptions=False)


# ─────────────────────────────────────────────────────────────────────────────
# 单元测试：辅助函数
# ─────────────────────────────────────────────────────────────────────────────

class TestHelperFunctions:
    def test_bypass_health(self):
        assert _should_bypass("/health") is True

    def test_bypass_metrics(self):
        assert _should_bypass("/metrics") is True

    def test_bypass_docs(self):
        assert _should_bypass("/docs") is True

    def test_no_bypass_api(self):
        assert _should_bypass("/api/v1/chat") is False

    def test_limit_ai_path(self):
        from app.middleware.rate_limit import _AI_RPM
        assert _get_limit_for_path("/api/v1/chat") == _AI_RPM

    def test_limit_default_path(self):
        from app.middleware.rate_limit import _DEFAULT_RPM
        assert _get_limit_for_path("/api/v1/solar-terms") == _DEFAULT_RPM

    def test_limit_upload_path(self):
        from app.middleware.rate_limit import _UPLOAD_RPM
        assert _get_limit_for_path("/api/v1/audio/upload") == _UPLOAD_RPM


# ─────────────────────────────────────────────────────────────────────────────
# 单元测试：滑动窗口计数器
# ─────────────────────────────────────────────────────────────────────────────

class TestSlidingWindowCounter:
    def setup_method(self):
        self.counter = _SlidingWindowCounter()

    def test_allows_within_limit(self):
        for _ in range(5):
            allowed, remaining, reset_at = self.counter.check_and_record(
                "user:test", limit=10, window=60
            )
            assert allowed is True

    def test_blocks_after_limit(self):
        limit = 3
        for _ in range(limit):
            allowed, _, _ = self.counter.check_and_record(
                "user:block_test", limit=limit, window=60
            )
            assert allowed is True

        allowed, remaining, _ = self.counter.check_and_record(
            "user:block_test", limit=limit, window=60
        )
        assert allowed is False
        assert remaining == 0

    def test_remaining_decreases(self):
        limit = 5
        for i in range(3):
            _, remaining, _ = self.counter.check_and_record(
                "user:remain_test", limit=limit, window=60
            )
        assert remaining == limit - 3

    def test_different_keys_independent(self):
        limit = 2
        for _ in range(limit):
            self.counter.check_and_record("user:a", limit=limit, window=60)

        # key a is now blocked
        allowed_a, _, _ = self.counter.check_and_record("user:a", limit=limit, window=60)
        assert allowed_a is False

        # key b should still be allowed
        allowed_b, _, _ = self.counter.check_and_record("user:b", limit=limit, window=60)
        assert allowed_b is True

    def test_reset_at_is_future(self):
        _, _, reset_at = self.counter.check_and_record(
            "user:reset_test", limit=10, window=60
        )
        assert reset_at > time.time()

    def test_cleanup_removes_stale(self):
        # Add a key, then simulate it becoming stale by manipulating timestamps
        self.counter.check_and_record("user:stale", limit=10, window=1)
        # Manually set the timestamp to be older than _WINDOW_SECONDS
        old_time = time.monotonic() - 61
        self.counter._requests["user:stale"][0] = old_time
        # Force cleanup: use a very old _last_cleanup so the interval check passes
        self.counter._last_cleanup = -9999
        self.counter.cleanup()
        assert "user:stale" not in self.counter._requests


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试：HTTP 中间件行为
# ─────────────────────────────────────────────────────────────────────────────

class TestRateLimitMiddleware:
    def test_health_bypass(self):
        _, client = _make_app(enabled=True)
        resp = client.get("/health")
        # Health is bypassed — no rate limit headers
        assert resp.status_code == 200
        assert "X-RateLimit-Limit" not in resp.headers

    def test_normal_request_passes(self):
        _, client = _make_app(enabled=True)
        resp = client.get("/api/v1/test")
        assert resp.status_code == 200

    def test_rate_limit_headers_present(self):
        _, client = _make_app(enabled=True)
        resp = client.get("/api/v1/test")
        assert "X-RateLimit-Limit" in resp.headers
        assert "X-RateLimit-Remaining" in resp.headers
        assert "X-RateLimit-Reset" in resp.headers

    def test_limit_value_in_header(self):
        from app.middleware.rate_limit import _DEFAULT_RPM
        _, client = _make_app(enabled=True)
        resp = client.get("/api/v1/test")
        assert int(resp.headers["X-RateLimit-Limit"]) == _DEFAULT_RPM

    def test_middleware_disabled(self):
        # Patch must remain active during request because Starlette
        # lazily instantiates middleware on first request.
        with patch("app.middleware.rate_limit._ENABLED", False):
            _, client = _make_app(enabled=False)
            resp = client.get("/api/v1/test")
        assert resp.status_code == 200
        # No rate limit headers when disabled
        assert "X-RateLimit-Limit" not in resp.headers

    def test_429_when_limit_exceeded(self):
        from app.middleware.rate_limit import _DEFAULT_RPM, _counter
        # Use a unique key to avoid cross-test interference
        unique_header = {"X-User-ID": f"test-over-limit-{time.time()}"}

        with patch("app.middleware.rate_limit._DEFAULT_RPM", 3):
            app = FastAPI()

            @app.get("/api/v1/test")
            async def ep():
                return {"ok": True}

            app.add_middleware(RateLimitMiddleware)
            client = TestClient(app, raise_server_exceptions=False)

            for _ in range(3):
                r = client.get("/api/v1/test", headers=unique_header)
                assert r.status_code == 200

            r = client.get("/api/v1/test", headers=unique_header)
            assert r.status_code == 429

    def test_429_response_body(self):
        from app.middleware.rate_limit import _DEFAULT_RPM
        unique_id = f"body-test-{time.time()}"
        headers = {"X-User-ID": unique_id}

        with patch("app.middleware.rate_limit._DEFAULT_RPM", 1):
            app = FastAPI()

            @app.get("/api/v1/test")
            async def ep():
                return {"ok": True}

            app.add_middleware(RateLimitMiddleware)
            client = TestClient(app, raise_server_exceptions=False)

            client.get("/api/v1/test", headers=headers)
            r = client.get("/api/v1/test", headers=headers)

            assert r.status_code == 429
            body = r.json()
            assert body["error"] == "rate_limit_exceeded"
            assert "retry_after_seconds" in body
            assert "Retry-After" in r.headers

    def test_user_id_header_used_as_key(self):
        """同一 User-ID 共享配额，不同 User-ID 独立计数"""
        with patch("app.middleware.rate_limit._DEFAULT_RPM", 2):
            app = FastAPI()

            @app.get("/api/v1/test")
            async def ep():
                return {"ok": True}

            app.add_middleware(RateLimitMiddleware)
            client = TestClient(app, raise_server_exceptions=False)

            uid_a = f"user-a-{time.time()}"
            uid_b = f"user-b-{time.time()}"

            # Exhaust user-a's limit
            client.get("/api/v1/test", headers={"X-User-ID": uid_a})
            client.get("/api/v1/test", headers={"X-User-ID": uid_a})
            r_a = client.get("/api/v1/test", headers={"X-User-ID": uid_a})
            assert r_a.status_code == 429

            # user-b should still be allowed
            r_b = client.get("/api/v1/test", headers={"X-User-ID": uid_b})
            assert r_b.status_code == 200
