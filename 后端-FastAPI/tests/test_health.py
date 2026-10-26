"""健康检查 fail-closed：未配置 redis/模型网关时对应项 down，整体 503。"""

from app.routers import health as health_module


def test_health_fail_closed_when_dependencies_unconfigured(client):
    response = client.get("/api/health")
    assert response.status_code == 503
    body = response.json()
    assert body["status"] == "degraded"
    components = body["components"]
    assert components["database"]["status"] == "up"  # 测试库可达
    assert components["redis"] == {"configured": False, "status": "down"}
    assert components["model_gateway"] == {"configured": False, "status": "down"}


def test_health_configured_but_unreachable_is_down(settings):
    settings.redis_url = "redis://127.0.0.1:1/0"
    settings.model_router_url = "http://127.0.0.1:1"
    from fastapi.testclient import TestClient

    from app.main import create_app

    with TestClient(create_app(settings)) as client:
        response = client.get("/api/health")
    assert response.status_code == 503
    components = response.json()["components"]
    assert components["redis"]["configured"] is True
    assert components["redis"]["status"] == "down"
    assert components["model_gateway"]["configured"] is True
    assert components["model_gateway"]["status"] == "down"


def test_health_ok_when_all_components_up(settings, monkeypatch):
    settings.redis_url = "redis://fake/0"
    settings.model_router_url = "http://fake-gateway"
    monkeypatch.setattr(health_module, "probe_redis", lambda url: True)
    monkeypatch.setattr(health_module, "probe_gateway", lambda url: True)
    from fastapi.testclient import TestClient

    from app.main import create_app

    with TestClient(create_app(settings)) as client:
        response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_liveness_is_always_ok(client):
    assert client.get("/healthz").status_code == 200
