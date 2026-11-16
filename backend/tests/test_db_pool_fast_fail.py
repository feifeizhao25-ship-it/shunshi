"""A saturated database pool fails fast, and one caller cannot queue forever."""

import asyncio
import time

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy.exc import TimeoutError as PoolTimeout
from sqlalchemy.pool import QueuePool

from app.database.pool import postgres_pool_timeout
from app.db import make_engine
from app.errors import install_chinese_error_handlers
from app.middleware.user_concurrency import UserConcurrencyMiddleware


def test_postgres_engine_uses_a_short_pool_timeout(monkeypatch):
    monkeypatch.setenv("SHUNSHI_DB_POOL_TIMEOUT", "2")
    engine = make_engine("postgresql+psycopg://shunshi:fixture@127.0.0.1:1/shunshi")
    try:
        assert engine.pool.timeout() <= 2
        assert postgres_pool_timeout() <= 2
    finally:
        engine.dispose()


def test_file_sqlite_engine_does_not_keep_the_30s_pool_timeout(tmp_path, monkeypatch):
    monkeypatch.setenv("SHUNSHI_DB_POOL_TIMEOUT", "2")
    engine = make_engine(f"sqlite:///{tmp_path}/core.db")
    try:
        assert engine.pool.timeout() <= 2
    finally:
        engine.dispose()


def test_memory_sqlite_engine_still_builds():
    engine = make_engine("sqlite://")
    engine.dispose()


def test_queue_checkout_returns_before_the_old_30s_wait():
    from sqlalchemy import create_engine

    engine = create_engine(
        "sqlite://",
        poolclass=QueuePool,
        pool_size=1,
        max_overflow=0,
        pool_timeout=0.2,
        connect_args={"check_same_thread": False},
    )
    first = engine.connect()
    started = time.perf_counter()
    with pytest.raises(PoolTimeout):
        engine.connect()
    elapsed = time.perf_counter() - started
    first.close()
    engine.dispose()
    assert elapsed < 2


def test_pool_timeout_is_a_503(client):
    assert PoolTimeout in client.app.exception_handlers


def test_pool_timeout_handler_body():
    app = FastAPI()
    install_chinese_error_handlers(app)

    @app.get("/blocked")
    def blocked():
        raise PoolTimeout("pool")

    from fastapi.testclient import TestClient

    with TestClient(app) as test_client:
        response = test_client.get("/blocked")
    assert response.status_code == 503
    assert "繁忙" in response.json()["detail"]
    assert "pool" not in response.text


def test_one_caller_burst_is_rejected_immediately():
    app = FastAPI()
    app.add_middleware(UserConcurrencyMiddleware, limit=2)
    hold = asyncio.Event()
    entered = asyncio.Event()
    state = {"n": 0}

    @app.get("/slow")
    async def slow():
        state["n"] += 1
        if state["n"] >= 2:
            entered.set()
        await hold.wait()
        return {"ok": True}

    async def _run():
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            tasks = [asyncio.create_task(client.get("/slow", headers={"X-Real-IP": "203.0.113.50"})) for _ in range(5)]
            await asyncio.wait_for(entered.wait(), timeout=1)
            await asyncio.sleep(0.05)
            finished = [task for task in tasks if task.done()]
            assert finished, "excess requests should return without waiting for the slow ones"
            assert any(task.result().status_code == 429 for task in finished)
            started = time.perf_counter()
            hold.set()
            responses = await asyncio.gather(*tasks)
            assert time.perf_counter() - started < 2
        codes = sorted(response.status_code for response in responses)
        assert codes.count(429) == 3
        assert codes.count(200) == 2

    asyncio.run(_run())
