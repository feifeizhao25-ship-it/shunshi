# 顺时 ShunShi AI Router/后端专用开发提示词

你是世界级 Python 后端架构师、FastAPI 专家、AI Router 设计者、PostgreSQL 数据库架构师。

你的任务是为「顺时 ShunShi」生成完整的、可直接开发的后端代码结构。

---

## 一、项目配置

### 1.1 pyproject.toml

```toml
[project]
name = "shunshi-backend"
version = "1.0.0"
description = "顺时后端API服务"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "sqlalchemy>=2.0.0",
    "asyncpg>=0.29.0",
    "redis>=5.0.0",
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "python-jose[cryptography]>=3.3.0",
    "passlib[bcrypt]>=1.7.4",
    "python-multipart>=0.0.6",
    "httpx>=0.25.0",
    "openai>=1.3.0",
    "anthropic>=0.18.0",
    "alibabacloud-oss-python-sdk>=2.0.0",
    "sentry-sdk[fastapi]>=1.39.0",
    "prometheus-client>=0.19.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.25.0",
    "ruff>=0.1.0",
    "mypy>=1.7.0",
]

[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.build_meta"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

### 1.2 目录结构

```
shunshi_backend/
├── app/
│   ├── __init__.py
│   ├── main.py                      # FastAPI 入口
│   ├── config.py                    # 配置
│   ├── constants.py                 # 常量
│   │
│   ├── api/                         # API 路由
│   │   ├── v1/
│   │   │   ├── router.py
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── chat/
│   │   │   ├── wellness/
│   │   │   ├── family/
│   │   │   ├── subscription/
│   │   │   └── health.py
│   │   └── dependencies.py
│   │
│   ├── core/                       # 核心功能
│   │   ├── security/
│   │   ├── database/
│   │   ├── cache/
│   │   └── storage/
│   │
│   ├── models/                    # SQLAlchemy 模型
│   │   ├── user.py
│   │   ├── conversation.py
│   │   ├── message.py
│   │   ├── memory.py
│   │   └── ...
│   │
│   ├── schemas/                   # Pydantic Schema
│   │
│   ├── services/                  # 业务服务
│   │   ├── auth_service.py
│   │   ├── user_service.py
│   │   ├── chat_service.py
│   │   └── ...
│   │
│   ├── ai/                        # AI 核心
│   │   ├── router/
│   │   ├── llm/
│   │   ├── skills/
│   │   └── prompts/
│   │
│   └── utils/
│
├── scripts/
├── tests/
├── docker/
├── pyproject.toml
├── requirements.txt
└── .env.example
```

---

## 二、配置管理

### 2.1 config.py

```python
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # 环境
    ENV: str = "development"
    DEBUG: bool = True
    
    # 数据库
    DATABASE_URL: str = "postgresql://postgres:password@localhost:5432/shunshi"
    DATABASE_POOL_SIZE: int = 20
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # JWT
    JWT_SECRET: str = "your-secret-key"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    
    # LLM
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    SMALL_MODEL_URL: str = "http://localhost:8000/v1"
    
    # 阿里云
    ALIYUN_ACCESS_KEY_ID: str = ""
    ALIYUN_ACCESS_KEY_SECRET: str = ""
    OSS_BUCKET: str = "shunshi"
    
    # 监控
    SENTRY_DSN: str = ""
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
```

---

## 三、数据库模型

### 3.1 User 模型

```python
# app/models/user.py
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid
import enum


class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone = Column(String(20), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_login_at = Column(DateTime(timezone=True))
    status = Column(String(20), default="active")
    is_premium = Column(Boolean, default=False)
    premium_expires_at = Column(DateTime(timezone=True))
    registration_source = Column(String(50))
    metadata = Column(JSONB, default={})
    
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    settings = relationship("UserSettings", back_populates="user", uselist=False)
    conversations = relationship("Conversation", back_populates="user")


class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True)
    nickname = Column(String(100))
    avatar_url = Column(Text)
    gender = Column(String(10))
    birth_date = Column(DateTime)
    life_stage = Column(String(20))  # exploring, stressed, healthy, companion
    bio = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="profile")


