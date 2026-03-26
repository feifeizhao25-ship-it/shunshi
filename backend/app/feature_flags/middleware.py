"""
顺时 AI - Feature Flag 中间件
将 feature flags 注入到 request.state，供路由使用

作者: Claw 🦅
日期: 2026-03-18
"""

import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.feature_flags.store import flag_store

logger = logging.getLogger(__name__)


class FeatureFlagMiddleware(BaseHTTPMiddleware):
    """
    将 feature flags 注入到 request.state.flags
    路由中可通过 request.state.flags.is_enabled("key") 使用
    """

    async def dispatch(self, request: Request, call_next):
        request.state.flags = flag_store
        response = await call_next(request)
        return response


# 保持向后兼容的别名
feature_flag_middleware = FeatureFlagMiddleware
