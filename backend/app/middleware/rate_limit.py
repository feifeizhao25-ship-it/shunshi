"""
顺时 — 请求限流中间件

基于内存的滑动窗口限流（Sliding Window Rate Limiter）。
不依赖 Redis，适合单实例部署；多实例部署时可替换为 Redis 后端。

限流策略（可通过环境变量调整）：
  RATE_LIMIT_DEFAULT_RPM   — 普通接口，每分钟最多 N 次（默认 60）
  RATE_LIMIT_AI_RPM        — AI / LLM 接口，每分钟最多 N 次（默认 20）
  RATE_LIMIT_UPLOAD_RPM    — 上传接口，每分钟最多 N 次（默认 10）
  RATE_LIMIT_ENABLED       — 是否启用（默认 true）

识别客户端身份：
  优先使用 X-User-ID 请求头（已登录用户），
  其次使用 X-Forwarded-For / X-Real-IP，
  最后使用 client.host。

响应头：
  X-RateLimit-Limit     — 窗口内允许的最大请求数
  X-RateLimit-Remaining — 窗口内剩余次数
  X-RateLimit-Reset     — 窗口重置时间（Unix 时间戳）

限流时返回 429 Too Many Requests，并附带 Retry-After 头。
"""

import os
import time
import collections
import threading
from typing import Dict, Deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from ..core.settings import settings


# ─────────────────────────────────────────────────────────────────────────────
# 配置
# ─────────────────────────────────────────────────────────────────────────────

_ENABLED: bool = os.getenv("RATE_LIMIT_ENABLED", "true").lower() != "false"

# 每分钟限制（窗口大小固定为 60 秒）
_WINDOW_SECONDS = 60

_DEFAULT_RPM:  int = settings.RATE_LIMIT_PER_MINUTE
_AI_RPM:       int = settings.RATE_LIMIT_CHAT_PER_MINUTE
_AUTH_RPM:     int = settings.RATE_LIMIT_AUTH_PER_MINUTE
_UPLOAD_RPM:   int = int(os.getenv("RATE_LIMIT_UPLOAD_RPM",  "10"))

# 路径前缀 → 限流级别
_PATH_LIMITS: list[tuple[str, int]] = [
    # 认证类 — 最严格
    ("/api/v1/auth",                  _AUTH_RPM),
    # 上传类
    ("/api/v1/audio/upload",          _UPLOAD_RPM),
    ("/api/v1/multimodal/upload",     _UPLOAD_RPM),
    # AI / LLM 类
    ("/api/v1/chat",                  _AI_RPM),
    ("/api/v1/ai",                    _AI_RPM),
    ("/api/v1/rag/query",             _AI_RPM),
    ("/api/v1/first-insight",         _AI_RPM),
    ("/api/v1/seasons/chat",          _AI_RPM),
    ("/api/v1/speech",                _AI_RPM),
    # 默认
]

# 健康检查 / 指标端点不做限流
_BYPASS_PREFIXES: tuple[str, ...] = ("/health", "/metrics", "/docs", "/openapi")

# 用于周期性清理过期记录（内存保护）
_CLEANUP_INTERVAL_SECONDS = 300  # 每 5 分钟清理一次


# ─────────────────────────────────────────────────────────────────────────────
# 内存存储
# ─────────────────────────────────────────────────────────────────────────────

class _SlidingWindowCounter:
    """
    线程安全的滑动窗口计数器。
    每个 client_key 对应一个时间戳双端队列，超出窗口的时间戳自动丢弃。
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._requests: Dict[str, Deque[float]] = {}
        self._last_cleanup = time.monotonic()

    def check_and_record(self, client_key: str, limit: int, window: int) -> tuple[bool, int, float]:
        """
        检查是否超出限制并记录本次请求。

        返回：
            allowed   — True 表示允许，False 表示超出限制
            remaining — 窗口内剩余次数（allow 后）
            reset_at  — 窗口重置时间（Unix 时间戳）
        """
        now = time.monotonic()
        cutoff = now - window

        with self._lock:
            if client_key not in self._requests:
                self._requests[client_key] = collections.deque()

            dq = self._requests[client_key]

            # 清除过期时间戳
            while dq and dq[0] < cutoff:
                dq.popleft()

            count = len(dq)

            if count >= limit:
                # 超限：最早的时间戳 + window 即为重置时间
                reset_at = time.time() + (dq[0] - cutoff) if dq else time.time() + window
                return False, 0, reset_at

            # 未超限：记录本次请求
            dq.append(now)
            remaining = limit - len(dq)
            reset_at = time.time() + window
            return True, remaining, reset_at

    def cleanup(self) -> None:
        """清理长期无活动的 key，防止内存无限增长。"""
        now = time.monotonic()
        if now - self._last_cleanup < _CLEANUP_INTERVAL_SECONDS:
            return

        cutoff = now - _WINDOW_SECONDS
        with self._lock:
            stale_keys = [
                k for k, dq in self._requests.items()
                if not dq or dq[-1] < cutoff
            ]
            for k in stale_keys:
                del self._requests[k]
            self._last_cleanup = now


_counter = _SlidingWindowCounter()


# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _get_client_key(request: Request) -> str:
    """从请求中提取客户端唯一标识。"""
    # 已登录用户优先使用 user_id（同一用户多 IP 共享配额）
    user_id = request.headers.get("X-User-ID")
    if user_id:
        return f"user:{user_id}"

    # 代理转发的真实 IP
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        ip = forwarded_for.split(",")[0].strip()
        return f"ip:{ip}"

    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return f"ip:{real_ip}"

    # 直连 IP
    host = request.client.host if request.client else "unknown"
    return f"ip:{host}"


def _get_limit_for_path(path: str) -> int:
    """根据请求路径返回对应的限流值。"""
    for prefix, limit in _PATH_LIMITS:
        if path.startswith(prefix):
            return limit
    return _DEFAULT_RPM


def _should_bypass(path: str) -> bool:
    """判断路径是否跳过限流。"""
    return any(path.startswith(bp) for bp in _BYPASS_PREFIXES)


# ─────────────────────────────────────────────────────────────────────────────
# 中间件
# ─────────────────────────────────────────────────────────────────────────────

class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    滑动窗口限流中间件。
    在 main.py 中注册：
        app.add_middleware(RateLimitMiddleware)
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # 未启用或健康检查直接放行
        if not _ENABLED or _should_bypass(request.url.path):
            return await call_next(request)

        client_key = _get_client_key(request)
        limit = _get_limit_for_path(request.url.path)

        # 周期清理
        _counter.cleanup()

        allowed, remaining, reset_at = _counter.check_and_record(
            client_key, limit, _WINDOW_SECONDS
        )

        if not allowed:
            retry_after = max(1, int(reset_at - time.time()))
            return JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "error": "rate_limit_exceeded",
                    "message": "请求过于频繁，请稍后重试。",  # 中英双语
                    "message_en": "Too many requests, please slow down.",
                    "retry_after_seconds": retry_after,
                },
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(int(reset_at)),
                },
            )

        response = await call_next(request)

        # 在响应头中附加限流信息
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(int(reset_at))

        return response
