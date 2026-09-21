"""顺时后端骨架入口：单 FastAPI 应用，按模块分 router。"""

from contextlib import asynccontextmanager
import asyncio
import importlib
import pkgutil

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings
from .db import init_db, make_engine, make_session_factory
from .db.database import engine as product_engine, init_db as init_product_db
from .database.db import close_all_test_connections, init_db as init_record_store
from .models.base import Base as product_model_base
from .routers import chat, content, feedback, health, memory, reflections, seasons, settings as settings_router, subscription, user


# 国际版 SEASONS 专用的模块，国内版不挂载：
# - stripe / seasons_subscription：境外支付与美元定价；
# - seasons_chat：``POST /ai/chat`` 英文人设、不登录可用、user_id 由客户端自报（额度形同虚设）；
# - seasons_api / seasons_home / seasons_family / seasons_audio：国际版的用户、家庭与内容接口，
#   其中 ``/api/v1/seasons/user/{user_id}`` 的删除与导出不校验身份。
# 国内客户端的对话页仍调 ``/ai/chat``，由 routers/chat.py 的 legacy_router 接到国内对话链路。
INTERNATIONAL_ONLY_MODULES = frozenset(
    {
        "stripe",
        "seasons_api",
        "seasons_audio",
        "seasons_chat",
        "seasons_family",
        "seasons_home",
        "seasons_subscription",
    }
)


def _include_product_routers(app: FastAPI) -> None:
    """Mount every production router under ``app.router``.

    Keeping this discovery fail-closed ensures a missing runtime dependency or
    broken router prevents release instead of silently shipping a partial API.
    """
    from fastapi import Depends

    from . import router as product_router_package
    from .product_access import product_access_guard

    mounted = {id(route) for route in app.router.routes}
    for module_info in pkgutil.iter_modules(product_router_package.__path__):
        if module_info.name.startswith("_"):
            continue
        if module_info.name in INTERNATIONAL_ONLY_MODULES:
            continue
        module = importlib.import_module(f"{product_router_package.__name__}.{module_info.name}")
        candidate = getattr(module, "router", None)
        if candidate is not None and id(candidate) not in mounted:
            needs_prefix = not candidate.prefix and any(
                getattr(route, "path", None) == "" for route in candidate.routes
            )
            prefix = f"/api/v1/{module_info.name.replace('_', '-')}" if needs_prefix else ""
            # 默认关着：见 app/product_access.py。
            app.include_router(
                candidate, prefix=prefix, dependencies=[Depends(product_access_guard)]
            )
            mounted.add(id(candidate))


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    if settings.env == "production" and (
        len(settings.jwt_secret) < 32 or not settings.cors_origin_list()
    ):
        raise RuntimeError("生产环境必须配置至少 32 位 SHUNSHI_JWT_SECRET 和明确的 SHUNSHI_CORS_ORIGINS")

    # 生产环境不允许回落到 SQLite 缺省值。
    #
    # `Settings` 的 env_prefix 是 "SHUNSHI_"，而 docker-compose.yml 里写的是
    # 不带前缀的 DATABASE_URL —— pydantic-settings 根本不读它。于是
    # database_url 悄悄用了缺省值 sqlite:///./shunshi_dev.db，落在容器的
    # WORKDIR /app 下，而 compose 只把 /app/data 和 /app/logs 做成了 volume。
    #
    # 结果：postgres 容器健康地跑着、一个字节都没写进去；用户数据全在
    # 容器可写层里，**下一次 docker compose up --build 就清零**。
    #
    # JWT 与 CORS 都是 fail-closed 的，唯独"数据存在哪"不是——偏偏它是
    # 唯一一个错了不会报错、只会在重新部署那天才暴露的配置。补上。
    if settings.env == "production" and settings.database_url.startswith("sqlite"):
        raise RuntimeError(
            "生产环境必须显式配置 SHUNSHI_DATABASE_URL（PostgreSQL DSN）。"
            "当前回落到了 SQLite 缺省值，数据不会持久化。"
            "注意变量名要带 SHUNSHI_ 前缀，不带前缀的 DATABASE_URL 不会被读取。"
        )

    import os

    legacy_secret = os.environ.get("JWT_SECRET", "")
    if legacy_secret and settings.jwt_secret and legacy_secret != settings.jwt_secret:
        # 登录接口与核心接口必须用同一把密钥，否则登录成功后处处 401（见 core/settings.py）。
        raise RuntimeError("JWT_SECRET 与 SHUNSHI_JWT_SECRET 同时配置且不一致；只保留 SHUNSHI_JWT_SECRET")

    engine = make_engine(settings.database_url)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        init_db(engine)  # 启动建表，对齐见己 init_db 惯例
        init_product_db()
        product_model_base.metadata.create_all(product_engine)
        init_record_store()
        from .rag.knowledge_base import load_knowledge_bases

        load_knowledge_bases()
        recovery_stop = asyncio.Event()
        recovery_task = None
        if settings.env == "production":
            from .services.payment_recovery import payment_recovery_loop
            recovery_task = asyncio.create_task(payment_recovery_loop(app, recovery_stop))
        try:
            yield
        finally:
            recovery_stop.set()
            if recovery_task is not None:
                await recovery_task
            close_all_test_connections()
            engine.dispose()

    app = FastAPI(
        title="顺时 API",
        version="0.1.0",
        docs_url=None if settings.env == "production" else "/docs",
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.engine = engine
    app.state.session_factory = make_session_factory(engine)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list() or ["http://localhost:3000"],
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    )

    app.include_router(health.router)
    # The production auth contract accepts the email/password payload used by
    # the shipped clients. Mount only those overlapping account primitives
    # before the legacy skeleton user router. Other legacy account endpoints
    # (data export/deletion and guest auth) remain authoritative; mounting the
    # whole production router here would silently replace their response
    # contracts because Starlette resolves duplicate paths by registration
    # order.
    from .router import auth as product_auth_router
    auth_compat = APIRouter()
    preferred_auth_paths = {
        "/api/v1/auth/register",
        "/api/v1/auth/login",
        "/api/v1/auth/refresh",
        "/api/v1/auth/me",
    }
    auth_compat.routes.extend(
        route
        for route in product_auth_router.router.routes
        if getattr(route, "path", None) in preferred_auth_paths
    )
    app.include_router(auth_compat)
    # These authenticated core routes remain authoritative. The legacy content
    # proxy is intentionally excluded because the production content router
    # below owns the public catalogue and search contract.
    app.include_router(user.router)
    app.include_router(memory.router)
    app.include_router(chat.router)
    app.include_router(chat.legacy_router)
    app.include_router(subscription.router)
    app.include_router(reflections.router)
    app.include_router(feedback.router)
    app.include_router(settings_router.router)
    app.include_router(seasons.router)
    # Only mount the authenticated proxy endpoints from the skeleton content
    # module. Its /contents routes are placeholders and must not shadow the
    # seeded, production catalogue discovered below.
    content_proxy = APIRouter()
    content_proxy_paths = {
        "/api/v1/cms/content/{content_id}",
        "/api/v1/seasons/audio/{audio_id}",
    }
    content_proxy.routes.extend(
        route
        for route in content.router.routes
        if getattr(route, "path", None) in content_proxy_paths
    )
    app.include_router(content_proxy)
    _include_product_routers(app)
    return app


app = create_app()
