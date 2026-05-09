# 顺时 ShunShi AI Router 架构

## 架构总览

```
用户请求
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      AI Router                               │
├─────────────────────────────────────────────────────────────┤
│  1. Request Parsing      - 解析请求                          │
│  2. User Context Building - 构建用户上下文                   │
│  3. Intent Detection     - 意图识别                         │
│  4. Skill Routing        - Skill 路由                       │
│  5. Prompt Building      - Prompt 构造                       │
│  6. Model Routing        - 模型选择                          │
│  7. Safety Guard         - 安全检查                          │
│  8. Schema Validation    - 输出校验                          │
│  9. Response Repair      - 响应修复                          │
│ 10. Cache Layer          - 缓存层                            │
│ 11. FollowUp Scheduling  - 跟进计划                          │
│ 12. Presence Policy      - 存在感策略                        │
│ 13. Care Status Updating - 照护状态更新                       │
│ 14. Audit Logging        - 审计日志                          │
│ 15. Metrics Reporting    - 指标上报                          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   小模型     │   │   大模型     │   │   Skills    │
│   (7B)      │   │   (72B)      │   │   Engine    │
└──────────────┘   └──────────────┘   └──────────────┘
```

---

## 核心文件结构

### AI Router 主逻辑

```python
# ai/router/router.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import json

router = APIRouter(prefix="/ai", tags=["ai"])

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    user_id: str
    stream: bool = False

class ChatResponse(BaseModel):
    text: str
    tone: str
    care_status: str
    presence_level: str
    offline_encouraged: bool
    safety_flag: bool
    cards: List[dict]
    follow_up: List[str]
    meta: dict

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    # 1. 解析请求
    parsed = await request_parser.parse(request)
    
    # 2. 构建用户上下文
    context = await context_builder.build(request.user_id)
    
    # 3. 意图识别
    intent = await intent_detector.detect(parsed.message, context)
    
    # 4. Skill 路由
    skill = await skill_selector.select(intent, context)
    
    # 5. Prompt 构造
    prompt = await prompt_builder.build(intent, skill, context)
    
    # 6. 模型选择
    model = await model_selector.select(intent, skill, context)
    
    # 7. 安全检查
    await safety_guard.check(prompt, context)
    
    # 8. 调用模型
    response = await llm_client.generate(prompt, model)
    
    # 9. Schema 校验
    validated = await schema_validator.validate(response)
    
    # 10. 响应修复
    repaired = await response_repair.fix(validated)
    
    # 11. 缓存
    await cache_layer.set(request, repaired)
    
    # 12. 跟进计划
    if repaired.get("follow_up"):
        await follow_up_scheduler.schedule(
            user_id=request.user_id,
            conversation_id=request.conversation_id,
            follow_ups=repaired["follow_up"]
        )
    
    # 13. Presence 策略
    await presence_policy.update(request.user_id, repaired)
    
    # 14. 照护状态更新
    await care_status_updater.update(request.user_id, repaired)
    
    # 15. 审计日志
    await audit_logger.log(request, repaired)
    
    return repaired
```

---

## 模块详解

### 1. Intent Detection (意图识别)

```python
# ai/router/intent_detector.py
from enum import Enum

class IntentType(Enum):
    # 主要意图
    CHAT = "chat"                    # 闲聊
    SLEEP = "sleep"                  # 睡眠相关
    EMOTION = "emotion"              # 情绪支持
    FOOD = "food"                    # 食疗
    TEA = "tea"                      # 茶饮
    ACUPOINT = "acupoint"             # 穴位
    SOLAR_TERM = "solar_term"        # 节气
    CONSTITUTION = "constitution"    # 体质
    HABIT = "habit"                  # 习惯
    DAILY_PLAN = "daily_plan"        # 每日计划
    FAMILY = "family"                # 家庭
    FOLLOW_UP = "follow_up"          # 跟进回复
    
    # 特殊意图
    SAFE_MODE = "safe_mode"          # 安全模式
    QUIT = "quit"                    # 结束对话

class Intent:
    type: IntentType
    confidence: float
    entities: dict
    context_needed: bool

class IntentDetector:
    async def detect(self, message: str, context: dict) -> Intent:
        # 使用小模型进行意图识别
        prompt = f"""
判断用户消息的意图。
消息: {message}
上下文: {context}

可选意图: {list(IntentType)}
        
返回JSON格式:
{{
    "type": "意图类型",
    "confidence": 0.0-1.0,
    "entities": {{}},
    "context_needed": true/false
}}
"""
        result = await self.llm.generate(prompt)
        return Intent(**json.loads(result))
```

### 2. Skill Selector (Skill 路由)

