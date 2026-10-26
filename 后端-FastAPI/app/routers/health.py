"""健康检查：fail-closed。任一组件未配置/不可达 → 该项 down，整体 503。"""

import httpx
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from ..db import ping as db_ping

router = APIRouter()


def probe_redis(redis_url: str) -> bool:
    """真实 PING；redis 库不可用时按 down 处理，不假报。"""
    try:
        import redis
    except ImportError:
        return False
    try:
        return bool(redis.Redis.from_url(redis_url, socket_timeout=2).ping())
    except Exception:
        return False


def probe_gateway(model_router_url: str) -> bool:
    """轻量探测网关 /health；超时或非 2xx 记 down。"""
    try:
        response = httpx.get(f"{model_router_url.rstrip('/')}/health", timeout=2.0)
        return response.status_code < 500
    except Exception:
        return False


@router.get("/api/health")
def health(request: Request):
    settings = request.app.state.settings
    engine = request.app.state.engine

    components = {
        "database": {"configured": True, "status": "up" if db_ping(engine) else "down"},
        "redis": {
            "configured": bool(settings.redis_url),
            "status": "down",
        },
        "model_gateway": {
            "configured": bool(settings.model_router_url),
            "status": "down",
        },
    }
    if settings.redis_url:
        components["redis"]["status"] = "up" if probe_redis(settings.redis_url) else "down"
    if settings.model_router_url:
        components["model_gateway"]["status"] = (
            "up" if probe_gateway(settings.model_router_url) else "down"
        )

    healthy = all(item["status"] == "up" for item in components.values())
    body = {
        "status": "ok" if healthy else "degraded",
        "service": "shunshi-api",
        "components": components,
    }
    return JSONResponse(body, status_code=200 if healthy else 503)


@router.get("/healthz")
def liveness():
    """进程级存活探针（compose/K8s liveness 用，不做深度检查）。"""
    return {"status": "ok", "service": "shunshi-api"}
