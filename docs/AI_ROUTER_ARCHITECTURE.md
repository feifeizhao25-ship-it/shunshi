# 顺时 AI Router 完整代码架构

> 顺时真正的大脑中枢：稳定 × 可控 × 可扩展

---

## 一、AI Router 职责定义

| # | 职责 | 说明 |
|---|------|------|
| 1 | 请求接收 | 聊天/今日计划/Skills/Follow-up |
| 2 | 用户上下文组装 | isPremium/life_stage/quiet_hours/care_status |
| 3 | Prompt 组合 | Core + Policy + Task + Skill |
| 4 | 模型路由 | 7B 免费 / 72B 付费关键节点 |
| 5 | 安全检查 | 医疗/用药/体检/高风险情绪 |
| 6 | Schema 校验 | JSON Schema 验证 |
| 7 | 结果缓存 | 节省 token 成本 |
| 8 | 日志与评测 | prompt_version/model/latency/tokens |

---

## 二、总体架构

```
Flutter App
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│                         API Gateway                              │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AI Router                                  │
├─────────────────────────────────────────────────────────────────┤
│  Request Parser → Context Builder → Intent Detector             │
│  Skill Router → Prompt Builder → Model Router                   │
│  Safety Guard → Schema Validator → Cache Manager                │
│  Response Repair → Audit Logger → Metrics                       │
└─────────────────────────────────────────────────────────────────┘
     │
     ▼
Structured Response
```

---

## 三、项目目录结构

```
shunshi-ai-router/
├── app/
│   ├── main.py                 # FastAPI 入口
│   ├── config.py               # 配置
│   └── constants.py            # 常量
│
├── api/routes/
│   ├── chat.py                 # /chat/send
│   ├── daily_plan.py           # /daily-plan/generate
│   ├── skill.py                # /skill/run
│   └── health.py               # /health
│
├── core/
│   ├── request_parser.py       # 请求解析
│   ├── context_builder.py      # 上下文组装
│   ├── intent_detector.py      # 意图识别
│   ├── skill_router.py         # Skill 路由
│   ├── prompt_builder.py       # Prompt 组合
│   ├── prompt_registry.py      # Prompt 注册表
│   ├── model_router.py          # 模型路由
│   ├── safety_guard.py         # 安全检查
│   ├── schema_validator.py     # Schema 校验
│   ├── response_repair.py       # 响应修复
│   ├── cache_manager.py         # 缓存管理
│   ├── followup_engine.py       # 跟进引擎
│   ├── presence_policy.py       # 退让策略
│   ├── care_status_engine.py   # 照护状态机
│   ├── audit_logger.py          # 审计日志
│   └── metrics.py               # 指标收集
│
├── models/
│   ├── request_models.py        # 请求模型
│   └── response_models.py       # 响应模型
│
├── providers/
│   ├── qwen_provider.py        # 通义千问
│   ├── openai_provider.py       # OpenAI
│   └── mock_provider.py         # 测试用
│
├── skills/
│   ├── base.py                  # Skill 基类
│   ├── daily_rhythm.py         # 今日节律
│   ├── mood_first_aid.py       # 情绪急救
│   ├── sleep_winddown.py       # 睡前仪式
│   ├── solar_term_guide.py     # 节气指南
│   └── food_tea_recommender.py # 食疗茶饮
│
├── prompts/
│   ├── core.py                  # Core Prompt
│   ├── policy.py                # Policy Prompt
│   └── task.py                  # Task Prompt
│
└── deploy/
    ├── Dockerfile
    └── docker-compose.yml
```

---

## 四、核心 API

### 4.1 聊天接口

```python
# api/routes/chat.py
from fastapi import APIRouter, Depends
from app.models.request_models import ChatRequest
from app.models.response_models import ChatResponse, ShunShiResponse
from app.core.intent_detector import IntentDetector
from app.core.skill_router import SkillRouter
from app.core.prompt_builder import PromptBuilder
from app.core.model_router import ModelRouter
from app.core.safety_guard import SafetyGuard
from app.core.schema_validator import SchemaValidator
from app.core.cache_manager import CacheManager
from app.core.audit_logger import AuditLogger

router = APIRouter(prefix="/chat", tags=["chat"])

@router.post("/send", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    """发送聊天消息"""
    
    # 1. 安全检查
    safety_result = await SafetyGuard.check(request.message)
    if safety_result.blocked:
        return await build_safe_mode_response(safety_result)
    
    # 2. 意图识别
    intent = await IntentDetector.detect(request.message)
    
    # 3. Skill 路由
    skill = await SkillRouter.route(intent)
    
    # 4. 构建 Prompt
    prompt = await PromptBuilder.build(
        core=request.prompt_version.core,
        policy=request.prompt_version.policy,
        task=skill.task_prompt,
        context=request.context,
    )
    
    # 5. 模型路由
    model = await ModelRouter.select(intent, request.context)
    
    # 6. 缓存检查
    cache_key = CacheManager.build_key(skill.name, request)
    cached = await CacheManager.get(cache_key)
    if cached:
        return cached
    
    # 7. 调用 LLM
    response = await model.complete(prompt)
    
    # 8. Schema 校验
    validated = await SchemaValidator.validate(response)
    
    # 9. 记录日志
    await AuditLogger.log(request, validated, model.name)
    
    # 10. 返回
    return validated
```

