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

from .cache.cache import ai_cache
from .core.settings import settings
from .prompts.registry import prompt_registry
from .audit.logger import audit_logger
from .llm.siliconflow import SiliconFlowClient, ChatMessage, MessageRole, get_client
from .database.db import init_db, close_db
from .router import auth, chat, contents, family, notifications, solar_terms, subscription, today_plan, records, settings as settings_router_module, skills, share
from .router import constitution, content_cms, cards, recommendations
from .router import family as family_router
from .safety.router import router as safety_router
from .alerts.router import router as alert_router
from .alerts.store import AlertStore
from .metrics.middleware import MetricsMiddleware, get_metrics, track_llm_request
from .middleware.api_version import APIVersionMiddleware
from .middleware.tracing import RequestTracingMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .rag.router import router as rag_router
from .rag.knowledge_base import load_knowledge_bases
from .rag.embedder import init_embedders
from .feature_flags.router import router as flag_router
from .feature_flags import flag_store
from .feature_flags.middleware import feature_flag_middleware
from .prompts.router import router as prompt_router
from .prompts import prompt_store
from .router.config import UserTier, RoutingContext
from .router.router import ModelRouter
from .router.recommend import router as recommend_router
from .router.speech import router as speech_router
from .router.wisdom import router as wisdom_router
from .router.crowd import router as crowd_router
from .router.seasons_chat import router as seasons_chat_router
from .router.seasons_api import router as seasons_api_router
from .router.seasons_home import router as seasons_home_router
from .router.seasons_audio import router as seasons_audio_router
from .router.seasons_subscription import router as seasons_subscription_router
from .router.seasons_family import router as seasons_family_router
from .router.stripe import router as stripe_router
from .router.lifecycle import router as lifecycle_router
from .router.memory import router as memory_router
from .router.users import router as users_router
from .router.followup import router as followup_router
from .router.skills import router as skills_router
from .router.push import router as push_router
from .router.audit import router as audit_router
from .router.accessibility import router as accessibility_router
from .router.acupoint import router as acupoint_router
from .router.admin import router as admin_router
from .router.admin_auth import router as admin_auth_router
from .router.ai_companion import router as ai_companion_router
from .router.ai_content import router as ai_content_router
from .router.ai_dream import router as ai_dream_router
from .router.ai_ingredient_scan import router as ai_ingredient_scan_router
from .router.ai_wellness_plan import router as ai_wellness_plan_router
from .router.alipay import router as alipay_router
from .router.allergy_wellness import router as allergy_wellness_router
from .router.audio_v2 import router as audio_v2_router
from .router.auth import router as auth_router
from .router.baduanjin import router as baduanjin_router
from .router.banner import router as banner_router
from .router.calorie_tracker import router as calorie_tracker_router
from .router.cards import router as cards_router
from .router.child_wellness import router as child_wellness_router
from .router.chronic_care import router as chronic_care_router
from .router.client_metrics import router as client_metrics_router
from .router.community import router as community_router
from .router.constitution import router as constitution_router
from .router.content_cms import router as content_cms_router
from .router.contents import router as contents_router
from .router.core_skills import router as core_skills_router
from .router.couple_wellness import router as couple_wellness_router
from .router.coupon import router as coupon_router
from .router.cultural_stories import router as cultural_stories_router
from .router.data_analytics import router as data_analytics_router
from .router.emotion import router as emotion_router
from .router.exercise import router as exercise_router
from .router.expert_qa import router as expert_qa_router
from .router.eye_care import router as eye_care_router
from .router.feedback import router as feedback_router
from .router.first_insight import router as first_insight_router
from .router.food_compatibility import router as food_compatibility_router
from .router.food_therapy import router as food_therapy_router
from .router.gamification import router as gamification_router
from .router.gifting import router as gifting_router
from .router.gratitude import router as gratitude_router
from .router.habit_builder import router as habit_builder_router
from .router.hair_care import router as hair_care_router
from .router.health import router as health_router
from .router.health_integration import router as health_integration_router
from .router.herbal_knowledge import router as herbal_knowledge_router
from .router.journal import router as journal_router
from .router.kidney_care import router as kidney_care_router
from .router.live_class import router as live_class_router
from .router.liver_care import router as liver_care_router
from .router.localization import router as localization_router
from .router.lunar_calendar import router as lunar_calendar_router
from .router.lung_care import router as lung_care_router
from .router.maternity import router as maternity_router
from .router.membership import router as membership_router
from .router.menstrual import router as menstrual_router
from .router.mental_wellness import router as mental_wellness_router
from .router.meridian import router as meridian_router
from .router.moxibustion import router as moxibustion_router
from .router.multimodal_images import router as multimodal_images_router
from .router.multimodal_speech import router as multimodal_speech_router
from .router.multimodal_videos import router as multimodal_videos_router
from .router.notifications import router as notifications_router
from .router.oauth_wechat import router as oauth_wechat_router
from .router.onboarding import router as onboarding_router
from .router.pet_wellness import router as pet_wellness_router
from .router.postpartum import router as postpartum_router
from .router.push_intelligence import router as push_intelligence_router
from .router.push_notifications import router as push_notifications_router
from .router.recipe import router as recipe_router
from .router.recommendations import router as recommendations_router
from .router.records import router as records_router
from .router.regional_wellness import router as regional_wellness_router
from .router.senior_wellness import router as senior_wellness_router
from .router.settings import router as settings_router
from .router.share import router as share_router
from .router.shichen import router as shichen_router
from .router.skin_care import router as skin_care_router
from .router.sleep import router as sleep_router
from .router.smart_alarm import router as smart_alarm_router
from .router.solar_terms import router as solar_terms_router
from .router.solar_wellness import router as solar_wellness_router
from .router.diary import router as diary_router
from .router.favorites import router as favorites_router
from .router.sports_recovery import router as sports_recovery_router
from .router.stomach_care import router as stomach_care_router
from .router.subscription_local import router as subscription_local_router
from .router.tcm_culture import router as tcm_culture_router
from .router.tcm_food_safety import router as tcm_food_safety_router
from .router.tcm_medication import router as tcm_medication_router
from .router.tea import router as tea_router
from .router.theme import router as theme_router
from .router.timezone_wellness import router as timezone_wellness_router
from .router.today_plan import router as today_plan_router
from .router.upload import router as upload_router
from .router.user_data import router as user_data_router
from .router.water_tracker import router as water_tracker_router
from .router.wearable import router as wearable_router
from .router.weather_wellness import router as weather_wellness_router
from .router.wechat_social import router as wechat_social_router
from .router.weight_manage import router as weight_manage_router
from .router.wellness_myth import router as wellness_myth_router
from .router.western_bridge import router as western_bridge_router
from .router.widget import router as widget_router
from .router.workplace_wellness import router as workplace_wellness_router
from .router.youth_wellness import router as youth_wellness_router


