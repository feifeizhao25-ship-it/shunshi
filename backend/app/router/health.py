"""
顺时 ShunShi — 扩展健康检查 API
/api/v1/health

提供详细的健康状态，包括数据库、Redis、LLM 服务可用性。
"""
import os
import time
from datetime import datetime, timezone

from fastapi import APIRouter
from ..core.settings import settings

router = APIRouter(prefix="/api/v1/health", tags=["健康检查"])

_start_time = time.time()


@router.get("", summary="健康检查", description="返回服务基本状态、版本号和时间戳")
async def health_check():
    """基础健康检查"""
    return {
        "status": "healthy",
        "service": "shunshi-api",
        "version": "2.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/detailed", summary="详细健康检查", description="返回服务状态、数据库连接、Redis连接、LLM服务可用性等详细信息")
async def detailed_health_check():
    """详细健康检查（包含依赖项状态）"""
    checks = {
        "api": _check_api(),
        "database": _check_database(),
        "redis": _check_redis(),
        "llm": _check_llm(),
    }
    
    all_healthy = all(c["status"] == "healthy" for c in checks.values())
    
    return {
        "status": "healthy" if all_healthy else "degraded",
        "service": "shunshi-api",
        "version": "2.0.0",
        "uptime_seconds": int(time.time() - _start_time),
        "checks": checks,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/ready", summary="就绪探针", description="Kubernetes就绪探针，检查数据库是否可用")
async def readiness_check():
    """K8s 就绪探针"""
    db_ok = _check_database()["status"] == "healthy"
    return {
        "ready": db_ok,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/live", summary="存活探针", description="Kubernetes存活探针，返回服务是否存活")
async def liveness_check():
    """K8s 存活探针"""
    return {
        "alive": True,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def _check_api():
    """检查 API 自身状态"""
    return {
        "status": "healthy",
        "message": "API 运行正常",
    }


def _check_database():
    """检查数据库连接"""
    try:
        from app.database.db import get_db
        db = get_db()
        db.execute("SELECT 1")
        return {
            "status": "healthy",
            "message": "数据库连接正常",
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "message": f"数据库连接失败: {str(e)}",
        }


def _check_redis():
    """检查 Redis 连接"""
    try:
        import redis
        redis_url = settings.REDIS_URL
        r = redis.from_url(redis_url, socket_connect_timeout=2)
        r.ping()
        return {
            "status": "healthy",
            "message": "Redis 连接正常",
        }
    except Exception as e:
        return {
            "status": "unhealthy" if settings.APP_ENV == "production" else "degraded",
            "message": f"Redis 连接失败: {str(e)}",
        }


def _check_llm():
    """检查 LLM 服务可用性"""
    api_key = settings.SILICONFLOW_API_KEY or settings.DEEPSEEK_API_KEY or os.getenv("SILICONFLOW_API_KEY") or os.getenv("DEEPSEEK_API_KEY")
    if not api_key:
        return {
            "status": "degraded",
            "message": "LLM API Key 未配置",
        }
    
    return {
        "status": "healthy",
        "message": "LLM 配置正常",
    }