### 4.2 Skill 接口

```python
# api/routes/skill.py
from fastapi import APIRouter, HTTPException
from app.models.request_models import SkillRequest

router = APIRouter(prefix="/skill", tags=["skill"])

SKILL_REGISTRY = {
    "DailyRhythmPlan": DailyRhythmSkill,
    "MoodFirstAid": MoodFirstAidSkill,
    "SleepWindDown": SleepWindDownSkill,
    "SolarTermGuide": SolarTermGuideSkill,
    "FoodTeaRecommender": FoodTeaRecommenderSkill,
}

@router.post("/run")
async def run_skill(request: SkillRequest):
    """运行指定 Skill"""
    skill_class = SKILL_REGISTRY.get(request.skill)
    if not skill_class:
        raise HTTPException(status_code=404, detail="Skill not found")
    
    skill = skill_class()
    result = await skill.execute(request)
    return result
```

### 4.3 健康检查

```python
# api/routes/health.py
from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["health"])

@router.get("")
async def health_check():
    """健康检查"""
    return {
        "status": "ok",
        "router": "healthy",
        "redis": await check_redis(),
        "db": await check_db(),
    }
```

---

## 五、请求/响应模型

### 5.1 请求模型

```python
# models/request_models.py
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from enum import Enum


class LifeStage(str, Enum):
    EXPLORATION = "exploration"
    STRESS = "stress"
    HEALTH = "health"
    COMPANIONSHIP = "companionship"


class UserContext(BaseModel):
    is_premium: bool = False
    life_stage: LifeStage = LifeStage.EXPLORATION
    memory_enabled: bool = True
    proactive_enabled: bool = True
    quiet_hours: Dict[str, str] = {"start": "23:00", "end": "07:00"}
    preferences: Dict[str, str] = {}
    constraints: Dict[str, Any] = {}


class ChatRequest(BaseModel):
    user_id: str
    message: str
    context: UserContext
    signals: Optional[Dict] = None
    prompt_version: Dict[str, str] = {}


class SkillRequest(BaseModel):
    skill: str
    user_id: str
    user_context: UserContext
    task_params: Dict[str, Any] = {}
```

### 5.2 响应模型

```python
# models/response_models.py
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from enum import Enum


class Tone(str, Enum):
    GENTLE = "gentle"
    NEUTRAL = "neutral"
    CHEERFUL = "cheerful"
    CALM = "calm"


class CareStatus(str, Enum):
    STABLE = "stable"
    NEEDS_ATTENTION = "needs_attention"
    ESCALATE = "escalate"


class PresenceLevel(str, Enum):
    NORMAL = "normal"
    REDUCED = "reduced"
    SILENT = "silent"


class SafetyFlag(str, Enum):
    NONE = "none"
    SENSITIVE = "sensitive"
    ABNORMAL = "abnormal"


class ShunShiResponse(BaseModel):
    text: str
    tone: Tone = Tone.GENTLE
    care_status: CareStatus = CareStatus.STABLE
    presence_level: PresenceLevel = PresenceLevel.NORMAL
    offline_encouraged: bool = False
    safety_flag: SafetyFlag = SafetyFlag.NONE
    cards: Optional[List[Dict]] = None
    follow_up: Optional[Dict] = None
    meta: Dict[str, Any]
```

---

## 六、核心模块实现

### 6.1 Intent Detector

```python
# core/intent_detector.py
class IntentDetector:
    """意图识别器"""
    
    PATTERNS = {
        "sleep": ["睡不着", "失眠", "sleep", "睡前"],
        "emotion": ["烦", "焦虑", "压力", "emotion", "情绪"],
        "solar_term": ["节气", "立春", "惊蛰", "solar"],
        "food_tea": ["吃", "喝", "食疗", "茶饮"],
        "acupressure": ["穴位", "按揉", "acupoint"],
        "medical": ["药", "血压", "血糖", "体检", "medical", "诊断"],
    }
    
    @classmethod
    async def detect(cls, message: str) -> str:
        message_lower = message.lower()
        
        # 医疗相关优先
        if any(p in message_lower for p in cls.PATTERNS["medical"]):
            return "medical_risk"
        
        for intent, patterns in cls.PATTERNS.items():
            if intent != "medical" and any(p in message_lower for p in patterns):
                return intent
        
        return "chat"
```

