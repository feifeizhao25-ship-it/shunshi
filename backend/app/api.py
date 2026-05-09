"""
顺时后端 API 服务
包含所有业务接口

作者: Claw 🦅
日期: 2026-03-13
"""

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .router import chat, auth
from .router import contents, family, notifications, solar_terms, subscription, today_plan, records, settings
from .database.db import init_db, close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # Startup
    print("[Startup] 初始化数据库...")
    init_db()
    print("[Startup] 数据库就绪")
    yield
    # Shutdown
    print("[Shutdown] 关闭数据库连接...")
    close_db()


app = FastAPI(
    title="顺时 API",
    version="1.0.0",
    description="顺时 AI 养生陪伴系统后端 API",
    lifespan=lifespan
)

# CORS — 仅允许生产域名
_CORS_ORIGINS = os.getenv(
    "CORS_ALLOWED_ORIGINS",
    "https://shunshi.app,https://www.shunshi.app,https://api.shunshi.app"
).split(",")

if os.getenv("CORS_ALLOW_LOCALHOST", "").lower() == "true":
    _CORS_ORIGINS.extend([
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8080",
    ])

app.add_middleware(
    CORSMiddleware,
    allow_origins=_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router)
app.include_router(chat.router)
app.include_router(today_plan.router)
app.include_router(contents.router)
app.include_router(family.router)
app.include_router(solar_terms.router)
app.include_router(subscription.router)
app.include_router(notifications.router)
app.include_router(records.router)
app.include_router(settings.router)

# 健康检查
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "shunshi-api"}

@app.get("/")
async def root():
    return {"message": "欢迎使用顺时 API", "version": "1.0.0"}
