"""产品路由的统一门禁：默认要登录、只能动自己的数据、运营接口只给管理员。

## 为什么要有这个文件

``app/router/`` 下约 120 个模块由 ``main._include_product_routers`` 自动挂载。
2026-09-21 在按测试配置拉起的后端上，把**每一条**路由都不带 token 调了一遍：
370 条返回 200，另有 209 条返回 422（校验了参数、却没校验身份）。其中包括：

- ``GET /api/v1/users/{user_id}/export`` —— 不登录就能导出任意用户的资料；
- ``GET /api/v1/admin/dashboard`` 等整个 ``/api/v1/admin/*`` —— 后台统计、模型配置、
  LLM 调用记录；
- ``POST /api/v1/notifications/broadcast`` —— 任何人都能以「顺时」的名义给全体用户推送；
- ``POST /api/v1/coupon/issue``、``/gamification/award``、``/gifting/gift-cards/create``
  —— 任何人给任何人发券、发徽章、造礼品卡；
- ``/api/v1/family/*`` 等大量接口用 ``user_id: str = "user-001"`` 当身份：
  不传就落到演示账号上（于是**所有真实用户共用一份家庭数据**），传别人的 id 就读写别人的。

逐个模块补鉴权要改上百个文件，且下一个新模块照旧会漏。所以在挂载处加一道门：

1. **公开**：登录注册（``/api/v1/auth/*``）、管理员登录、支付回调（验签在处理函数里做）。
2. **仅管理员**（``X-Admin-Token``，即管理后台登录后拿到的令牌）：见 ``ADMIN_ONLY``。
3. **要登录**：所有写操作；以及参数里带 ``user_id`` 的读操作。
   - 路径、查询串、JSON 请求体里的 ``user_id`` 必须等于 token 里的本人，否则 403；
   - 没传 ``user_id`` 的，替它填上本人——不再落到演示账号 ``user-001`` 上。
4. 其余不带用户标识的 GET（节气、食谱、穴位等公共内容）保持公开。

管理后台带着管理员令牌访问任何产品路由都放行（它要读列表、审内容）。

这道门不替代各模块自己的校验，只保证「没有校验」时默认是关着的。
"""

from __future__ import annotations

import re
from typing import Any, Iterable

from fastapi import HTTPException, Request

USER_KEYS = ("user_id", "userId")
SAFE_METHODS = frozenset({"GET", "HEAD", "OPTIONS"})

# 不需要任何身份的前缀。
PUBLIC_PREFIXES: tuple[str, ...] = (
    "/api/v1/auth/",
    "/api/v1/admin/auth/",
    # 支付平台的异步通知：身份由处理函数验签确定，不可能带用户 token。
    "/api/v1/payments/alipay/notify",
    "/api/v1/payments/wechat/notify",
)

# 仅管理员。(方法集合或 None=全部方法, 路径正则)
ADMIN_ONLY: tuple[tuple[frozenset[str] | None, re.Pattern[str]], ...] = tuple(
    (methods, re.compile(pattern))
    for methods, pattern in (
        (None, r"^/api/v1/admin/"),
        (None, r"^/api/v1/cms/"),
        (None, r"^/api/v1/audit(/|$)"),
        (None, r"^/api/v1/feedback/admin/"),
        (None, r"^/api/v1/notifications/(broadcast|send|send-to-user|push/batch|followup-due)$"),
        (None, r"^/api/v1/notifications/scheduler/"),
        (None, r"^/api/v1/coupon/issue$"),
        (None, r"^/api/v1/gamification/award$"),
        (None, r"^/api/v1/gifting/gift-cards/create$"),
        (None, r"^/api/v1/expert-qa/questions/[^/]+/answer$"),
        (None, r"^/api/v1/push-intel/ab-test$"),
        (None, r"^/api/v1/ai-content/(generate|batch-generate)$"),
        (None, r"^/api/v1/subscription/(check-expired|check-expiry|usage/record)$"),
        # 列出的是**所有用户**的到期随访任务
        (None, r"^/api/v1/followup/(due|check)$"),
        (None, r"^/api/v1/analytics/app-stats$"),
        (frozenset({"POST", "PUT", "PATCH", "DELETE"}), r"^/api/v1/banner(/|$)"),
    )
)


def is_public(path: str) -> bool:
    return path.startswith(PUBLIC_PREFIXES)


def is_admin_only(method: str, path: str) -> bool:
    return any(
        (methods is None or method in methods) and pattern.search(path)
        for methods, pattern in ADMIN_ONLY
    )