### 6.2 Model Router

```python
# core/model_router.py
class ModelRouter:
    """模型路由器 - 成本控制核心"""
    
    CRITICAL_TASKS = {"daily_plan", "solar_term", "constitution"}
    LARGE_MODEL = "qwen-max"
    SMALL_MODEL = "qwen-turbo"
    
    @classmethod
    async def select(cls, intent: str, context) -> dict:
        # 免费用户默认小模型
        if not context.is_premium:
            return {"provider": "qwen", "model": cls.SMALL_MODEL, "is_cheap": True}
        
        # 关键任务用大模型
        if intent in cls.CRITICAL_TASKS:
            return {"provider": "qwen", "model": cls.LARGE_MODEL, "is_cheap": False}
        
        # 30%概率用大模型
        import random
        use_large = random.random() < 0.3
        
        return {
            "provider": "qwen",
            "model": cls.LARGE_MODEL if use_large else cls.SMALL_MODEL,
            "is_cheap": not use_large
        }
```

### 6.3 Safety Guard

```python
# core/safety_guard.py
class SafetyGuard:
    """安全守卫"""
    
    MEDICAL_KEYWORDS = ["药", "血压", "血糖", "体检", "诊断", "治疗"]
    EXTREME_KEYWORDS = ["自杀", "轻生", "抑郁", "绝望", "撑不住"]
    
    @classmethod
    async def check(cls, message: str) -> dict:
        message_lower = message.lower()
        
        # 极端情绪
        for keyword in cls.EXTREME_KEYWORDS:
            if keyword in message_lower:
                return {
                    "blocked": False,
                    "flag": "abnormal",
                    "reason": f"extreme_emotion:{keyword}"
                }
        
        # 医疗相关
        if any(k in message_lower for k in cls.MEDICAL_KEYWORDS):
            return {"blocked": False, "flag": "sensitive", "reason": "medical"}
        
        return {"blocked": False, "flag": "none"}
```

### 6.4 Cache Manager

```python
# core/cache_manager.py
import redis.asyncio as redis
import json
import hashlib

class CacheManager:
    """缓存管理器"""
    
    CACHEABLE = {
        "DailyRhythmPlan": 86400,
        "SolarTermGuide": 604800,
        "SleepWindDown": 604800,
        "FoodTeaRecommender": 2592000,
    }
    
    @classmethod
    def build_key(cls, skill: str, request) -> str:
        parts = [f"skill:{skill}"]
        if hasattr(request, "user_id"):
            parts.append(f"user:{request.user_id}")
        return ":".join(parts)
    
    @classmethod
    async def get(cls, key: str) -> Optional[dict]:
        # 从 Redis 获取
        pass
    
    @classmethod
    async def set(cls, key: str, value: dict, ttl: int):
        # 写入 Redis
        pass
    
    @classmethod
    async def should_cache(cls, skill: str) -> bool:
        return skill in cls.CACHEABLE
```

### 6.5 Schema Validator

```python
# core/schema_validator.py
import json

class SchemaValidator:
    """Schema 校验器"""
    
    REQUIRED = ["text", "tone", "care_status", "presence_level", "safety_flag", "meta"]
    
    @classmethod
    async def validate(cls, raw_response: str) -> dict:
        try:
            data = json.loads(raw_response)
        except:
            data = await cls.repair_json(raw_response)
        
        # 校验必填字段
        for field in cls.REQUIRED:
            if field not in data:
                raise ValueError(f"Missing: {field}")
        
        return data
    
    @classmethod
    async def repair_json(cls, text: str) -> dict:
        # 移除 markdown，尝试修复
        text = text.strip()
        if text.startswith("```"):
            text = text.split("```")[1]
        try:
            return json.loads(text)
        except:
            return {
                "text": text[:500],
                "tone": "gentle",
                "care_status": "stable",
                "presence_level": "normal",
                "safety_flag": "none",
                "meta": {"repair_count": 1}
            }
```

---

## 七、Prompt 注册表

```python
# core/prompt_registry.py
class PromptRegistry:
    """Prompt 注册表"""
    
    PROMPTS = {
        "SS_CORE_ALL_v1.0": """
你是顺时，一个 AI 养生陪伴助手。
用户信息：人生阶段 {life_stage}，是否付费 {is_premium}

原则：
1. 记住用户之前说过的话
2. 主动关心用户状态
3. 回答简洁温暖
4. 知道什么时候不打扰
5. 永远不给出医疗诊断或药物建议
        """,
        
        "SS_POLICY_PREMIUM_v1.0": "尊享版：详细建议、深度记忆、优先响应",
        
        "SS_POLICY_FREE_v1.0": "免费版：基础陪伴、简化建议",
        
        "SS_TASK_CHAT_v1.0": "日常聊天，温暖回应，不超过150字",
        
        "SS_TASK_SLEEP_v1.0": "睡眠咨询，实用的睡眠建议，不给药物建议",
        
        "SS_TASK_EMOTION_v1.0": "情绪支持，先共情再给建议，不评判不诊断",
        
        "SS_TASK_SAFE_v1.0": "安全模式，建议咨询专业医生，不给具体建议",
    }
    
    @classmethod
    def get(cls, key: str) -> str:
        return cls.PROMPTS.get(key, "")
