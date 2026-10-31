"""统一的错误出口：国内版界面全中文。

历史上各模块的 ``HTTPException(detail=...)`` 有上百处英文文案（"Acupoint xxx not found"），
也有把 ``SHUNSHI_DEEPSEEK_API_KEY``、``Stripe`` 这类运维信息直接放进 detail 的；
FastAPI 自带的 404/405/422 与未捕获异常的 500 也是英文。客户端一般直接把 detail 显示给用户。
逐处改改不完、新模块还会再漏，所以在应用出口统一兜底：
- 没有中文的文案 → 按状态码换成中文通用提示；
- 有中文但带环境变量名、技术栈名、原始报错的 → 同样换掉；
- 原文一律记到日志，方便运维排查；
- 结构（状态码、dict 里的 configured 等其它键、422 的 loc/type）保持不变，客户端契约不受影响。
"""

from __future__ import annotations

import logging
import re
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger(__name__)

_CJK = re.compile(r"[一-鿿]")
_TECH = re.compile(
    r"\b[A-Z][A-Z0-9]*_[A-Z0-9_]{2,}\b|API[ _-]?KEY|Stripe|Redis|PostgreSQL|SQLite|SQLAlchemy|"
    r"DeepSeek|SiliconFlow|OpenRouter|Sentry|Supabase|Traceback|HTTP\s*\d{3}|Error:|Exception|"
    r"\b(?:400|401|403|404|429|500|502|503)\s+[A-Z][a-z]+",
    re.IGNORECASE,
)

GENERIC_BY_STATUS = {
    400: "请求内容有误，请检查后重试",
    401: "请先登录",
    403: "没有权限进行此操作",
    404: "没有找到相关内容",
    405: "不支持这种操作",
    409: "当前状态下无法完成此操作，请刷新后重试",
    413: "提交的内容太大",
    422: "填写的内容不正确，请检查后重试",
    429: "操作太频繁，请稍后再试",
}
SERVER_GENERIC = "服务暂时不可用，请稍后再试"

_VALIDATION_MSG = (
    ("missing", "缺少必填项"),
    ("date", "日期格式不正确，应为 年-月-日"),
    ("time", "时间格式不正确"),
    ("too_short", "内容太短"),
    ("too_long", "内容太长"),
    ("string_too", "长度不符合要求"),
    ("greater", "数值太小"),
    ("less", "数值太大"),
    ("literal", "选项不正确"),
    ("enum", "选项不正确"),
    ("json", "提交的数据格式不正确"),
    ("int", "需要填写整数"),
    ("float", "需要填写数字"),
    ("bool", "需要选择是或否"),
    ("string_pattern", "格式不正确"),
)


GENERIC_BY_STATUS_EN = {
    400: "The request looks wrong. Please check it and try again.",
    401: "Please sign in first.",
    403: "You don't have permission to do this.",
    404: "We couldn't find what you were looking for.",
    405: "That action isn't supported.",
    409: "This can't be done in the current state. Please refresh and try again.",
    413: "The content you submitted is too large.",
    422: "Some of the information isn't valid. Please check it and try again.",
    429: "Too many requests. Please try again shortly.",
}
SERVER_GENERIC_EN = "The service is unavailable right now. Please try again later."

_VALIDATION_MSG_EN = (
    ("missing", "This field is required"),
    ("date", "Invalid date; use YYYY-MM-DD"),
    ("time", "Invalid time"),
    ("too_short", "Too short"),
    ("too_long", "Too long"),
    ("string_too", "Length is not allowed"),
    ("greater", "Value is too small"),
    ("less", "Value is too large"),
    ("literal", "Invalid choice"),
    ("enum", "Invalid choice"),
    ("json", "Invalid data format"),
    ("int", "A whole number is required"),
    ("float", "A number is required"),
    ("bool", "Choose yes or no"),
    ("string_pattern", "Invalid format"),
)


def _is_global(request: Request) -> bool:
    """International edition requests (X-App-Market: global, or a non-Chinese Accept-Language)."""
    from app.locale_context import resolve_locale

    h = request.headers
    return resolve_locale(h.get("accept-language"), h.get("x-app-market"), h.get("x-region")).is_global


def _generic_en(status: int) -> str:
    return GENERIC_BY_STATUS_EN.get(status, SERVER_GENERIC_EN if status >= 500 else "The request couldn't be completed. Please try again later.")


_BARE_HTTP_PHRASES = {
    "not found", "method not allowed", "forbidden", "unauthorized", "bad request", "not authenticated",
    "internal server error", "conflict", "unprocessable entity", "too many requests", "payload too large",
}


def _needs_replacing_en(text: str) -> bool:
    return bool(_CJK.search(text)) or bool(_TECH.search(text)) or text.strip().rstrip(".").lower() in _BARE_HTTP_PHRASES


def _clean_en(value: Any, status: int) -> Any:
    """International edition: never show Chinese or operator text; keep plain English messages."""
    if isinstance(value, str):
        if _needs_replacing_en(value):
            logger.info("replaced a user-visible Chinese/technical error (status=%s): %s", status, value[:300])
            return _generic_en(status)
        return value
    if isinstance(value, dict):
        return {k: (_clean_en(v, status) if k in ("detail", "message", "msg", "error") else v) for k, v in value.items()}
    if isinstance(value, list):
        return [_clean_en(v, status) for v in value]
    return value


def _validation_message_en(error_type: str) -> str:
    for key, text in _VALIDATION_MSG_EN:
        if key in error_type:
            return text
    return "Invalid format"


def _generic(status: int) -> str:
    return GENERIC_BY_STATUS.get(status, SERVER_GENERIC if status >= 500 else "请求未能完成，请稍后再试")


def _needs_replacing(text: str) -> bool:
    return not _CJK.search(text) or bool(_TECH.search(text))


def _clean(value: Any, status: int) -> Any:
    if isinstance(value, str):
        if _needs_replacing(value):
            logger.info("替换用户可见的非中文/技术性报错(status=%s): %s", status, value[:300])
            return _generic(status)
        return value
    if isinstance(value, dict):
        return {k: (_clean(v, status) if k in ("detail", "message", "msg", "error") else v) for k, v in value.items()}
    if isinstance(value, list):
        return [_clean(v, status) for v in value]
    return value


def _validation_message(error_type: str) -> str:
    for key, text in _VALIDATION_MSG:
        if key in error_type:
            return text
    return "格式不正确"


def install_chinese_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        clean = _clean_en if _is_global(request) else _clean
        return JSONResponse(
            {"detail": clean(exc.detail, exc.status_code)},
            status_code=exc.status_code,
            headers=getattr(exc, "headers", None),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_handler(request: Request, exc: RequestValidationError):
        message = _validation_message_en if _is_global(request) else _validation_message
        items = [
            {"loc": list(err.get("loc", ())), "type": err.get("type", ""), "msg": message(err.get("type", ""))}
            for err in exc.errors()
        ]
        return JSONResponse({"detail": items}, status_code=422)

    @app.exception_handler(Exception)
    async def unhandled_handler(request: Request, exc: Exception):
        logger.exception("未处理的异常: %s %s", request.method, request.url.path)
        return JSONResponse({"detail": SERVER_GENERIC_EN if _is_global(request) else SERVER_GENERIC}, status_code=500)
