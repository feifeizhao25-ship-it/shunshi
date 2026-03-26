"""
顺时 - Prometheus Metrics 中间件
提供 HTTP 请求、LLM 调用、活跃用户等指标采集。

指标列表：
- http_requests_total: HTTP 请求总数 (counter, by method/path/status)
- http_request_duration_seconds: HTTP 请求延迟 (histogram)
- llm_requests_total: LLM 调用总数 (counter, by model)
- llm_request_duration_seconds: LLM 调用延迟 (histogram)
- active_users: 活跃用户数 (gauge)
- chat_messages_total: 聊天消息总数 (counter)
- subscriptions_active: 活跃订阅数 (gauge)

作者: Claw 🦅
日期: 2026-03-17
"""

import time
import logging
from typing import Callable

logger = logging.getLogger(__name__)

try:
    from prometheus_client import (
        Counter, Histogram, Gauge, generate_latest,
        CONTENT_TYPE_LATEST, REGISTRY,
    )
    _PROMETHEUS_AVAILABLE = True
except ImportError:
    _PROMETHEUS_AVAILABLE = False
    logger.warning("[Metrics] prometheus_client 未安装，指标采集将不工作。pip install prometheus_client")

if _PROMETHEUS_AVAILABLE:
    # ==================== HTTP 指标 ====================

    http_requests_total = Counter(
        "http_requests_total",
        "Total HTTP requests",
        ["method", "path", "status"],
    )

    http_request_duration_seconds = Histogram(
        "http_request_duration_seconds",
        "HTTP request duration in seconds",
        ["method", "path"],
        buckets=[0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 10.0],
    )

    # ==================== LLM 指标 ====================

    llm_requests_total = Counter(
        "llm_requests_total",
        "Total LLM API requests",
        ["model"],
    )

    llm_request_duration_seconds = Histogram(
        "llm_request_duration_seconds",
        "LLM request duration in seconds",
        ["model"],
        buckets=[0.5, 1.0, 2.0, 3.0, 5.0, 10.0, 15.0, 20.0, 30.0, 60.0],
    )

    # ==================== 业务指标 ====================

    active_users = Gauge(
        "active_users",
        "Number of active users",
    )

    chat_messages_total = Counter(
        "chat_messages_total",
        "Total chat messages sent",
    )

    subscriptions_active = Gauge(
        "subscriptions_active",
        "Number of active subscriptions",
    )
else:
    # Mock objects when prometheus_client is not available
    class _NoOp:
        def labels(self, *args, **kwargs): return self
        def inc(self, *args, **kwargs): pass
        def dec(self, *args, **kwargs): pass
        def observe(self, *args, **kwargs): pass
        def set(self, *args, **kwargs): pass
        def time(self, *args, **kwargs): return _NoOpContext()
        def __enter__(self): return self
        def __exit__(self, *args): pass

    class _NoOpContext:
        def __enter__(self): return self
        def __exit__(self, *args): pass

    http_requests_total = _NoOp()
    http_request_duration_seconds = _NoOp()
    llm_requests_total = _NoOp()
    llm_request_duration_seconds = _NoOp()
    active_users = _NoOp()
    chat_messages_total = _NoOp()
    subscriptions_active = _NoOp()


def get_metrics():
    """生成 Prometheus 格式的指标文本"""
    if not _PROMETHEUS_AVAILABLE:
        return "# prometheus_client not installed\n"
    return generate_latest(REGISTRY)


# ==================== 路径标准化 ====================

# 将动态路径标准化，避免 label explosion
_PATH_PREFIXES = [
    "/api/v1/contents/",
    "/api/v1/chat/",
    "/api/v1/memory/",
    "/api/v1/followup/",
    "/api/v1/subscription/",
    "/api/v1/solar-terms/",
    "/api/v1/family/",
    "/api/v1/notifications/",
    "/api/v1/records/",
    "/api/v1/settings/",
    "/api/v1/lifecycle/",
    "/api/v1/auth/",
]

def normalize_path(path: str) -> str:
    """将动态路径标准化"""
    for prefix in _PATH_PREFIXES:
        if path.startswith(prefix):
            return prefix.rstrip("/") + "/:id"
    # 静态路径列表
    if path in ("/", "/health", "/metrics", "/stats", "/models", "/prompts"):
        return path
    return "other"


# ==================== FastAPI 中间件 ====================

class MetricsMiddleware:
    """
    FastAPI 中间件：记录 HTTP 请求指标
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        method = scope["method"]
        path = scope["path"]
        normalized = normalize_path(path)

        start_time = time.time()

        # 捕获响应状态码
        status_code = 500

        async def send_wrapper(message):
            nonlocal status_code
            if message.get("type") == "http.response.start":
                status_code = message.get("status", 500)
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            duration = time.time() - start_time

            if _PROMETHEUS_AVAILABLE:
                http_requests_total.labels(
                    method=method,
                    path=normalized,
                    status=status_code,
                ).inc()

                http_request_duration_seconds.labels(
                    method=method,
                    path=normalized,
                ).observe(duration)


def track_llm_request(model: str, duration_seconds: float):
    """记录一次 LLM 调用"""
    if _PROMETHEUS_AVAILABLE:
        llm_requests_total.labels(model=model).inc()
        llm_request_duration_seconds.labels(model=model).observe(duration_seconds)