```python
# ai/router/skill_selector.py
class SkillSelector:
    SKILL_INTENT_MAP = {
        "sleep": "sleep_wind_down",
        "emotion": "mood_first_aid",
        "food": "food_tea_recommender",
        "tea": "food_tea_recommender",
        "acupoint": "acupressure_routine_lite",
        "solar_term": "solar_term_guide",
        "constitution": "body_constitution_lite",
        "daily_plan": "daily_rhythm_plan",
        "family": "family_care_digest",
    }
    
    async def select(self, intent: Intent, context: dict) -> Optional[str]:
        skill_code = self.SKILL_INTENT_MAP.get(intent.type.value)
        
        # 检查用户是否有权限使用该 Skill
        if skill_code:
            is_premium = await self.check_premium(skill_code, context["user_id"])
            if is_premium or not self.skill_service.is_premium(skill_code):
                return skill_code
        
        # 默认使用通用对话
        return None
```

### 3. Model Selector (模型选择)

```python
# ai/router/model_selector.py
from enum import Enum

class ModelType(Enum):
    SMALL = "small"      # 7B 模型 - 快速、便宜
    LARGE = "large"     # 72B 模型 - 深度、精准
    
class ModelSelector:
    # 70% 请求用小模型，30% 用大模型
    SMALL_RATIO = 0.7
    
    async def select(self, intent: Intent, skill: Optional[str], context: dict) -> ModelType:
        # 强制使用大模型的场景
        if intent.type in [IntentType.EMOTION, IntentType.SAFE_MODE]:
            return ModelType.LARGE
        
        if skill in ["mood_first_aid", "body_constitution_lite"]:
            return ModelType.LARGE
        
        # 检查用户订阅级别
        if context.get("is_premium"):
            return ModelType.LARGE
        
        # 根据负载和成本动态选择
        if await self.should_use_large_model():
            return ModelType.LARGE
        
        # 默认使用小模型
        return ModelType.SMALL
    
    async def should_use_large_model(self) -> bool:
        # 检查当前负载
        # 检查成本配额
        return random.random() > self.SMALL_RATIO
```

### 4. Safety Guard (安全检查)

```python
# ai/router/safety_guard.py
class SafetyLevel(Enum):
    NORMAL = "normal"
    WARNING = "warning"
    SAFE_MODE = "safe_mode"

class SafetyGuard:
    DANGER_KEYWORDS = [
        "自杀", "自残", "抑郁", "绝望", 
        "去医院", "看医生", "心理咨询"
    ]
    
    HIGH_RISK_KEYWORDS = [
        "不想活了", "活着没意思", "太累了不想坚持"
    ]
    
    async def check(self, prompt: str, context: dict) -> SafetyLevel:
        message = prompt.lower()
        
        # 高风险关键词检测
        for keyword in self.HIGH_RISK_KEYWORDS:
            if keyword in message:
                return SafetyLevel.SAFE_MODE
        
        # 危险关键词检测
        for keyword in self.DANGER_KEYWORDS:
            if keyword in message:
                return SafetyLevel.WARNING
        
        return SafetyLevel.NORMAL
    
    async def apply(self, level: SafetyLevel, response: dict, context: dict) -> dict:
        if level == SafetyLevel.SAFE_MODE:
            # 触发 SafeMode
            response["safety_flag"] = True
            response["text"] = SAFE_MODE_PROMPT
            response["cards"] = []
            response["follow_up"] = []
            
        elif level == SafetyLevel.WARNING:
            # 添加温馨提示
            response["text"] += "\n\n💡 温馨提示：如果感到不适，建议咨询专业人士。"
        
        return response
```

### 5. Schema Validator (输出校验)

```python
# ai/router/schema_validator.py
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Any
from enum import Enum

class ToneEnum(str, Enum):
    WARM = "warm"
    CALM = "calm"
    CHEERFUL = "cheerful"
    PROFESSIONAL = "professional"

class CareStatusEnum(str, Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    CONCERNED = "concerned"
    NEEDS_ATTENTION = "needs_attention"

class PresenceLevelEnum(str, Enum):
    NORMAL = "normal"
    REDUCED = "reduced"
    SILENT = "silent"

class CardTypeEnum(str, Enum):
    ACUPOINT = "acupoint"
    FOOD = "food"
    TEA = "tea"
    MOVEMENT = "movement"
    BREATHING = "breathing"
    SLEEP = "sleep"
    SOLAR_TERM = "solar_term"
    NOTE = "note"

class AIResponse(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    tone: ToneEnum = ToneEnum.WARM
    care_status: CareStatusEnum = CareStatusEnum.GOOD
    presence_level: PresenceLevelEnum = PresenceLevelEnum.NORMAL
    offline_encouraged: bool = False
    safety_flag: bool = False
    cards: List[dict] = Field(default_factory=list)
    follow_up: List[str] = Field(default_factory=list)
    meta: dict = Field(default_factory=dict)
    
    @validator("text")
    def text_not_empty(cls, v):
        if not v.strip():
            raise ValueError("Text cannot be empty")
        return v.strip()

class SchemaValidator:
    async def validate(self, response: str) -> AIResponse:
        try:
            # 尝试解析 JSON
            data = json.loads(response)
            return AIResponse(**data)
        except json.JSONDecodeError:
            # 非 JSON 响应，包装为通用回复
            return self.repair_non_json(response)
        except Exception as e:
            # Schema 验证失败，尝试修复
            return self.repair_invalid(response, e)
    
    async def repair_non_json(self, response: str) -> AIResponse:
        # 提取可能的 JSON
        json_match = re.search(r'\{.*\}', response, re.DOTALL)
        if json_match:
            try:
                return AIResponse(**json.loads(json_match.group()))
            except:
                pass
        
        # 无法修复，返回安全的默认响应
        return AIResponse(
            text=response[:500],
            safety_flag=True
        )
```