```

---

## 八、成本控制策略

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI 成本控制三板斧                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 小模型优先 (70% 请求)                                       │
│     • 免费用户：默认 7B                                        │
│     • 付费用户：闲聊走 7B                                      │
│                                                                 │
│  2. 大模型只用于关键节点 (30% 请求)                             │
│     • 今日计划生成                                             │
│     • 节气总结                                                  │
│     • 复杂养生咨询                                             │
│                                                                 │
│  3. 缓存结果                                                   │
│     • 节气指南：7天                                            │
│     • 睡前仪式：7天                                            │
│     • 食疗推荐：30天                                           │
│                                                                 │
│  目标：单请求成本 < ¥0.001                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 九、灰度与回滚

```python
# core/feature_flags.py
class FeatureFlags:
    """特性开关 - 支持灰度与回滚"""
    
    FLAGS = {
        "new_prompt_v2": {" rollout": 0.05, "enabled": True },
        "use_large_model": {" rollout": 0.3, "enabled": True },
        "aggressive_followup": {" rollout": 0.0, "enabled": False },
    }
    
    @classmethod
    def is_enabled(cls, flag: str, user_id: str = None) -> bool:
        if flag not in cls.FLAGS:
            return False
        
        config = cls.FLAGS[flag]
        if not config["enabled"]:
            return False
        
        # 简单灰度：用户ID哈希
        if user_id:
            user_hash = hash(user_id) % 100
            return user_hash < (config["rollout"] * 100)
        
        return True
    
    @classmethod
    def rollback(cls, flag: str):
        """回滚"""
        if flag in cls.FLAGS:
            cls.FLAGS[flag]["enabled"] = False
            cls.FLAGS[flag]["rollout"] = 0
```

---

## 十、可观测性指标

```
┌─────────────────────────────────────────────────────────────────┐
│                    必须监控的指标                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  性能指标：                                                     │
│  • API 延迟 P50/P95/P99                                       │
│  • LLM 延迟                                                    │
│  • Redis 命中率                                                │
│  • DB 查询时间                                                 │
│                                                                 │
│  AI 质量指标：                                                 │
│  • Schema 校验通过率                                           │
│  • Safety Flag 触发率                                          │
│  • 平均评分                                                    │
│  • Repair 次数                                                 │
│                                                                 │
│  商业指标：                                                     │
│  • Premium 使用量                                               │
│  • 转化率                                                      │
│  • Follow-up 打开率                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 总结

```
AI Router = 意图识别 + Skill路由 + Prompt组合 + 模型选择 + 安全守卫 + 
           Schema校验 + 缓存管理 + 日志审计

稳定 = 完善的错误处理 + 灰度回滚 + 监控告警
可控 = 小模型优先 + 大模型关键节点 + 缓存命中
可扩展 = 模块化设计 + Feature Flags + 多 Provider 支持
```

---

## 已完成文档

| # | 文档 | 内容 |
|---|------|------|
| 1 | LIFE_STAGE_ENGINE | Life Stage Engine |
| 2 | ULTIMATE_FEATURE_MAP | 万亿产品功能地图 |
| 3 | TECHNICAL_ARCHITECTURE | 万亿级技术架构 |
| 4 | UI_SYSTEM | 1亿用户级 UI |
| 5 | SKILLS_SYSTEM | Skills 体系设计 |
| 6 | SKILLS_IMPLEMENTATION | Skills 实施规格 |
| 7 | AI_TEST_ITERATION | 10轮测试体系 |
| 8 | AI_EVALUATION_SYSTEM | 自动化测试系统 |
| 9 | AI_ROUTER_ARCHITECTURE | AI Router 代码架构 |

---

## 顺时万亿产品全系列（已完成）

| 模块 | 状态 |
|------|------|
| Life Stage Engine | ✅ |
| Ultimate Feature Map (10年) | ✅ |
| Technical Architecture | ✅ |
| UI System | ✅ |
| Skills System | ✅ |
| Skills Implementation | ✅ |
| AI Test Iteration | ✅ |
| AI Evaluation System | ✅ |
| AI Router Architecture | ✅ |

---

**顺时已从一个 AI 聊天 App 进化为：**

- 生命周期系统
- 家庭系统
- 技能系统
- AI Router
- 测试系统
- 订阅系统
- 节律系统

**这才是真正有可能走向万亿的产品结构。**
