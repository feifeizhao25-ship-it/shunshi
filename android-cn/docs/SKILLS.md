# SKILLS.md - 顺时中国版 内置 Skills 开发者指南

## 概述

顺时不建立大规模静态内容库，专业养生内容通过 **Skills + 大模型** 动态生成。

每个 Skill 是独立的功能模块，通过 `BaseSkill` 抽象类定义，由 AI Router 统一调度。

---

## Skill 基类

```python
class BaseSkill(ABC):
    code: str           # 唯一标识，如 "sleep_wind_down"
    name: str            # 中文名称，如 "睡前放松"
    category: SkillCategory  # WELLNESS / EMOTION / DAILY / FAMILY / SYSTEM
    description: str     # 功能描述
    is_premium: bool    # 是否需要 Premium 订阅

    async def execute(self, params: InputSchema) -> OutputSchema:
        ...

    def get_caching_strategy(self) -> str:
        return "none" | "short" | "medium" | "long"
```

### 输出 Schema

```json
{
  "text": "共情+建议文本",
  "tone": "warm" | "calm" | "gentle",
  "care_status": "good" | "watching" | "concerned",
  "safety_flag": false,
  "cards": [
    {
      "type": "breathing" | "food" | "acupoint" | "exercise" | "tea",
      "title": "卡片标题",
      "subtitle": "副标题",
      "steps": ["步骤1", "步骤2"],
      "duration_min": 5,
      "contraindications": [],
      "media": [],
      "cta": ["查看详情"]
    }
  ],
  "follow_up": ["跟进问题1", "跟进问题2"]
}
```

---

## 12 个内置 Skills

### 1. DailyRhythmPlan（每日节律计划）

| 字段 | 值 |
|------|-----|
| Code | `daily_rhythm_plan` |
| Category | DAILY |
| Premium | ❌ 免费 |
| 缓存策略 | `short`（1小时）|

**功能：** 根据用户今日状态、节气、习惯，生成个性化每日生活节律建议。

**触发示例：**
- "今天有什么建议"
- "今日计划"
- App 每日首次打开时自动调用

**输入上下文：**
```python
{
  "user_id": "usr_abc123",
  "life_stage": "stressed",
  "today_status": {"mood": "calm", "energy": "medium"},
  "solar_term": {"name": "惊蛰", "date_range": "3月5日-3月19日"},
  "habits": ["早起", "午睡"]
}
```

**输出示例：**
```json
{
  "text": "惊蛰时节，早睡早起有助于阳气生发。今天状态不错，可以试试轻度运动。",
  "cards": [],
  "follow_up": ["今天感觉怎么样？"]
}
```

---

### 2. MoodFirstAid（情绪急救）

| 字段 | 值 |
|------|-----|
| Code | `mood_first_aid` |
| Category | EMOTION |
| Premium | ❌ 免费 |
| 缓存策略 | `none` |

**功能：** 提供情绪支持，分析情绪状态，给出微小行动建议。

**触发示例：**
- "心情不好"
- "最近很焦虑"
- "压力大"

**安全逻辑：**
```python
HIGH_RISK_EMOTIONS = ["绝望", "自杀", "自残", "崩溃"]

def is_high_risk(emotion: str, intensity: int) -> bool:
    return emotion in HIGH_RISK_EMOTIONS or intensity >= 9
```

**高风险时：** 触发 SafeMode，返回危机帮助资源，不生成任何建议。

**输出示例：**
```json
{
  "text": "听起来你最近压力很大，这种感受很正常。给自己一个拥抱，先深呼吸一下？",
  "cards": [],
  "follow_up": ["有什么具体的事情让你烦心吗？"]
}
```

---

### 3. SleepWindDown（睡前放松）

| 字段 | 值 |
|------|-----|
| Code | `sleep_wind_down` |
| Category | WELLNESS |
| Premium | ❌ 免费 |
| 缓存策略 | `none` |

**功能：** 根据用户睡眠困扰，提供个性化睡前放松建议、呼吸法、或音频。

**触发示例：**
- "睡不着"
- "睡眠不好"
- "失眠"

**输出示例：**
```json
{
  "text": "春分时节肝气旺，容易影响睡眠。试试这个放松流程：",
  "cards": [
    {
      "type": "breathing",
      "title": "4-7-8 呼吸法",
      "subtitle": "帮助入睡的经典呼吸练习",
      "steps": ["用鼻子吸气4秒", "屏住呼吸7秒", "用嘴呼气8秒", "重复3-4次"],
      "duration_min": 5,
      "contraindications": ["严重呼吸系统疾病患者"]
    }
  ],
  "follow_up": ["今天经历了什么让你难以入睡？"]
}
```

---

### 4. OfficeMicroBreak（办公室微休息）

| 字段 | 值 |
|------|-----|
| Code | `office_micro_break` |
| Category | WELLNESS |
| Premium | ❌ 免费 |
| 缓存策略 | `short` |

