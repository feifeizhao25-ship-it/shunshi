"""Failed password logins are limited per account and IP."""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.login_rate_limit import FAILURE_LIMIT, MemoryLoginStore, memory_store


def test_login_failures_then_429_and_success_clears_the_window(settings):
    memory_store.clear()
    email = f"limit-{uuid.uuid4().hex[:8]}@example.com"
    password = "Correct-horse-9"
    with TestClient(create_app(settings)) as client:
        assert client.post(
            "/api/v1/auth/register",
            json={"email": email, "password": password, "name": "测"},
        ).status_code == 200
        for _ in range(FAILURE_LIMIT):
            failed = client.post(
                "/api/v1/auth/login",
                json={"email": email, "password": "wrong-password"},
                headers={"X-Real-IP": "203.0.113.10"},
            )
            assert failed.status_code == 401
        blocked = client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": password},
            headers={"X-Real-IP": "203.0.113.10"},
        )
        assert blocked.status_code == 429
        assert blocked.headers.get("retry-after")

        other_ip = client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": password},
            headers={"X-Real-IP": "203.0.113.11"},
        )
        assert other_ip.status_code == 200

        # The successful login cleared only that IP. The first address stays locked.
        still_locked = client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": password},
            headers={"X-Real-IP": "203.0.113.10"},
        )
        assert still_locked.status_code == 429

        other_account = f"other-{uuid.uuid4().hex[:8]}@example.com"
        assert client.post(
            "/api/v1/auth/register",
            json={"email": other_account, "password": password, "name": "测"},
        ).status_code == 200
        assert client.post(
            "/api/v1/auth/login",
            json={"email": other_account, "password": password},
            headers={"X-Real-IP": "203.0.113.10"},
        ).status_code == 200


def test_login_limiter_uses_an_injected_store(settings):
    store = MemoryLoginStore()
    email = f"store-{uuid.uuid4().hex[:8]}@example.com"
    password = "Correct-horse-9"
    with TestClient(create_app(settings)) as client:
        assert client.post(
            "/api/v1/auth/register",
            json={"email": email, "password": password, "name": "测"},
        ).status_code == 200

        import app.services.login_rate_limit as limiter

        original = limiter._store

        def _forced(redis_url, explicit):
            del redis_url, explicit
            return store

        limiter._store = _forced
        try:
            for _ in range(FAILURE_LIMIT):
                assert client.post(
                    "/api/v1/auth/login",
                    json={"email": email, "password": "wrong-password"},
                    headers={"X-Real-IP": "198.51.100.8"},
                ).status_code == 401
            assert client.post(
                "/api/v1/auth/login",
                json={"email": email, "password": password},
                headers={"X-Real-IP": "198.51.100.8"},
            ).status_code == 429
        finally:
            limiter._store = original
    assert store.get(f"login_fail:email:{email}|198.51.100.8") == str(FAILURE_LIMIT)


def test_unreachable_redis_uses_memory():
    from app.services.login_rate_limit import record_login_failure

    memory_store.clear()
    record_login_failure("email:fallback@example.com", "203.0.113.9", redis_url="redis://127.0.0.1:1/0")
    assert memory_store.get("login_fail:email:fallback@example.com|203.0.113.9") == "1"


def test_fakeredis_store_counts_failures():
    fakeredis = pytest.importorskip("fakeredis")
    from app.services.login_rate_limit import record_login_failure, assert_login_allowed

    client = fakeredis.FakeRedis(decode_responses=True)
    account = "email:fake@example.com"
    for _ in range(FAILURE_LIMIT):
        record_login_failure(account, "203.0.113.20", store=client)
    with pytest.raises(Exception) as caught:
        assert_login_allowed(account, "203.0.113.20", store=client)
    assert getattr(caught.value, "status_code", None) == 429