---

## 统一 JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ShunShi AI Response",
  "type": "object",
  "required": ["text", "tone", "care_status", "presence_level"],
  "properties": {
    "text": {
      "type": "string",
      "minLength": 1,
      "maxLength": 2000,
      "description": "AI 回复的文本内容"
    },
    "tone": {
      "type": "string",
      "enum": ["warm", "calm", "cheerful", "professional"],
      "default": "warm",
      "description": "回复的语气"
    },
    "care_status": {
      "type": "string",
      "enum": ["excellent", "good", "concerned", "needs_attention"],
      "default": "good",
      "description": "用户照护状态"
    },
    "presence_level": {
      "type": "string",
      "enum": ["normal", "reduced", "silent"],
      "default": "normal",
      "description": "AI 存在感级别"
    },
    "offline_encouraged": {
      "type": "boolean",
      "default": false,
      "description": "是否鼓励用户离线"
    },
    "safety_flag": {
      "type": "boolean",
      "default": false,
      "description": "是否触发安全模式"
    },
    "cards": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "title"],
        "properties": {
          "type": {
            "type": "string",
            "enum": ["acupoint", "food", "tea", "movement", "breathing", "sleep", "solar_term", "note"]
          },
          "title": {"type": "string"},
          "subtitle": {"type": "string"},
          "steps": {"type": "array", "items": {"type": "string"}},
          "duration_min": {"type": "integer"},
          "contraindications": {"type": "array", "items": {"type": "string"}},
          "media": {"type": "array"},
          "cta": {"type": "array", "items": {"type": "string"}}
        }
      },
      "default": []
    },
    "follow_up": {
      "type": "array",
      "items": {"type": "string"},
      "default": []
    },
    "meta": {
      "type": "object",
      "default": {},
      "description": "元数据"
    }
  }
}
```

---

## API 接口

### POST /chat/send

```python
# Request
{
    "message": "最近睡眠不好，总是失眠",
    "conversation_id": "可选",
    "user_id": "用户ID",
    "stream": false
}

# Response
{
    "text": "听起来你最近休息不太好...",
    "tone": "warm",
    "care_status": "concerned",
    "presence_level": "normal",
    "offline_encouraged": false,
    "safety_flag": false,
    "cards": [
        {
            "type": "sleep",
            "title": "睡前放松建议",
            "steps": ["深呼吸", "温水泡脚", "听轻音乐"],
            "duration_min": 30
        }
    ],
    "follow_up": ["今天感觉怎么样", "有什么心事吗"],
    "meta": {
        "intent": "sleep",
        "skill": "sleep_wind_down",
        "model": "small",
        "latency_ms": 1234
    }
}
```

### POST /daily-plan/generate

```python
# Request
{
    "user_id": "用户ID",
    "date": "2026-03-08"
}

# Response
{
    "date": "2026-03-08",
    "greeting": "早上好",
    "solar_term": "惊蛰",
    "insight": "今日宜清淡饮食",
    "three_things": [
        "喝一杯温水",
        "午休20分钟",
        "睡前泡脚"
    ],
    "habits": [
        {"id": "1", "name": "喝水", "completed": false},
        {"id": "2", "name": "散步", "completed": false}
    ],
    "ai_care": "记得照顾好自己"
}
```

### POST /skill/run

```python
# Request
{
    "skill_code": "sleep_wind_down",
    "user_id": "用户ID",
    "params": {
        "sleep_quality": "poor",
        "trouble": "难以入睡"
    }
}

# Response
{
    "skill_code": "sleep_wind_down",
    "output": {
        "text": "给你几个帮助入睡的小建议...",
        "cards": [...],
        "follow_up": [...]
    },
    "cached": false,
    "duration_ms": 567
}
```