# ==================== RAG 惰性加载 ====================

_rag_ready = False


async def _lazy_load_rag():
    """RAG 知识库惰性加载，不阻塞启动"""
    global _rag_ready
    try:
        load_knowledge_bases()
        init_embedders()
        _rag_ready = True
        _logger.info("[Startup] RAG 知识库后台加载完成")
    except Exception as e:
        _logger.error(f"[Startup] RAG 加载失败: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期：启动时初始化数据库，关闭时清理"""
    # Startup
    _logger.info("[Startup] 初始化数据库...")
    init_db()
    _logger.info("[Startup] 数据库就绪")

    _logger.info("[Startup] RAG 知识库后台加载...")
    import asyncio
    asyncio.create_task(_lazy_load_rag())

    _logger.info("[Startup] 初始化 LLM 审计日志...")
    from .llm.audit import init_llm_audit
    init_llm_audit()
    _logger.info("[Startup] LLM 审计日志就绪")

    _logger.info("[Startup] 初始化 Feature Flag 系统...")
    flag_store.ensure_tables()
    flag_store.init_preset_flags()
    _logger.info("[Startup] Feature Flag 系统就绪")

    _logger.info("[Startup] 初始化 Prompt 版本管理...")
    prompt_store.init_tables()
    prompt_store.init_presets()
    _logger.info("[Startup] Prompt 版本管理就绪")

    _logger.info("[Startup] 初始化告警系统...")
    from .alerts.store import alert_store as _alert_store
    _alert_store.init_tables()
    _logger.info("[Startup] 告警系统就绪")

    yield
    # Shutdown
    _logger.info("[Shutdown] 关闭数据库连接...")
    close_db()
    _logger.info("[Shutdown] 完成")


app = FastAPI(title="顺时 AI Router API", version="2.0.0", lifespan=lifespan)

# ==================== 全局异常处理 ====================

import logging
import traceback

_logger = logging.getLogger("shunshi")

from fastapi.responses import JSONResponse
from starlette.requests import Request


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """全局异常处理：捕获所有未处理异常，隐藏堆栈细节，统一返回 JSON 错误"""
    request_id = getattr(request.state, "request_id", None) or request.headers.get("X-Request-Id", "unknown")
    _logger.error(
        f"[Unhandled Exception] request_id={request_id} "
        f"method={request.method} path={request.url.path} "
        f"error={type(exc).__name__}: {exc}\n{traceback.format_exc()}"
    )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "服务器内部错误，请稍后重试",
            "error_code": "INTERNAL_ERROR",
            "request_id": request_id,
        },
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """HTTP 异常统一格式化，确保所有错误返回 JSON"""
    request_id = getattr(request.state, "request_id", None) or request.headers.get("X-Request-Id", "unknown")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "error_code": f"HTTP_{exc.status_code}",
            "request_id": request_id,
        },
    )

# 静态文件服务 (知识库图片)
_static_dir = Path(__file__).parent.parent / "static"
if _static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(_static_dir)), name="static")

