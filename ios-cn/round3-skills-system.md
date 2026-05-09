# 顺时 ShunShi Skills 系统

## Skills 架构

顺时不建立大规模静态内容库，专业内容通过 Skills + 大模型动态生成。

---

## Skill 基类

```python
# ai/skills/base.py
from abc import ABC, abstractmethod
from pydantic import BaseModel
from typing import Optional, Dict, Any
from enum import Enum

class SkillCategory(str, Enum):
    WELLNESS = "wellness"        # 养生
    EMOTION = "emotion"          # 情绪
    DAILY = "daily"              # 日常
    FAMILY = "family"            # 家庭
    SYSTEM = "system"            # 系统

class InputSchema(BaseModel):
    user_id: str
    context: Dict[str, Any] = {}
    
class OutputSchema(BaseModel):
    text: str
    cards: list = []
    follow_up: list = []
    care_status: str = "good"

class BaseSkill(ABC):
    code: str
    name: str
    category: SkillCategory
    description: str
    is_premium: bool = False
    
    @abstractmethod
    async def execute(self, params: InputSchema) -> OutputSchema:
        pass
    
    def get_prompt(self, version: str = "latest") -> str:
        """获取 Skill Prompt"""
        pass
    
    def validate_input(self, data: dict) -> InputSchema:
        """验证输入"""
        pass
    
    def get_caching_strategy(self) -> str:
        """获取缓存策略: none / short / medium / long"""
        return "none"
```

---

## 12 个内置 Skills

### 1. DailyRhythmPlan (每日节律计划)

```python
class DailyRhythmPlanSkill(BaseSkill):
    code = "daily_rhythm_plan"
    name = "每日节律计划"
    category = SkillCategory.DAILY
    description = "生成用户今日的生活节律建议"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        # 获取用户上下文
        user_context = await self.get_user_context(params.user_id)
        
        # 获取当前节气
        solar_term = await self.get_current_solar_term()
        
        # 获取用户习惯
        habits = await self.get_user_habits(params.user_id)
        
        # 构建 Prompt
        prompt = f"""
你是顺时 AI，擅长根据用户情况和节气生成每日生活建议。

用户信息：
- 生命周期阶段：{user_context.life_stage}
- 今日状态：{user_context.today_status}
- 当前节气：{solar_term.name} ({solar_term.date_range})
- 用户习惯：{habits}

请生成今日节律计划，包含：
1. 一句问候
2. 今日洞察 (insight)
3. 今日三件事
4. 习惯打卡列表
5. 一句 AI 关怀

要求：
- 语言简洁、温和
- 建议要小、具体、可执行
- 不给复杂的长清单
- 根据生命周期调整重点

返回 JSON 格式：
{{
    "text": "问候语+洞察",
    "cards": [],
    "follow_up": []
}}
"""
        result = await self.llm.generate(prompt)
        return OutputSchema(**json.loads(result))
    
    def get_caching_strategy(self) -> str:
        return "short"  # 缓存 1 小时
```

### 2. MoodFirstAid (情绪急救)

```python
class MoodFirstAidSkill(BaseSkill):
    code = "mood_first_aid"
    name = "情绪急救"
    category = SkillCategory.EMOTION
    description = "提供情绪支持和建议"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        # 分析情绪
        emotion = params.context.get("emotion", "unknown")
        intensity = params.context.get("intensity", 5)
        
        # 检查是否需要 SafeMode
        if self.is_high_risk(emotion, intensity):
            return self.trigger_safe_mode()
        
        # 生成共情回复
        prompt = f"""
你是顺时 AI，一个温和、耐心的生活朋友。

用户说：{params.context.get('message', '')}

请先共情理解用户情绪，然后提供一个微小的行动建议。

原则：
- 先共情
- 再理解
- 后建议
- 最后给一个小行动
- 不把用户定义为某种"问题人格"
- 不说"你一直在……"
- 不说"你就是……"
- 只说观察，不说判断

返回 JSON 格式：
{{
    "text": "共情+建议",
    "cards": [],
    "follow_up": ["关心的问题"]
}}
"""
        result = await self.llm.generate(prompt, model="large")
        return OutputSchema(**json.loads(result))
    
    def is_high_risk(self, emotion: str, intensity: int) -> bool:
        high_risk_emotions = ["绝望", "自杀", "自残", "崩溃"]
        return emotion in high_risk_emotions or intensity >= 9
```

