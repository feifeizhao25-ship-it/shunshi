"""顺时后端骨架入口：单 FastAPI 应用，按模块分 router。"""

from contextlib import asynccontextmanager
import importlib
import pkgutil

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings
from .db import init_db, make_engine, make_session_factory
from .db.database import engine as product_engine, init_db as init_product_db
from .database.db import close_all_test_connections, init_db as init_record_store
from .models.base import Base as product_model_base
from .routers import chat, feedback, health, memory, reflections, seasons, settings as settings_router, subscription, user


def _include_product_routers(app: FastAPI) -> None:
    """Mount every production router under ``app.router``.

    Keeping this discovery fail-closed ensures a missing runtime dependency or
    broken router prevents release instead of silently shipping a partial API.
    """
    from . import router as product_router_package

    mounted = {id(route) for route in app.router.routes}
    for module_info in pkgutil.iter_modules(product_router_package.__path__):
        if module_info.name.startswith("_"):
            continue
        module = importlib.import_module(f"{product_router_package.__name__}.{module_info.name}")
        candidate = getattr(module, "router", None)
        if candidate is not None and id(candidate) not in mounted:
            needs_prefix = not candidate.prefix and any(
                getattr(route, "path", None) == "" for route in candidate.routes
            )
            prefix = f"/api/v1/{module_info.name.replace('_', '-')}" if needs_prefix else ""
            app.include_router(candidate, prefix=prefix)
            mounted.add(id(candidate))


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    if settings.env == "production" and (
        len(settings.jwt_secret) < 32 or not settings.cors_origin_list()
    ):
        raise RuntimeError("生产环境必须配置至少 32 位 SHUNSHI_JWT_SECRET 和明确的 SHUNSHI_CORS_ORIGINS")

    engine = make_engine(settings.database_url)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        init_db(engine)  # 启动建表，对齐见己 init_db 惯例
        init_product_db()
        product_model_base.metadata.create_all(product_engine)
        init_record_store()
        try:
            yield
        finally:
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
    app.include_router(subscription.router)
    app.include_router(reflections.router)
    app.include_router(feedback.router)
    app.include_router(settings_router.router)
    app.include_router(seasons.router)
    _include_product_routers(app)
    return app


app = create_app()
