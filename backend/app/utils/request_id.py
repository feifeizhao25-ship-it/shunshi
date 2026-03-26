"""
request_id 工具 — 基于 contextvars 的请求级链路追踪标识
"""
from contextvars import ContextVar

# 使用 contextvars 存储当前请求的 request_id
_current_request_id: ContextVar[str] = ContextVar("request_id", default="")


def get_request_id() -> str:
    """获取当前请求的 request_id"""
    return _current_request_id.get() or "unknown"


def set_request_id(rid: str) -> None:
    """设置当前请求的 request_id"""
    _current_request_id.set(rid)
