"""
链路追踪中间件 — 为每个 HTTP 请求生成 request_id，注入 contextvars，
并在响应头中返回 X-Request-ID 和 X-Latency-Ms。
"""
import uuid
import time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.utils.request_id import set_request_id


class RequestTracingMiddleware(BaseHTTPMiddleware):
    """为每个请求生成 request_id，记录开始时间"""

    async def dispatch(self, request: Request, call_next) -> Response:
        # 生成 request_id (8字符短UUID，便于日志查看)
        request_id = str(uuid.uuid4())[:8]
        start_time = time.perf_counter()

        # 注入到请求 state (供路由依赖注入使用)
        request.state.request_id = request_id

        # 注入到 contextvars (供日志格式化器和业务代码使用)
        set_request_id(request_id)

        # 执行下游中间件 / 路由
        response = await call_next(request)

        # 计算耗时 (perf_counter 精度更高)
        latency_ms = int((time.perf_counter() - start_time) * 1000)

        # 添加响应头
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Latency-Ms"] = str(latency_ms)

        return response
