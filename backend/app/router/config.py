"""
顺时 AI Router - 模型路由系统 v1
ShunShi AI Model Routing System

核心功能：
1. 用户意图识别 (Intent Detection)
2. Skill 路由 (Skill Routing)
3. 模型选择 (Model Selection)
4. Prompt 管理 (Prompt Management)
5. Safety 控制 (Safety Control)
6. Schema 校验 (Schema Validation)
7. Follow-up 生成 (Follow-up Generation)
8. Audit 记录 (Audit Logging)

作者: Claw 🦅
日期: 2026-03-09
"""

from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
import hashlib
import json


# ==================== 模型枚举 ====================

class ModelTier(str, Enum):
    """模型层级"""
    DEFAULT = "default"          # DeepSeek-V3.2 - 高频聊天 (80%)
    CONTENT = "content"         # GLM-4.6 - 内容生成 (15%)
    DEEP = "deep"               # Qwen3-235B - 深度分析 (5%)
    AGENT = "agent"             # Kimi K2 - 复杂Agent
    BACKGROUND = "background"  # MiniMax M2 - 后台任务


class ModelProvider(str, Enum):
    """模型提供商"""
    DEEPSEEK = "deepseek"
    GLM = "glm"
    QWEN = "qwen"
    KIMI = "kimi"
    MINIMAX = "minimax"
    OPENROUTER = "openrouter"
    SILICONFLOW = "siliconflow"
    # 国际版
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    GOOGLE = "google"


# ==================== 模型配置 ====================

MODEL_CONFIG = {
    # 默认对话层 - 高频聊天 (80% 请求)
    "deepseek-v3.2": {
        "provider": ModelProvider.DEEPSEEK,
        "tier": ModelTier.DEFAULT,
        "context_window": 128000,
        "output_tokens": 8192,
        "cost_per_1k_input": 0.0005,
        "cost_per_1k_output": 0.002,
        "strengths": ["日常聊天", "快速回答", "成本优先"],
        "weaknesses": ["复杂推理", "长文本生成"],
        "fallback": "minimax-m2",
    },
    
    # 内容生成层 - 节气/食疗 (15% 请求)
    "glm-4.6": {
        "provider": ModelProvider.GLM,
        "tier": ModelTier.CONTENT,
        "context_window": 128000,
        "output_tokens": 8192,
        "cost_per_1k_input": 0.001,
        "cost_per_1k_output": 0.005,
        "strengths": ["内容生成", "节气养生", "食疗推荐"],
        "weaknesses": ["复杂推理"],
        "fallback": "deepseek-v3.2",
    },
    
    # 深度分析层 - 周报/月报 (5% 请求)
    "qwen3-235b": {
        "provider": ModelProvider.QWEN,
        "tier": ModelTier.DEEP,
        "context_window": 200000,
        "output_tokens": 16384,
        "cost_per_1k_input": 0.008,
        "cost_per_1k_output": 0.04,
        "strengths": ["深度分析", "周报月报", "复杂推理"],
        "weaknesses": ["成本高", "响应较慢"],
        "fallback": "kimi-k2-thinking",
    },
    
    # 复杂Agent层 - 多skill调用
    "kimi-k2-thinking": {
        "provider": ModelProvider.KIMI,
        "tier": ModelTier.AGENT,
        "context_window": 200000,
        "output_tokens": 32000,
        "cost_per_1k_input": 0.01,
        "cost_per_1k_output": 0.05,
        "strengths": ["复杂推理", "多步任务", "长上下文"],
        "weaknesses": ["成本高"],
        "fallback": "glm-4.6",
    },
    
    # 后台任务层 - 批量生成
    "minimax-m2": {
        "provider": ModelProvider.MINIMAX,
        "tier": ModelTier.BACKGROUND,
        "context_window": 100000,
        "output_tokens": 8192,
        "cost_per_1k_input": 0.0003,
        "cost_per_1k_output": 0.001,
        "strengths": ["批量处理", "低成本", "高吞吐量"],
        "weaknesses": ["质量一般"],
        "fallback": "deepseek-v3.2",
    },

    # ===== 国际版模型 (SEASONS) =====
    "gpt-5.4": {
        "provider": ModelProvider.OPENAI,
        "tier": ModelTier.DEFAULT,
        "context_window": 200000,
        "output_tokens": 16384,
        "cost_per_1k_input": 0.002,
        "cost_per_1k_output": 0.01,
        "strengths": ["日常对话", "通用推理"],
        "weaknesses": ["成本中等"],
        "fallback": "gemini-3-flash",
    },
    "claude-sonnet-4.6": {
        "provider": ModelProvider.ANTHROPIC,
        "tier": ModelTier.CONTENT,
        "context_window": 200000,
        "output_tokens": 16384,
        "cost_per_1k_input": 0.003,
        "cost_per_1k_output": 0.015,
        "strengths": ["情绪支持", "自然表达", "内容生成"],
        "weaknesses": ["成本较高"],
        "fallback": "gpt-5.4",
    },
    "claude-opus-4.6": {
        "provider": ModelProvider.ANTHROPIC,
        "tier": ModelTier.DEEP,
        "context_window": 200000,
        "output_tokens": 32000,
        "cost_per_1k_input": 0.015,
        "cost_per_1k_output": 0.075,
        "strengths": ["深度分析", "复杂推理"],
        "weaknesses": ["成本高"],
        "fallback": "claude-sonnet-4.6",
    },
    "gemini-3-pro": {
        "provider": ModelProvider.GOOGLE,
        "tier": ModelTier.CONTENT,
        "context_window": 1000000,
        "output_tokens": 16384,
        "cost_per_1k_input": 0.00125,
        "cost_per_1k_output": 0.005,
        "strengths": ["超长上下文", "多模态", "节气分析"],
        "weaknesses": ["中文养生素养一般"],
        "fallback": "gpt-5.4",
    },
    "gemini-3-flash": {
        "provider": ModelProvider.GOOGLE,
        "tier": ModelTier.BACKGROUND,
        "context_window": 1000000,
        "output_tokens": 8192,
        "cost_per_1k_input": 0.000075,
        "cost_per_1k_output": 0.0003,
        "strengths": ["超低成本", "快速响应", "批量任务"],
        "weaknesses": ["质量一般"],
        "fallback": "deepseek-v3.2",
    },
}


