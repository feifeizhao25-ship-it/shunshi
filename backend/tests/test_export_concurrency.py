"""Data export must not sit on the 30s pool default or the 30s SQLite busy wait."""

import asyncio
import time

import httpx
from sqlalchemy import create_engine, text
from sqlalchemy.pool import QueuePool

from app.db.database import engine as product_engine
from app.services.account_erasure import export_product_store


def test_product_sqlite_pool_uses_the_short_timeout():
    # conftest loads the product engine as a file SQLite QueuePool.
    assert product_engine.dialect.name == "sqlite"
    assert product_engine.pool.timeout() <= 2


def test_product_export_does_not_checkout_a_second_connection(tmp_path, monkeypatch):
    url = f"sqlite:///{tmp_path}/product.db"
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=1,
        max_overflow=0,
        pool_timeout=30,
        connect_args={"check_same_thread": False},
    )
    with engine.begin() as connection:
        connection.execute(text('CREATE TABLE notes (id TEXT, user_id TEXT)'))
    monkeypatch.setattr("app.db.database.engine", engine)
    started = time.perf_counter()
    try:
        exported = export_product_store("nobody")
    finally:
        engine.dispose()
    elapsed = time.perf_counter() - started
    assert exported == {}
    assert elapsed < 3, f"product export waited {elapsed:.1f}s for a second connection"


def test_twenty_concurrent_exports_finish_quickly(settings):
    from app.db import init_db
    from app.main import create_app

    app = create_app(settings)
    init_db(app.state.engine)

    async def _run():
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test", timeout=8.0) as http:
            login = await http.post("/api/v1/auth/guest-login", json={})
            assert login.status_code == 200, login.text
            token = login.json().get("access_token") or login.json().get("data", {}).get("token")
            headers = {"Authorization": f"Bearer {token}"}
            started = time.perf_counter()

            async def one():
                began = time.perf_counter()
                response = await http.post("/api/v1/auth/data/export", headers=headers)
                return response.status_code, time.perf_counter() - began

            results = await asyncio.gather(*[one() for _ in range(20)])
            wall = time.perf_counter() - started
        return results, wall

    results, wall = asyncio.run(_run())
    assert wall < 8
    statuses = [status for status, _elapsed in results]
    assert 500 not in statuses
    assert set(statuses) <= {200, 429, 503}
    assert 200 in statuses
    slow = [elapsed for _status, elapsed in results if elapsed >= 5]
    assert not slow, f"export requests exceeded 5s: {list(zip(statuses, [round(e, 2) for _s, e in results]))}"
    for status, elapsed in results:
        assert elapsed < 5, f"status {status} took {elapsed:.2f}s"
