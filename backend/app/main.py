"""
顺时 AI Router API - 完整版
FastAPI + SiliconFlow Integration

作者: Claw 🦅
日期: 2026-03-09
"""

import uuid
import time
import os
from contextlib import asynccontextmanager
from dotenv import load_dotenv
load_dotenv()
from typing import Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Header
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from pydantic import BaseModel, Field
from datetime import datetime

from .router.config import UserTier, RoutingContext
from .router.router import ModelRouter
from .cache.cache import ai_cache
from .prompts.registry import prompt_registry
from .audit.logger import audit_logger
from .llm.siliconflow import SiliconFlowClient, ChatMessage, MessageRole, get_client
from .database.db import init_db, close_db
from .router import auth, chat, contents, family, notifications, solar_terms, subscription, today_plan, records, settings, skills
from .router.recommend import router as recommend_router
from .router import constitution, content_cms, cards, recommendations
from .router.speech import router as speech_router
from .router.wisdom import router as wisdom_router
from .router.crowd import router as crowd_router
from .router.seasons_chat import router as seasons_chat_router
from .router.seasons_api import router as seasons_api_router
from .router.seasons_home import router as seasons_home_router
from .router.seasons_audio import router as seasons_audio_router
from .router.seasons_subscription import router as seasons_subscription_router
from .router.seasons_family import router as seasons_family_router
from .router import family as family_router
from .router.stripe import router as stripe_router
from .router.lifecycle import router as lifecycle_router
from .router.memory import router as memory_router
from .router.users import router as users_router
from .router.followup import router as followup_router
from .router.skills import router as skills_router
from .router.push import router as push_router
from .router.audit import router as audit_router
from .safety.router import router as safety_router
from .alerts.router import router as alert_router
from .alerts.store import AlertStore
from .metrics.middleware import MetricsMiddleware, get_metrics, track_llm_request
from .middleware.tracing import RequestTracingMiddleware
from .rag.router import router as rag_router
from .rag.knowledge_base import load_knowledge_bases
from .rag.embedder import init_embedders
from .feature_flags.router import router as flag_router
from .feature_flags import flag_store
from .feature_flags.middleware import feature_flag_middleware
from .prompts.router import router as prompt_router
from .prompts import prompt_store


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期：启动时初始化数据库，关闭时清理"""
    # Startup
    print("[Startup] 初始化数据库...")
    init_db()
    print("[Startup] 数据库就绪")

    print("[Startup] 加载 RAG 知识库...")
    load_knowledge_bases()
    init_embedders()
    print("[Startup] RAG 知识库就绪")

    print("[Startup] 初始化 LLM 审计日志...")
    from .llm.audit import init_llm_audit
    init_llm_audit()
    print("[Startup] LLM 审计日志就绪")

    print("[Startup] 初始化 Feature Flag 系统...")
    flag_store.ensure_tables()
    flag_store.init_preset_flags()
    print("[Startup] Feature Flag 系统就绪")

    print("[Startup] 初始化 Prompt 版本管理...")
    prompt_store.init_tables()
    prompt_store.init_presets()
    print("[Startup] Prompt 版本管理就绪")

    print("[Startup] 初始化告警系统...")
    from .alerts.store import alert_store as _alert_store
    _alert_store.init_tables()
    print("[Startup] 告警系统就绪")

    yield
    # Shutdown
    print("[Shutdown] 关闭数据库连接...")
    close_db()
    print("[Shutdown] 完成")


app = FastAPI(title="顺时 AI Router API", version="2.0.0", lifespan=lifespan)

# 静态文件服务 (知识库图片)
_static_dir = Path(__file__).parent.parent / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")

# CORS
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# ngrok 免费版跳过浏览器警告页面
from starlette.middleware.base import BaseHTTPMiddleware
class NgrokSkipMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if "ngrok" in request.headers.get("host", ""):
            request.headers.__dict__["_list"].append(
                (b"ngrok-skip-browser-warning", b"true")
            )
        response = await call_next(request)
        return response
app.add_middleware(NgrokSkipMiddleware)

# 链路追踪中间件 (最早注册，最晚执行，确保覆盖所有路由)
app.add_middleware(RequestTracingMiddleware)

# Prometheus Metrics 中间件
app.add_middleware(MetricsMiddleware)

# Feature Flag 中间件
app.add_middleware(feature_flag_middleware)

# 注册所有业务路由
app.include_router(auth.router)
app.include_router(contents.router)
app.include_router(family.router)
app.include_router(solar_terms.router)
app.include_router(subscription.router)
app.include_router(notifications.router)
app.include_router(records.router)
app.include_router(settings.router)
app.include_router(today_plan.router)
app.include_router(chat.router)
# 注册新系统路由
app.include_router(lifecycle_router)
app.include_router(memory_router)
app.include_router(users_router)
app.include_router(followup_router)
app.include_router(skills_router, prefix="/api/v1/skills", tags=["skills"])

# 体质辨识 & 内容 CMS 路由
app.include_router(constitution.router, prefix="/api/v1/constitution", tags=["constitution"])
app.include_router(content_cms.router, prefix="/api/v1/cms", tags=["content-cms"])

# 系统提示卡 & 智能推荐路由
app.include_router(cards.router)
app.include_router(recommendations.router)

# 国际版 Stripe 支付路由
app.include_router(stripe_router)

# RAG 知识库路由
app.include_router(rag_router)

# 个性化推送路由
app.include_router(push_router)

# LLM 审计日志路由 (admin)
app.include_router(audit_router)

# 安全守卫路由
app.include_router(safety_router)

# Feature Flag 管理路由
app.include_router(flag_router, prefix="/api/v1/flags", tags=["feature-flags"])

# Prompt 版本管理路由
app.include_router(prompt_router)

# 告警管理路由
app.include_router(alert_router)
app.include_router(speech_router)
app.include_router(recommend_router)
app.include_router(wisdom_router)
app.include_router(crowd_router)
# SEASONS Global AI Chat
app.include_router(seasons_chat_router)
app.include_router(seasons_api_router)
app.include_router(seasons_home_router)
app.include_router(seasons_audio_router)
app.include_router(seasons_subscription_router)
app.include_router(seasons_family_router)

# 全局路由器
model_router = ModelRouter()

# LLM 客户端
llm_client = SiliconFlowClient(
    api_key=os.getenv("SILICONFLOW_API_KEY", "sk-zzgbgihucvfipavpgvviavuvgqfczsiqjheixrsbjpuscwvm")
)


# ==================== 请求/响应模型 ====================

class ChatRequest(BaseModel):
    """聊天请求"""
    user_id: str
    message: str
    conversation_id: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class ChatResponse(BaseModel):
    """聊天响应"""
    response_id: str
    message: str
    model: str
    tokens_used: int
    latency_ms: int
    cost_usd: float
    cached: bool = False


class RouteRequest(BaseModel):
    """路由请求"""
    user_id: str
    user_tier: str = "free"
    api_path: str
    prompt: str
    skill_name: Optional[str] = None
    context_length: int = 0


class RouteResponse(BaseModel):
    """路由响应"""
    selected_model: str
    fallback_model: str
    reasoning: str
    estimated_cost: float
    cacheable: bool


class StatsResponse(BaseModel):
    """统计响应"""
    cache_stats: Dict[str, Any]
    audit_stats: Dict[str, Any]


# ==================== 内部函数 ====================

async def call_llm(
    model: str,
    prompt: str,
    system_prompt: str = None,
    temperature: float = 0.7,
    max_tokens: int = 4096,
) -> tuple[str, int, float]:
    """
    调用 LLM 并返回响应
    
    Returns: (response_text, tokens_used, cost_usd)
    """
    messages = []
    if system_prompt:
        messages.append(ChatMessage(role=MessageRole.SYSTEM, content=system_prompt))
    messages.append(ChatMessage(role=MessageRole.USER, content=prompt))
    
    response = await llm_client.chat_completion(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    
    content = response.choices[0].get("message", {}).get("content", "")
    tokens = response.usage.total_tokens
    
    # 成本计算 (简化版)
    cost_per_token = {
        "deepseek-v3.2": 0.000001,
        "glm-4.6": 0.000003,
        "qwen3-235b": 0.000024,
        "kimi-k2-thinking": 0.00003,
        "minimax-m2": 0.0000007,
    }
    rate = cost_per_token.get(model, 0.000001)
    cost = tokens * rate
    
    return content, tokens, cost


# ==================== API 端点 ====================

@app.get("/")
async def root():
    """健康检查"""
    return {
        "service": "ShunShi AI Router",
        "version": "1.0.0",
        "status": "running",
    }


@app.get("/health")
async def health():
    """健康检查"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/metrics")