# ==================== API 与模型映射 ====================

API_MODEL_MAP = {
    # 普通聊天
    "/chat/send": {
        "default_model": "deepseek-v3.2",
        "premium_model": "glm-4.6",
        "complexity": "simple",
    },
    
    # 今日节律
    "/daily-plan/generate": {
        "default_model": "deepseek-v3.2",
        "premium_model": "glm-4.6",
        "complexity": "medium",
    },
    
    # Skill执行
    "/skill/run": {
        "skill_models": {
            "solar_term_guide": "glm-4.6",
            "food_tea_recommender": "glm-4.6",
            "sleep_winddown": "glm-4.6",
            "emotion_support": "glm-4.6",
            "exercise_recommender": "glm-4.6",
            "acupoint_guide": "glm-4.6",
            "constitution_analysis": "kimi-k2-thinking",
            "family_care": "kimi-k2-thinking",
        },
    },
    
    # 周报
    "/weekly-report": {
        "default_model": "qwen3-235b",
        "premium_model": "kimi-k2-thinking",
        "complexity": "high",
    },
    
    # 月报
    "/monthly-report": {
        "default_model": "qwen3-235b",
        "premium_model": "kimi-k2-thinking",
        "complexity": "high",
    },
    
    # 家庭摘要
    "/family/digest": {
        "default_model": "kimi-k2-thinking",
        "complexity": "high",
    },
    
    # 情绪支持
    "/emotion/support": {
        "default_model": "glm-4.6",
        "complexity": "medium",
    },
    
    # 跟进生成
    "/followup/generate": {
        "default_model": "minimax-m2",
        "complexity": "simple",
    },
    
    # 内容生成 - 食疗/节气
    "/content/generate": {
        "default_model": "glm-4.6",
        "complexity": "medium",
    },
}


# ==================== 用户等级配置 ====================

class UserTier(str, Enum):
    """用户等级"""
    FREE = "free"       # 免费用户
    PREMIUM = "premium" # 会员
    FAMILY = "family"   # 家庭套餐


USER_TIER_MODELS = {
    UserTier.FREE: [
        "deepseek-v3.2",
        "minimax-m2",
    ],
    UserTier.PREMIUM: [
        "deepseek-v3.2",
        "glm-4.6",
        "qwen3-235b",
        "kimi-k2-thinking",
    ],
    UserTier.FAMILY: [
        "deepseek-v3.2",
        "glm-4.6",
        "qwen3-235b",
        "kimi-k2-thinking",
        "minimax-m2",
    ],
}


# ==================== 成本配置 ====================

COST_BUDGET = {
    "daily": {
        "requests": 300000,  # 30万请求/天
        "budget_usd": 200,   # $200/天
    },
    "distribution": {
        ModelTier.DEFAULT: 0.80,    # 80% 请求
        ModelTier.CONTENT: 0.15,    # 15% 请求
        ModelTier.DEEP: 0.03,       # 3% 请求
        ModelTier.AGENT: 0.02,      # 2% 请求
    },
}


# ==================== 数据模型 ====================

class RoutingContext(BaseModel):
    """路由上下文"""
    user_id: str
    user_tier: UserTier = UserTier.FREE
    api_path: str
    skill_name: Optional[str] = None
    prompt: str
    context_length: int = 0
    is_premium_feature: bool = False
    priority: str = "normal"  # normal, high, low


class ModelSelectionResult(BaseModel):
    """模型选择结果"""
    selected_model: str
    fallback_model: str
    reasoning: str
    tier: ModelTier
    estimated_cost: float = 0.0
    cacheable: bool = False


class AIRouterConfig(BaseModel):
    """AI Router 配置"""
    enable_cache: bool = True
    enable_audit: bool = True
    enable_fallback: bool = True
    cache_ttl_hours: int = 24
    max_retries: int = 3
    timeout_seconds: int = 60