# CORS
from fastapi.middleware.cors import CORSMiddleware
# CORS — 仅允许生产域名
_CORS_ORIGINS = settings.CORS_ALLOWED_ORIGINS.split(",")

# 开发模式：localhost 支持（仅当环境变量显式启用）
if settings.CORS_ALLOW_LOCALHOST:
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
    expose_headers=["X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset", "Retry-After", "X-Request-Id"],
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

# 请求限流中间件
app.add_middleware(RateLimitMiddleware)

# API 版本管理中间件
app.add_middleware(APIVersionMiddleware)

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
app.include_router(settings_router_module.router)
app.include_router(today_plan.router)
app.include_router(chat.router)
app.include_router(seasons_chat_router, prefix="/api/v1")
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
app.include_router(share.router)

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
app.include_router(recommend_router)
# SEASONS Global AI Chat

# 批量注册缺失路由
app.include_router(accessibility_router)
app.include_router(acupoint_router)
app.include_router(admin_router)
app.include_router(admin_auth_router)
app.include_router(ai_companion_router)
app.include_router(ai_content_router)
app.include_router(ai_dream_router)
app.include_router(ai_ingredient_scan_router)
app.include_router(ai_wellness_plan_router)
app.include_router(alipay_router)
app.include_router(allergy_wellness_router)
app.include_router(audio_v2_router)
app.include_router(auth_router)
app.include_router(baduanjin_router)
app.include_router(banner_router)
app.include_router(calorie_tracker_router)
app.include_router(child_wellness_router)
app.include_router(chronic_care_router)
app.include_router(client_metrics_router)
app.include_router(community_router)
app.include_router(contents_router)
app.include_router(core_skills_router)
app.include_router(couple_wellness_router)
app.include_router(coupon_router)
app.include_router(cultural_stories_router)
app.include_router(data_analytics_router)
app.include_router(emotion_router)
app.include_router(exercise_router)
app.include_router(expert_qa_router)
app.include_router(eye_care_router)
app.include_router(feedback_router)
app.include_router(first_insight_router)
app.include_router(food_compatibility_router)
app.include_router(food_therapy_router)
app.include_router(gamification_router)
app.include_router(gifting_router)
app.include_router(gratitude_router)
app.include_router(habit_builder_router)
app.include_router(hair_care_router)
app.include_router(health_router)
app.include_router(health_integration_router)
app.include_router(herbal_knowledge_router)
app.include_router(journal_router)
app.include_router(kidney_care_router)
app.include_router(live_class_router)
app.include_router(liver_care_router)
app.include_router(localization_router)
app.include_router(lunar_calendar_router)
app.include_router(lung_care_router)
app.include_router(maternity_router)
app.include_router(membership_router)
app.include_router(menstrual_router)
app.include_router(mental_wellness_router)
app.include_router(meridian_router)
app.include_router(moxibustion_router)
app.include_router(multimodal_images_router)
app.include_router(multimodal_speech_router)
app.include_router(speech_router)
app.include_router(multimodal_videos_router)
app.include_router(notifications_router)
app.include_router(oauth_wechat_router)
app.include_router(onboarding_router)
app.include_router(pet_wellness_router)
app.include_router(postpartum_router)
app.include_router(push_intelligence_router)
app.include_router(push_notifications_router)
app.include_router(recipe_router)
app.include_router(records_router)
app.include_router(regional_wellness_router)
app.include_router(senior_wellness_router)
app.include_router(settings_router)
app.include_router(share_router)
app.include_router(shichen_router)
app.include_router(skin_care_router)
app.include_router(sleep_router)
app.include_router(smart_alarm_router)
app.include_router(solar_terms_router)
app.include_router(solar_wellness_router)
app.include_router(diary_router)
app.include_router(favorites_router)
app.include_router(sports_recovery_router)
app.include_router(stomach_care_router)
app.include_router(subscription_local_router)
app.include_router(tcm_culture_router)
app.include_router(tcm_food_safety_router)
app.include_router(tcm_medication_router)
app.include_router(tea_router)
app.include_router(theme_router)
app.include_router(timezone_wellness_router)
app.include_router(today_plan_router)
app.include_router(upload_router)
app.include_router(user_data_router)
app.include_router(water_tracker_router)
app.include_router(wearable_router)
app.include_router(weather_wellness_router)
app.include_router(wechat_social_router)
app.include_router(weight_manage_router)
app.include_router(wellness_myth_router)
app.include_router(western_bridge_router)
app.include_router(widget_router)
app.include_router(workplace_wellness_router)
app.include_router(youth_wellness_router)

# 全局路由器
model_router = ModelRouter()

# LLM 客户端
llm_client = SiliconFlowClient(
    api_key=settings.SILICONFLOW_API_KEY or os.getenv("SILICONFLOW_API_KEY", "")
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
        _logger.error(f"[Chat] LLM 调用失败: {e}, 尝试降级...")
        
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
