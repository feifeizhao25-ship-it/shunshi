"""
顺时后端 API 服务
包含所有业务接口

作者: Claw 🦅
日期: 2026-03-13
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .router import chat, auth
from .router import contents, family, notifications, solar_terms, subscription, today_plan, records, settings
from .router import multimodal_images, multimodal_speech, multimodal_videos
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

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
app.include_router(multimodal_images.router)
app.include_router(multimodal_speech.router)
app.include_router(multimodal_videos.router)

# 健康检查
@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "shunshi-api"}

@app.get("/")
async def root():
    return {"message": "欢迎使用顺时 API", "version": "1.0.0"}