class UserSettings(Base):
    __tablename__ = "user_settings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True)
    language = Column(String(10), default="zh_CN")
    theme = Column(String(20), default="light")
    memory_enabled = Column(Boolean, default=True)
    presence_level = Column(String(20), default="normal")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="settings")
```

### 3.2 Conversation 模型

```python
# app/models/conversation.py
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Integer, JSONB
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(255))
    type = Column(String(20), default="chat")
    last_message_at = Column(DateTime(timezone=True), index=True)
    last_ai_response = Column(JSONB)
    message_count = Column(Integer, default=0)
    is_archived = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation")


class Message(Base):
    __tablename__ = "conversation_messages"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id"), index=True)
    role = Column(String(20), nullable=False)
    content = Column(Text, nullable=False)
    content_type = Column(String(20), default="text")
    metadata = Column(JSON})
    safety_flag = Column(Boolean,B, default={ default=False)
    model_used = Column(String(50))
    skill_code = Column(String(50))
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    
    conversation = relationship("Conversation", back_populates="messages")
```

---

## 四、API 接口实现

### 4.1 主入口

```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.router import api_router
from app.core.database import init_db
from app.core.cache import init_redis
import sentry_sdk

sentry_sdk.init(dsn="")

app = FastAPI(
    title="顺时 API",
    description="顺时 AI 生活节律系统后端",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    await init_db()
    await init_redis()


@app.get("/")
async def root():
    return {"message": "欢迎使用顺时 API"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


app.include_router(api_router, prefix="/api/v1")
```

### 4.2 认证接口

```python
# app/api/v1/auth/endpoints.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import create_access_token
from app.api.v1.auth.schemas import LoginRequest, LoginResponse, RegisterRequest
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=LoginResponse)
async def register(request: RegisterRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    
    existing = await service.get_user_by_phone(request.phone)
    if existing:
        raise HTTPException(status_code=400, detail="手机号已注册")
    
    user = await service.create_user(phone=request.phone, nickname=request.nickname)
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return LoginResponse(
        user_id=str(user.id),
        access_token=access_token,
        token_type="bearer"
    )


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    service = AuthService(db)
    
    user = await service.verify_credentials(request.phone, request.verify_code)
    if not user:
        raise HTTPException(status_code=401, detail="验证码错误")
    
    await service.update_last_login(user.id)
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return LoginResponse(
        user_id=str(user.id),
        access_token=access_token,
        token_type="bearer",
        is_premium=user.is_premium
    )
```

### 4.3 对话接口

```python
# app/api/v1/chat/endpoints.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.v1.auth.dependencies import get_current_user
from app.api.v1.chat.schemas import ChatRequest, ChatResponse
from app.services.chat_service import ChatService
from app.models.user import User

router = APIRouter()


@router.post("/send", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = ChatService(db)
    response = await service.process_message(
        user_id=str(current_user.id),
        message=request.message,
        conversation_id=request.conversation_id
    )
    return response


@router.get("/conversations")
async def get_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = 20,
    offset: int = 0
):
    service = ChatService(db)
    conversations = await service.get_conversations(
        user_id=str(current_user.id),
        limit=limit,
        offset=offset
    )
    return {"conversations": conversations}
```

---

## 五、AI Router 实现

### 5.1 Router 主逻辑

```python
# app/ai/router/router.py
from typing import Optional
import json
from app.ai.router.intent_detector import IntentDetector, IntentType
from app.ai.router.skill_selector import SkillSelector
from app.ai.router.model_selector import ModelSelector, ModelType
from app.ai.router.prompt_builder import PromptBuilder
from app.ai.router.safety_guard import SafetyGuard, SafetyLevel
from app.ai.router.schema_validator import SchemaValidator
from app.ai.router.cache_layer import CacheLayer
from app.ai.llm import LLMClient


class AIRouter:
    def __init__(self):
        self.intent_detector = IntentDetector()
        self.skill_selector = SkillSelector()
        self.model_selector = ModelSelector()
        self.prompt_builder = PromptBuilder()
        self.safety_guard = SafetyGuard()
        self.schema_validator = SchemaValidator()
        self.cache_layer = CacheLayer()
        self.llm_client = LLMClient()
    
    async def process(self, user_id: str, message: str, conversation_id: Optional[str] = None) -> dict:
        # 1. 获取用户上下文
        user_context = await self._get_user_context(user_id)
        
        # 2. 意图识别
        intent = await self.intent_detector.detect(message, user_context)
        
        # 3. Skill 路由
        skill = await self.skill_selector.select(intent, user_context)
        
        # 4. Prompt 构造
        prompt = await self.prompt_builder.build(intent, skill, user_context)
        
        # 5. 模型选择
        model = await self.model_selector.select(intent, skill, user_context)
        
        # 6. 安全检查
        safety_level = await self.safety_guard.check(prompt, user_context)
        
        # 7. 检查缓存
        cache_key = f"{user_id}:{hash(message)}"
        cached = await self.cache_layer.get(cache_key)
        if cached:
            return cached
        
        # 8. 调用模型
        response = await self.llm_client.generate(prompt, model)
        
        # 9. Schema 校验
        validated = await self.schema_validator.validate(response)
        
        # 10. 应用安全策略
        if safety_level != SafetyLevel.NORMAL:
            validated = await self.safety_guard.apply(safety_level, validated, user_context)
        
        # 11. 缓存
        await self.cache_layer.set(cache_key, validated)
        
        return validated
    
    async def _get_user_context(self, user_id: str) -> dict:
        # 从数据库获取用户上下文
        from app.services.user_service import UserService
        service = UserService(None)  # 需要注入
        user = await service.get_by_id(user_id)
        profile = await service.get_profile(user_id)
        settings = await service.get_settings(user_id)
        
        return {
            "user": user,
            "profile": profile,
            "settings": settings,
            "life_stage": profile.life_stage if profile else "exploring"
        }
```

### 5.2 Intent Detector

```python
# app/ai/router/intent_detector.py
from enum import Enum
from typing import Optional


class IntentType(str, Enum):
    CHAT = "chat"
    SLEEP = "sleep"
    EMOTION = "emotion"
    FOOD = "food"
    TEA = "tea"
    ACUPOINT = "acupoint"
    SOLAR_TERM = "solar_term"
    CONSTITUTION = "constitution"
    HABIT = "habit"
    FAMILY = "family"
    SAFE_MODE = "safe_mode"


class Intent:
    def __init__(self, type: IntentType, confidence: float, entities: dict = None):
        self.type = type
        self.confidence = confidence
        self.entities = entities or {}


class IntentDetector:
    KEYWORD_MAP = {
        IntentType.SLEEP: ["睡眠", "失眠", "入睡", "睡觉"],
        IntentType.EMOTION: ["心情", "烦", "焦虑", "压力", "累", "难过"],
        IntentType.FOOD: ["食疗", "吃的", "养生菜"],
        IntentType.TEA: ["喝茶", "茶饮", "普洱"],
        IntentType.ACUPOINT: ["穴位", "按摩"],
        IntentType.SOLAR_TERM: ["节气", "惊蛰", "春分"],
        IntentType.CONSTITUTION: ["体质", "阳虚", "阴虚"],
        IntentType.HABIT: ["习惯", "打卡"],
        IntentType.FAMILY: ["家庭", "爸妈", "家人"],
    }
    
    async def detect(self, message: str, context: dict) -> Intent:
        message_lower = message.lower()
        
        for intent_type, keywords in self.KEYWORD_MAP.items():
            for keyword in keywords:
                if keyword in message_lower:
                    return Intent(type=intent_type, confidence=0.8, entities={"keyword": keyword})
        
        return Intent(type=IntentType.CHAT, confidence=0.5)
```

### 5.3 Safety Guard

```python
# app/ai/router/safety_guard.py
from enum import Enum


class SafetyLevel(str, Enum):
    NORMAL = "normal"
    WARNING = "warning"
    SAFE_MODE = "safe_mode"


SAFE_MODE_RESPONSE = {
    "text": "谢谢你的信任。能感觉到你现在很不容易。如果有困扰，建议联系专业人士。",
    "tone": "warm",
    "care_status": "needs_attention",
    "presence_level": "reduced",
    "offline_encouraged": True,
    "safety_flag": True,
    "cards": [],
    "follow_up": []
}


class SafetyGuard:
    HIGH_RISK = ["自杀", "自残", "不想活", "活着没意思"]
    WARNING = ["抑郁", "心理医生", "去医院"]
    
    async def check(self, prompt: str, context: dict) -> SafetyLevel:
        msg = prompt.lower()
        
        for keyword in self.HIGH_RISK:
            if keyword in msg:
                return SafetyLevel.SAFE_MODE
        
        for keyword in self.WARNING:
            if keyword in msg:
                return SafetyLevel.WARNING
        
        return SafetyLevel.NORMAL
    
    async def apply(self, level: SafetyLevel, response: dict, context: dict) -> dict:
        if level == SafetyLevel.SAFE_MODE:
            return SAFE_MODE_RESPONSE.copy()
        
        if level == SafetyLevel.WARNING:
            response["text"] += "\n\n💡 温馨提示：如果感到不适，建议咨询专业人士。"
            response["safety_flag"] = True
        
        return response
```

---

## 六、Skills 实现

### 6.1 Skill 基类

```python
# app/ai/skills/base.py
from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Dict, Any, List
from enum import Enum


class SkillCategory(str, Enum):
    WELLNESS = "wellness"
    EMOTION = "emotion"
    DAILY = "daily"
    FAMILY = "family"
    SYSTEM = "system"


class SkillInput(BaseModel):
    user_id: str
    context: Dict[str, Any] = {}


class SkillOutput(BaseModel):
    text: str
    tone: str = "warm"
    care_status: str = "good"
    cards: List[Dict[str, Any]] = []
    follow_up: List[str] = []


class BaseSkill(ABC):
    code: str = ""
    name: str = ""
    category: SkillCategory = SkillCategory.WELLNESS
    is_premium: bool = False
    
    @abstractmethod
    async def execute(self, input: SkillInput) -> SkillOutput:
        pass
    
    def get_caching_strategy(self) -> str:
        return "none"
```

### 6.2 MoodFirstAid Skill

```python
# app/ai/skills/mood_first_aid.py
from .base import BaseSkill, SkillCategory, SkillInput, SkillOutput
import json


MOOD_PROMPT = """
你是顺时 AI，一个温和、耐心的生活朋友。

用户说：{message}

请先共情理解用户情绪，然后提供一个微小的行动建议。

原则：
- 先共情
- 再理解
- 后建议
- 给一个小行动
- 不说"你一直在……"
- 不说"你就是……"

返回 JSON：
{{
    "text": "共情+建议",
    "cards": [],
    "follow_up": []
}}
"""


class MoodFirstAidSkill(BaseSkill):
    code = "mood_first_aid"
    name = "情绪急救"
    category = SkillCategory.EMOTION
    is_premium = False
    
    def __init__(self, llm_client):
        self.llm_client = llm_client
    
    async def execute(self, input: SkillInput) -> SkillOutput:
        message = input.context.get("message", "")
        
        prompt = MOOD_PROMPT.format(message=message)
        response = await self.llm_client.generate(prompt, model="large")
        
        try:
            data = json.loads(response)
        except:
            data = {"text": response, "cards": [], "follow_up": []}
        
        return SkillOutput(
            text=data.get("text", ""),
            tone="warm",
            care_status="concerned",
            cards=data.get("cards", []),
            follow_up=data.get("follow_up", [])
        )
    
    def get_caching_strategy(self) -> str:
        return "short"
```

### 6.3 SleepWindDown Skill

```python
# app/ai/skills/sleep_wind_down.py
from .base import BaseSkill, SkillCategory, SkillInput, SkillOutput
import json


SLEEP_PROMPT = """
用户提供信息：
- 睡眠质量：{quality}
- 困扰：{trouble}

请提供睡前放松建议，包含：
1. 简短共情
2. 放松步骤卡片
3. 小行动

返回 JSON：
{{
    "text": "共情+建议",
    "cards": [
        {{
            "type": "breathing",
            "title": "4-7-8 呼吸法",
            "steps": ["吸气4秒", "屏息7秒", "呼气8秒"],
            "duration_min": 5
        }}
    ],
    "follow_up": []
}}
"""


class SleepWindDownSkill(BaseSkill):
    code = "sleep_wind_down"
    name = "睡前放松"
    category = SkillCategory.WELLNESS
    is_premium = False
    
    def __init__(self, llm_client):
        self.llm_client = llm_client
    
    async def execute(self, input: SkillInput) -> SkillOutput:
        quality = input.context.get("sleep_quality", "normal")
        trouble = input.context.get("trouble", "")
        
        prompt = SLEEP_PROMPT.format(quality=quality, trouble=trouble)
        response = await self.llm_client.generate(prompt, model="small")
        
        try:
            data = json.loads(response)
        except:
            data = {"text": response, "cards": [], "follow_up": []}
        
        return SkillOutput(
            text=data.get("text", ""),
            tone="calm",
            cards=data.get("cards", []),
            follow_up=data.get("follow_up", [])
        )
    
    def get_caching_strategy(self) -> str:
        return "medium"
```

### 6.4 Skills 注册表

```python
# app/ai/skills/registry.py
from typing import Dict
from .base import BaseSkill
from .mood_first_aid import MoodFirstAidSkill
from .sleep_wind_down import SleepWindDownSkill


class SkillRegistry:
    _skills: Dict[str, BaseSkill] = {}
    _llm_client = None
    
    @classmethod
    def initialize(cls, llm_client):
        cls._llm_client = llm_client
        cls._skills = {
            "mood_first_aid": MoodFirstAidSkill(llm_client),
            "sleep_wind_down": SleepWindDownSkill(llm_client),
            # 添加更多 Skills...
        }
    
    @classmethod
    def get(cls, code: str) -> BaseSkill:
        return cls._skills.get(code)
    
    @classmethod
    def list_all(cls) -> list:
        return [
            {
                "code": s.code,
                "name": s.name,
                "category": s.category.value,
                "is_premium": s.is_premium
            }
            for s in cls._skills.values()
        ]
```

---

## 七、数据库 CRUD 服务

### 7.1 User Service

```python
# app/services/user_service.py
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, UserProfile, UserSettings
import uuid


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.id == uuid.UUID(user_id))
        )
        return result.scalar_one_or_none()
    
    async def get_by_phone(self, phone: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.phone == phone)
        )
        return result.scalar_one_or_none()
    
    async def create(self, phone: str, nickname: str = None) -> User:
        user = User(phone=phone, nickname=nickname)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        
        # 创建默认 profile
        profile = UserProfile(user_id=user.id, nickname=nickname)
        self.db.add(profile)
        
        # 创建默认 settings
        settings = UserSettings(user_id=user.id)
        self.db.add(settings)
        
        await self.db.commit()
        
        return user
    
    async def get_profile(self, user_id: str) -> Optional[UserProfile]:
        result = await self.db.execute(
            select(UserProfile).where(UserProfile.user_id == uuid.UUID(user_id))
        )
        return result.scalar_one_or_none()
    
    async def get_settings(self, user_id: str) -> Optional[UserSettings]:
        result = await self.db.execute(
            select(UserSettings).where(UserSettings.user_id == uuid.UUID(user_id))
        )
        return result.scalar_one_or_none()
    
    async def update_last_login(self, user_id: uuid.UUID):
        from datetime import datetime, timezone
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        if user:
            user.last_login_at = datetime.now(timezone.utc)
            await self.db.commit()