**功能：** 在工作间隙提供短暂休息建议，适合久坐办公人群。

**触发示例：**
- "工作累了"
- "办公室休息"
- "眼睛酸"

---

### 5. SolarTermGuide（节气指南）

| 字段 | 值 |
|------|-----|
| Code | `solar_term_guide` |
| Category | WELLNESS |
| Premium | ❌ 免费 |
| 缓存策略 | `long`（缓存到下一个节气） |

**功能：** 提供当前节气的养生建议，结合用户体质。

**触发示例：**
- "惊蛰有什么养生建议"
- "春分怎么养"

**输出示例：**
```json
{
  "text": "惊蛰 | 3月5日-3月19日\n\n春雷始鸣，惊醒蛰虫。此时肝气旺盛，宜早睡早起，多食清淡。",
  "cards": [
    {
      "type": "food",
      "title": "推荐食物",
      "subtitle": "惊蛰宜清淡",
      "steps": ["菠菜豆腐汤", "枸杞菊花茶", "山药粥"]
    },
    {
      "type": "exercise",
      "title": "推荐运动",
      "subtitle": "舒肝理气",
      "steps": ["八段锦", "散步", "太极拳"]
    }
  ],
  "follow_up": ["你想了解哪方面的养生建议？"]
}
```

---

### 6. BodyConstitutionLite（体质轻测）

| 字段 | 值 |
|------|-----|
| Code | `body_constitution_lite` |
| Category | WELLNESS |
| Premium | ✅ 需要 Premium |

**功能：** 9种体质快速测试，根据用户回答判断体质类型并给出建议。

**九种体质：** 气虚质、阳虚质、阴虚质、痰湿质、湿热质、血瘀质、气郁质、特禀质、平和质

**测试流程：**
1. 询问 3-5 个关键症状问题
2. 根据回答判断体质
3. 返回体质报告卡片

---

### 7. FoodTeaRecommender（食疗茶饮推荐）

| 字段 | 值 |
|------|-----|
| Code | `food_tea_recommender` |
| Category | WELLNESS |
| Premium | ❌ 免费 |

**功能：** 根据用户当前状态、季节、体质，推荐食疗菜谱和茶饮。

**触发示例：**
- "推荐养生菜"
- "春天喝什么茶"
- "气虚吃什么"

---

### 8. AcupressureRoutineLite（穴位保健）

| 字段 | 值 |
|------|-----|
| Code | `acupressure_routine_lite` |
| Category | WELLNESS |
| Premium | ❌ 免费 |

**功能：** 提供穴位按摩建议，包括穴位位置、按摩手法、功效说明。

**穴位示例：** 足三里、三阴交、合谷、太冲、百会、涌泉

---

### 9. FollowUpGenerator（跟进生成器）

| 字段 | 值 |
|------|-----|
| Code | `follow_up_generator` |
| Category | SYSTEM |
| Premium | ❌ 免费 |

**功能：** 在用户沉默或长时间未使用 App 时，主动生成轻量跟进消息。

**策略：**
- 轻量关心，不追问
- 可轻易忽略
- 不造成依赖感

---

### 10. PresencePolicyDecider（存在感策略决定）

| 字段 | 值 |
|------|-----|
| Code | `presence_policy_decider` |
| Category | SYSTEM |
| Premium | ❌ 免费 |
| 缓存策略 | `long` |

**功能：** 根据用户互动频率和偏好，决定 AI 的主动联系频率。

---

### 11. CareStatusUpdater（照护状态更新）

| 字段 | 值 |
|------|-----|
| Code | `care_status_updater` |
| Category | SYSTEM |
| Premium | ❌ 免费 |

**功能：** 根据用户近期对话内容，更新照护状态标签。

**状态值：** `good` / `watching` / `concerned`

---

### 12. FamilyCareDigest（家庭关怀摘要）

| 字段 | 值 |
|------|-----|
| Code | `family_care_digest` |
| Category | FAMILY |
| Premium | ✅ 需要 Premium（家庭计划） |

**功能：** 为家庭账号生成各成员关怀动态摘要。

**触发示例：**
- "家庭动态"
- "看看爸妈的状态"

---

## Skill 注册表

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
                "is_premium": s.is_premium,
                "caching_strategy": s.get_caching_strategy()
            }
            for s in cls._skills.values()
        ]

# 注册
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

## Skill 缓存策略

| 策略 | 有效期 | 适用场景 |
|------|--------|---------|
| `none` | 不缓存 | 实时性强的响应（对话、情绪） |
| `short` | 1小时 | 日计划、休息建议 |
| `medium` | 1天 | 体质相关建议 |
| `long` | 到下一节气 | 节气内容（15天左右） |

---

## 新增 Skill 流程

1. 在 `backend/app/ai/skills/` 下创建新 Skill 类，继承 `BaseSkill`
2. 实现 `execute()` 方法
3. 在 `registry.py` 中注册
4. 在 `intent_detector.py` 中添加路由规则
5. 添加对应测试用例