### 3. SleepWindDown (睡前放松)

```python
class SleepWindDownSkill(BaseSkill):
    code = "sleep_wind_down"
    name = "睡前放松"
    category = SkillCategory.WELLNESS
    description = "提供睡前放松建议"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        sleep_quality = params.context.get("sleep_quality", "normal")
        trouble = params.context.get("trouble", "")
        
        prompt = f"""
用户提供以下睡眠信息：
- 睡眠质量：{sleep_quality}
- 困扰：{trouble}

请提供睡前放松建议，包含：
1. 简短共情
2. 放松步骤卡片（3-5个）
3. 一个小行动

返回 JSON 格式：
{{
    "text": "共情+简短建议",
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
        result = await self.llm.generate(prompt)
        return OutputSchema(**json.loads(result))
```

### 4. OfficeMicroBreak (办公室微休息)

```python
class OfficeMicroBreakSkill(BaseSkill):
    code = "office_micro_break"
    name = "办公室微休息"
    category = SkillCategory.WELLNESS
    description = "提供办公室环境下的短暂休息建议"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        work_type = params.context.get("work_type", "desk")
        available_time = params.context.get("available_time", 5)
        
        # ... 实现
        pass
```

### 5. SolarTermGuide (节气指南)

```python
class SolarTermGuideSkill(BaseSkill):
    code = "solar_term_guide"
    name = "节气指南"
    category = SkillCategory.WELLNESS
    description = "提供当前节气的养生建议"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        current = await self.get_current_solar_term()
        user_constitution = await self.get_user_constitution(params.user_id)
        
        prompt = f"""
当前节气：{current.name}
日期范围：{current.start_date} - {current.end_date}
用户体质：{user_constitution}

请提供：
1. 节气简介（一句话）
2. 今日养生建议
3. 饮食建议卡片
4. 运动建议卡片

返回 JSON 格式：
{{
    "text": "节气介绍+建议",
    "cards": [
        {{
            "type": "food",
            "title": "推荐食物",
            "subtitle": "适合当前节气",
            "steps": ["做法1", "做法2"]
        }}
    ],
    "follow_up": []
}}
"""
        result = await self.llm.generate(prompt)
        return OutputSchema(**json.loads(result))
    
    def get_caching_strategy(self) -> str:
        return "long"  # 缓存到下一个节气
```

### 6. BodyConstitutionLite (体质轻测)

```python
class BodyConstitutionLiteSkill(BaseSkill):
    code = "body_constitution_lite"
    name = "体质轻测"
    category = SkillCategory.WELLNESS
    description = "九种体质快速测试与建议"
    is_premium = True
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        # 根据用户选择的症状判断体质
        symptoms = params.context.get("symptoms", [])
        
        # 输出体质结果卡片
        # ...
        pass
```

### 7. FoodTeaRecommender (食疗茶饮推荐)

```python
class FoodTeaRecommenderSkill(BaseSkill):
    code = "food_tea_recommender"
    name = "食疗茶饮推荐"
    category = SkillCategory.WELLNESS
    description = "根据用户情况推荐食疗和茶饮"
    is_premium = False
```

### 8. AcupressureRoutineLite (穴位保健)

```python
class AcupressureRoutineLiteSkill(BaseSkill):
    code = "acupressure_routine_lite"
    name = "穴位保健"
    category = SkillCategory.WELLNESS
    description = "提供穴位按摩建议"
    is_premium = False
```

### 9. FollowUpGenerator (跟进生成器)