```

### 7.2 Chat Service

```python
# app/services/chat_service.py
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.conversation import Conversation, Message
from app.ai.router.router import AIRouter
import uuid


class ChatService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.ai_router = AIRouter()
    
    async def process_message(
        self,
        user_id: str,
        message: str,
        conversation_id: Optional[str] = None
    ) -> dict:
        # 获取或创建对话
        conv = await self._get_or_create_conversation(user_id, conversation_id)
        
        # 保存用户消息
        user_msg = Message(
            conversation_id=conv.id,
            role="user",
            content=message
        )
        self.db.add(user_msg)
        await self.db.commit()
        
        # AI 处理
        response = await self.ai_router.process(user_id, message, str(conv.id))
        
        # 保存 AI 响应
        ai_msg = Message(
            conversation_id=conv.id,
            role="assistant",
            content=response.get("text", ""),
            metadata=response,
            model_used=response.get("meta", {}).get("model"),
            skill_code=response.get("meta", {}).get("skill")
        )
        self.db.add(ai_msg)
        
        # 更新对话
        conv.message_count += 1
        conv.last_ai_response = response
        
        await self.db.commit()
        
        return response
    
    async def _get_or_create_conversation(
        self,
        user_id: str,
        conversation_id: Optional[str] = None
    ) -> Conversation:
        if conversation_id:
            result = await self.db.execute(
                select(Conversation).where(Conversation.id == uuid.UUID(conversation_id))
            )
            conv = result.scalar_one_or_none()
            if conv:
                return conv
        
        conv = Conversation(
            user_id=uuid.UUID(user_id),
            title="新对话"
        )
        self.db.add(conv)
        await self.db.commit()
        await self.db.refresh(conv)
        return conv
    
    async def get_conversations(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Conversation]:
        result = await self.db.execute(
            select(Conversation)
            .where(Conversation.user_id == uuid.UUID(user_id))
            .order_by(Conversation.last_message_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())
```

---

## 八、核心依赖

### 8.1 Database

```python
# app/core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

Base = declarative_base()

engine = None
async_session_maker = None


async def init_db():
    global engine, async_session_maker
    from app.config import settings
    
    engine = create_async_engine(
        settings.DATABASE_URL,
        pool_size=settings.DATABASE_POOL_SIZE,
        echo=settings.DEBUG,
    )
    
    async_session_maker = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )


async def get_db():
    async with async_session_maker() as session:
        yield session
```

### 8.2 Cache

```python
# app/core/cache.py
import redis.asyncio as redis
from typing import Optional
import json

redis_client = None


async def init_redis():
    global redis_client
    from app.config import settings
    redis_client = await redis.from_url(settings.REDIS_URL, decode_responses=True)


class CacheLayer:
    def __init__(self):
        self.client = redis_client
    
    async def get(self, key: str) -> Optional[dict]:
        data = await self.client.get(key)
        if data:
            return json.loads(data)
        return None
    
    async def set(self, key: str, value: dict, ttl: int = 3600):
        await self.client.setex(key, ttl, json.dumps(value))
    
    async def delete(self, key: str):
        await self.client.delete(key)
```

---

## 九、API Schemas

### 9.1 Auth Schemas

```python
# app/api/v1/auth/schemas.py
from pydantic import BaseModel


class RegisterRequest(BaseModel):
    phone: str
    nickname: str = None
    verify_code: str


class LoginRequest(BaseModel):
    phone: str
    verify_code: str


class LoginResponse(BaseModel):
    user_id: str
    access_token: str
    token_type: str
    is_premium: bool = False
```

### 9.2 Chat Schemas

```python
# app/api/v1/chat/schemas.py
from pydantic import BaseModel
from typing import Optional, List, Dict, Any


class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    stream: bool = False


class ChatResponse(BaseModel):
    text: str
    tone: str = "warm"
    care_status: str = "good"
    presence_level: str = "normal"
    offline_encouraged: bool = False
    safety_flag: bool = False
    cards: List[Dict[str, Any]] = []
    follow_up: List[str] = []
    meta: Dict[str, Any] = {}
```

---

## 十、依赖注入

### 10.1 认证依赖

```python
# app/api/v1/auth/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.config import settings
from app.models.user import User
from app.services.user_service import UserService

security = HTTPBearer()


async def get_current_user(
    credentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    token = credentials.credentials
    
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="无效的token")
    except JWTError:
        raise HTTPException(status_code=401, detail="无效的token")
    
    service = UserService(db)
    user = await service.get_by_id(user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    return user
```
