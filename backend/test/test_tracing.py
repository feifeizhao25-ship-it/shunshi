"""
链路追踪中间件测试
"""
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from app.middleware.tracing import RequestTracingMiddleware


@pytest.fixture
def app():
    """创建一个挂载了 tracing 中间件的测试 FastAPI app"""
    _app = FastAPI()
    _app.add_middleware(RequestTracingMiddleware)

    @_app.get("/ping")
    async def ping():
        return {"ok": True}

    @_app.get("/slow")
    async def slow():
        import asyncio
        await asyncio.sleep(0.01)  # 10ms 确保可测量延迟
        return {"ok": True}

    return _app


@pytest.fixture
def client(app):
    return TestClient(app)


def test_request_id_in_response_header(client):
    """每个响应都应包含 X-Request-ID 头"""
    resp = client.get("/ping")
    assert resp.status_code == 200
    assert "X-Request-ID" in resp.headers
    rid = resp.headers["X-Request-ID"]
    # 8字符短UUID
    assert len(rid) == 8


def test_request_id_unique(client):
    """不同请求的 request_id 应该不同"""
    ids = set()
    for _ in range(20):
        resp = client.get("/ping")
        ids.add(resp.headers["X-Request-ID"])
    assert len(ids) == 20, f"Expected 20 unique IDs, got {len(ids)}"


def test_latency_in_response_header(client):
    """响应应包含 X-Latency-Ms 头且为合理的整数值"""
    resp = client.get("/ping")
    assert "X-Latency-Ms" in resp.headers
    latency = int(resp.headers["X-Latency-Ms"])
    # 即使是 ping 也应该 >= 0
    assert latency >= 0


def test_latency_measured_accurately(client):
    """对于 /slow 端点，延迟应该 >= 10ms"""
    resp = client.get("/slow")
    assert resp.status_code == 200
    latency = int(resp.headers["X-Latency-Ms"])
    assert latency >= 10