async def metrics():
    """Prometheus 指标端点"""
    from starlette.responses import Response
    body = get_metrics()
    return Response(content=body, media_type="text/plain")


@app.post("/route", response_model=RouteResponse)
async def route(request: RouteRequest):
    """
    模型路由接口
    
    根据请求上下文，选择最佳模型
    """
    context = RoutingContext(
        user_id=request.user_id,
        user_tier=UserTier(request.user_tier),
        api_path=request.api_path,
        skill_name=request.skill_name,
        prompt=request.prompt,
        context_length=request.context_length,
    )
    
    result = model_router.select_model(context)
    
    return RouteResponse(
        selected_model=result.selected_model,
        fallback_model=result.fallback_model,
        reasoning=result.reasoning,
        estimated_cost=result.estimated_cost,
        cacheable=result.cacheable,
    )


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    完整对话接口
    
    包含：路由 → LLM调用 → 缓存 → 审计
    """
    start_time = time.time()
    event_id = str(uuid.uuid4())
    
    # Step 1: 获取系统 Prompt
    system_prompt = prompt_registry.get("core") or "你是顺时，一个温暖贴心的 AI 养生健康陪伴助手。"
    
    # Step 2: 路由决策
    user_tier = request.context.get("user_tier", "free") if request.context else "free"
    
    context = RoutingContext(
        user_id=request.user_id,
        user_tier=UserTier(user_tier),
        api_path="/chat/send",
        prompt=request.message,
    )
    
    route_result = model_router.select_model(context)
    selected_model = route_result.selected_model
    
    # Step 3: 检查缓存
    cached_response = None
    if route_result.cacheable:
        cached_response = ai_cache.get(
            prompt=request.message,
            user_stage=request.context.get("stage") if request.context else None,
        )
    
    if cached_response:
        audit_logger.log_cache_hit(event_id)
        
        return ChatResponse(
            response_id=event_id,
            message=cached_response,
            model=selected_model,
            tokens_used=0,
            latency_ms=int((time.time() - start_time) * 1000),
            cost_usd=0.0,
            cached=True,
        )
    
    # Step 4: 记录审计日志
    audit_logger.log_request(
        event_id=event_id,
        user_id=request.user_id,
        user_tier=user_tier,
        api_path="/chat/send",
        prompt=request.message,
        model=selected_model,
    )
    
    # Step 5: 调用 LLM
    try:
        response_text, tokens_used, cost_usd = await call_llm(
            model=selected_model,
            prompt=request.message,
            system_prompt=system_prompt,
        )
    except Exception as e:
        # 降级处理
        logger = __import__("logging").getLogger(__name__)
        logger.error(f"[Chat] LLM 调用失败: {e}, 尝试降级...")
        
        audit_logger.log_fallback(
            event_id=event_id,
            from_model=selected_model,
            to_model=route_result.fallback_model,
            reason=str(e),
        )
        
        # 尝试降级模型
        fallback_model = route_result.fallback_model
        try:
            response_text, tokens_used, cost_usd = await call_llm(
                model=fallback_model,
                prompt=request.message,
                system_prompt=system_prompt,
            )
            selected_model = fallback_model
        except Exception as e2:
            audit_logger.log_error(event_id, str(e2))
            raise HTTPException(status_code=502, detail=f"LLM 调用失败: {e2}")
    
    # Step 6: 记录响应
    audit_logger.log_response(
        event_id=event_id,
        response=response_text,
        response_tokens=tokens_used,
        latency_ms=int((time.time() - start_time) * 1000),
        cost_usd=cost_usd,
    )
    
    # Step 7: 缓存结果
    if route_result.cacheable:
        ai_cache.set(
            prompt=request.message,
            response=response_text,
            user_stage=request.context.get("stage") if request.context else None,
        )
    
    return ChatResponse(
        response_id=event_id,
        message=response_text,
        model=selected_model,
        tokens_used=tokens_used,
        latency_ms=int((time.time() - start_time) * 1000),
        cost_usd=cost_usd,
        cached=False,
    )


@app.get("/prompts")
async def list_prompts():
    """列出所有 Prompts"""
    return {"prompts": prompt_registry.list_prompts()}


@app.get("/prompts/{name}")
async def get_prompt(name: str):
    """获取 Prompt"""
    prompt = prompt_registry.get_with_metadata(name)
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt not found")
    return prompt


@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    """获取统计信息"""
    return StatsResponse(
        cache_stats=ai_cache.get_stats(),
        audit_stats=audit_logger.get_stats(),
    )


@app.get("/models")
async def list_models():
    """列出可用模型"""
    from .router.config import MODEL_CONFIG
    
    models = []
    for name, config in MODEL_CONFIG.items():
        models.append({
            "name": name,
            "sf_model": llm_client._get_model_name(name),
            "provider": config.get("provider"),
            "tier": config.get("tier"),
            "context_window": config.get("context_window"),
            "cost_per_1k_input": config.get("cost_per_1k_input"),
            "cost_per_1k_output": config.get("cost_per_1k_output"),
        })
    
    return {"models": models}


# ==================== 主程序入口 ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
