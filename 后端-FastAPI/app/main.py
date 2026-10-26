"""顺时后端骨架入口：单 FastAPI 应用，按模块分 router。"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings
from .db import init_db, make_engine, make_session_factory
from .routers import chat, content, feedback, health, memory, reflections, seasons, settings as settings_router, subscription, user


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
        yield
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
    app.include_router(user.router)
    app.include_router(memory.router)
    app.include_router(chat.router)
    app.include_router(subscription.router)
    app.include_router(reflections.router)
    app.include_router(feedback.router)
    app.include_router(settings_router.router)
    app.include_router(seasons.router)
    app.include_router(content.router)
    return app


app = create_app()