```python
class FollowUpGeneratorSkill(BaseSkill):
    code = "follow_up_generator"
    name = "跟进生成器"
    category = SkillCategory.SYSTEM
    description = "生成跟进消息"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        last_topic = params.context.get("last_topic", "")
        days_since = params.context.get("days_since", 1)
        user_preference = params.context.get("user_preference", {})
        
        prompt = f"""
上次对话主题：{last_topic}
距离上次对话：{days_since} 天
用户偏好：{user_preference}

请生成一条轻量的跟进消息：
- 不要长
- 不要追问
- 可以是关心、提醒、分享
- 用户可以轻易忽略

返回 JSON 格式：
{{
    "text": "跟进消息",
    "cards": [],
    "follow_up": []
}}
"""
        result = await self.llm.generate(prompt)
        return OutputSchema(**json.loads(result))
```

### 10. PresencePolicyDecider (存在感策略决定)

```python
class PresencePolicyDeciderSkill(BaseSkill):
    code = "presence_policy_decider"
    name = "存在感策略"
    category = SkillCategory.SYSTEM
    description = "决定 AI 的主动联系频率"
    is_premium = False
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        # 分析用户互动频率
        # 检查用户设置
        # 决定存在感级别
        pass
    
    def get_caching_strategy(self) -> str:
        return "long"
```

### 11. CareStatusUpdater (照护状态更新)

```python
class CareStatusUpdaterSkill(BaseSkill):
    code = "care_status_updater"
    name = "照护状态更新"
    category = SkillCategory.SYSTEM
    description = "更新用户照护状态"
    is_premium = False
```

### 12. FamilyCareDigest (家庭关怀摘要)

```python
class FamilyCareDigestSkill(BaseSkill):
    code = "family_care_digest"
    name = "家庭关怀摘要"
    category = SkillCategory.FAMILY
    description = "生成家庭成员关怀动态"
    is_premium = True
    
    async def execute(self, params: InputSchema) -> OutputSchema:
        family_id = params.context.get("family_id")
        family_members = await self.get_family_members(family_id)
        
        # 生成关怀摘要
        pass
```

---

## Skills 注册表

```python
# ai/skills/registry.py
class SkillRegistry:
    _skills: Dict[str, BaseSkill] = {}
    
    @classmethod
    def register(cls, skill: BaseSkill):
        cls._skills[skill.code] = skill
    
    @classmethod
    def get(cls, code: str) -> BaseSkill:
        return cls._skills.get(code)
    
    @classmethod
    def list_all(cls) -> List[dict]:
        return [
            {
                "code": s.code,
                "name": s.name,
                "category": s.category.value,
                "description": s.description,
                "is_premium": s.is_premium,
                "caching_strategy": s.get_caching_strategy()
            }
            for s in cls._skills.values()
        ]
    
    @classmethod
    def get_by_category(cls, category: SkillCategory) -> List[BaseSkill]:
        return [s for s in cls._skills.values() if s.category == category]

# 注册所有 Skills
SkillRegistry.register(DailyRhythmPlanSkill())
SkillRegistry.register(MoodFirstAidSkill())
SkillRegistry.register(SleepWindDownSkill())
SkillRegistry.register(OfficeMicroBreakSkill())
SkillRegistry.register(SolarTermGuideSkill())
SkillRegistry.register(BodyConstitutionLiteSkill())
SkillRegistry.register(FoodTeaRecommenderSkill())
SkillRegistry.register(AcupressureRoutineLiteSkill())
SkillRegistry.register(FollowUpGeneratorSkill())
SkillRegistry.register(PresencePolicyDeciderSkill())
SkillRegistry.register(CareStatusUpdaterSkill())
SkillRegistry.register(FamilyCareDigestSkill())
```

---

## Skill 输出 Schema

```json
{
  "skill_code": "sleep_wind_down",
  "output": {
    "text": "睡前放松建议...",
    "tone": "warm",
    "care_status": "good",
    "cards": [
      {
        "type": "breathing",
        "title": "4-7-8 呼吸法",
        "subtitle": "帮助放松入睡",
        "steps": [
          "用鼻子吸气 4 秒",
          "屏住呼吸 7 秒",
          "用嘴呼气 8 秒",
          "重复 3-4 次"
        ],
        "duration_min": 5,
        "contraindications": [],
        "media": [],
        "cta": ["查看穴位图"]
      }
    ],
    "follow_up": [
      "今天感觉怎么样",
      "有什么心事可以聊聊"
    ]
  },
  "cached": false,
  "duration_ms": 1234
}
```