def _bearer(request: Request) -> str:
    header = request.headers.get("authorization") or ""
    scheme, _, token = header.partition(" ")
    return token.strip() if scheme.lower() == "bearer" else ""


def _is_admin(request: Request) -> bool:
    from .router.admin_auth import _verify_token

    candidates = [request.headers.get("x-admin-token") or "", _bearer(request)]
    return any(token and _verify_token(token) for token in candidates)


def _body_model_fields(route: Any) -> set[str]:
    fields: set[str] = set()
    dependant = getattr(route, "dependant", None)
    for param in getattr(dependant, "body_params", None) or []:
        annotation = getattr(getattr(param, "field_info", None), "annotation", None)
        annotation = annotation or getattr(param, "type_", None)
        model_fields = getattr(annotation, "model_fields", None)
        if isinstance(model_fields, dict):
            fields.update(model_fields)
        else:
            fields.add(getattr(param, "alias", None) or getattr(param, "name", ""))
    return fields


def _param_names(route: Any, kind: str) -> set[str]:
    dependant = getattr(route, "dependant", None)
    names: set[str] = set()
    stack = [dependant] if dependant is not None else []
    while stack:
        current = stack.pop()
        for param in getattr(current, kind, None) or []:
            names.add(getattr(param, "alias", None) or param.name)
        stack.extend(getattr(current, "dependencies", None) or [])
    return names


def route_user_keys(route: Any) -> dict[str, set[str]]:
    """这条路由从哪里读用户标识：{"path": {...}, "query": {...}, "body": {...}}。"""
    keys = set(USER_KEYS)
    return {
        "path": _param_names(route, "path_params") & keys,
        "query": _param_names(route, "query_params") & keys,
        "body": _body_model_fields(route) & keys,
    }


def _current_user_id(request: Request) -> str:
    from .security import verify_token

    token = _bearer(request)
    if not token:
        raise HTTPException(status_code=401, detail="请先登录")
    user_id = verify_token(request.app.state.settings, token)
    _reject_deleted(user_id)
    return user_id


def _reject_deleted(user_id: str) -> None:
    try:
        from .database.db import get_db

        row = get_db().execute("SELECT status FROM users WHERE id = ?", (user_id,)).fetchone()
    except Exception:
        raise HTTPException(status_code=503, detail="暂时无法核验账号状态，请稍后重试") from None
    if row is None:
        raise HTTPException(status_code=401, detail="账号不存在或已注销")
    if dict(row).get("status") == "deleted":
        raise HTTPException(status_code=403, detail="账号已注销")


def _mismatch(values: Iterable[Any], user_id: str) -> bool:
    return any(value not in (None, "") and str(value) != user_id for value in values)


async def product_access_guard(request: Request) -> None:
    path = request.scope.get("path") or request.url.path
    method = request.method.upper()
    if is_public(path):
        return

    admin = _is_admin(request)
    if is_admin_only(method, path):
        if admin:
            return
        if _bearer(request):
            raise HTTPException(status_code=403, detail="仅限管理员")
        raise HTTPException(status_code=401, detail="需要管理员登录")
    if admin:
        return

    route = request.scope.get("route")
    keys = route_user_keys(route)
    scoped = any(keys.values())
    if method in SAFE_METHODS and not scoped:
        return

    user_id = _current_user_id(request)
    request.state.user_id = user_id

    if _mismatch((request.path_params.get(k) for k in USER_KEYS), user_id):
        raise HTTPException(status_code=403, detail="只能访问自己的数据")

    query = request.query_params
    if _mismatch((v for k in USER_KEYS for v in query.getlist(k)), user_id):
        raise HTTPException(status_code=403, detail="只能访问自己的数据")
    missing = [k for k in keys["query"] if not query.get(k)]
    if missing:
        from urllib.parse import urlencode

        pairs = [(k, v) for k, v in query.multi_items() if k not in missing]
        pairs += [(k, user_id) for k in missing]
        request.scope["query_string"] = urlencode(pairs).encode()
        if hasattr(request, "_query_params"):
            del request._query_params

    if method not in SAFE_METHODS:
        body: Any = None
        content_type = request.headers.get("content-type", "")
        if "json" in content_type:
            try:
                body = await request.json()  # FastAPI 已读过并缓存，这里拿到的是同一个对象
            except Exception:
                body = None
        if isinstance(body, dict):
            if _mismatch((body.get(k) for k in USER_KEYS), user_id):
                raise HTTPException(status_code=403, detail="只能访问自己的数据")
            for key in keys["body"]:
                body[key] = user_id
