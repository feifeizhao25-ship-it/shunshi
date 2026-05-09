"""
API 版本管理中间件
- 当前版本 v1
- 废弃端点添加 Deprecation 响应头
- 未来 v2 版本的迁移支持
"""
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger(__name__)

CURRENT_API_VERSION = "v1"
DEPRECATED_PATHS = {
    # 未来废弃的端点放在这里
    # "/api/v1/old-endpoint": {"sunset": "2026-09-01", "replacement": "/api/v2/new-endpoint"},
}


class APIVersionMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)

        path = request.url.path

        # 检查是否是废弃路径
        if path in DEPRECATED_PATHS:
            info = DEPRECATED_PATHS[path]
            response.headers["Deprecation"] = "true"
            response.headers["Sunset"] = info.get("sunset", "")
            response.headers["Link"] = f'<{info.get("replacement", "")}>; rel="successor-version"'

        # 所有 API 响应添加当前版本头
        if path.startswith("/api/"):
            response.headers["X-API-Version"] = CURRENT_API_VERSION

        return response
