# 顺时 Skills 体系：可落地实施规格

> 统一 Schema + 12 Skills 完整规格 + 测试 Fixtures + 路由规则

---

## 一、统一 Skill 输出 Schema（ShunShiResponse v1）

### 1.1 完整 JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ShunShiResponse",
  "type": "object",
  "required": ["text", "tone", "care_status", "presence_level", "offline_encouraged", "safety_flag", "meta"],
  "properties": {
    "text": {
      "type": "string",
      "description": "对用户可见的主要文本内容",
      "minLength": 1,
      "maxLength": 500
    },
    "tone": {
      "type": "string",
      "enum": ["gentle", "neutral", "cheerful", "calm", "serious"],
      "description": "回复语气"
    },
    "care_status": {
      "type": "string",
      "enum": ["stable", "needs_attention", "escalate"],
      "description": "内部照护状态，不外显给用户"
    },
    "presence_level": {
      "type": "string",
      "enum": ["normal", "reduced", "silent"],
      "description": "触达级别"
    },
    "offline_encouraged": {
      "type": "boolean",
      "description": "是否鼓励线下/现实连接"
    },
    "safety_flag": {
      "type": "string",
      "enum": ["none", "sensitive", "abnormal"],
      "description": "安全标记"
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
          "title": { "type": "string" },
          "subtitle": { "type": "string" },
          "steps": {
            "type": "array",
            "items": { "type": "string" }
          },
          "duration_min": { "type": "integer", "minimum": 1 },
          "contraindications": {
            "type": "array",
            "items": { "type": "string" }
          },
          "media": {
            "type": "object",
            "properties": {
              "image_id": { "type": ["string", "null"] },
              "video_id": { "type": ["string", "null"] }
            }
          },
          "cta": {
            "type": "object",
            "properties": {
              "label": { "type": "string" },
              "action": {
                "type": "string",
                "enum": ["open_detail", "save", "start_timer", "share", "none"]
              },
              "payload": {
                "type": "object",
                "properties": {
                  "id": { "type": "string" }
                }
              }
            }
          }
        }
      },
      "maxItems": 3
    },
    "follow_up": {
      "type": "object",
      "properties": {
        "in_days": { "type": "integer", "minimum": 1, "maximum": 7 },
        "intent": {
          "type": "string",
          "enum": ["sleep_check", "emotion_check", "habit_check", "none"]
        },
        "message_hint": { "type": "string" }
      }
    },
    "meta": {
      "type": "object",
      "required": ["skill", "skill_version"],
      "properties": {
        "skill": { "type": "string" },
        "skill_version": { "type": "string" },
        "prompt_version": {
          "type": "object",
          "properties": {
            "core": { "type": "string" },
            "policy": { "type": "string" },
            "task": { "type": "string" }
          }
        },
        "cache": {
          "type": "object",
          "properties": {
            "hit": { "type": "boolean" },
            "key": { "type": ["string", "null"] },
            "ttl_sec": { "type": "integer" }
          }
        },
        "repair_count": { "type": "integer", "minimum": 0 }
      }
    }
  }
}
```

### 1.2 TypeScript 类型定义

```typescript
// types/shunshi-response.ts

export type Tone = 'gentle' | 'neutral' | 'cheerful' | 'calm' | 'serious';
export type CareStatus = 'stable' | 'needs_attention' | 'escalate';
export type PresenceLevel = 'normal' | 'reduced' | 'silent';
export type SafetyFlag = 'none' | 'sensitive' | 'abnormal';
export type CardType = 'acupoint' | 'food' | 'tea' | 'movement' | 'breathing' | 'sleep' | 'solar_term' | 'note';
export type CTAAction = 'open_detail' | 'save' | 'start_timer' | 'share' | 'none';

export interface Media {
  image_id: string | null;
  video_id: string | null;
}

export interface CTA {
  label: string;
  action: CTAAction;
  payload?: { id: string };
}

export interface Card {
  type: CardType;
  title: string;
  subtitle?: string;
  steps?: string[];
  duration_min?: number;
  contraindications?: string[];
  media?: Media;
  cta?: CTA;
}

export interface FollowUp {
  in_days?: number;
  intent?: 'sleep_check' | 'emotion_check' | 'habit_check' | 'none';
  message_hint?: string;
}

export interface PromptVersion {
  core: string;
  policy: string;
  task: string;
}

export interface CacheInfo {
  hit: boolean;
  key: string | null;
  ttl_sec: number;
}

export interface Meta {
  skill: string;
  skill_version: string;
  prompt_version?: PromptVersion;
  cache?: CacheInfo;
  repair_count: number;
}

export interface ShunShiResponse {
  text: string;
  tone: Tone;
  care_status: CareStatus;
  presence_level: PresenceLevel;
  offline_encouraged: boolean;
  safety_flag: SafetyFlag;
  cards?: Card[];
  follow_up?: FollowUp;
  meta: Meta;
}
```

---

## 二、统一 Skill 输入 Schema

```typescript
// types/skill-request.ts

export interface UserContext {
  is_premium: boolean;
  life_stage: 'explore' | 'stress' | 'health' | 'companion';
  memory_enabled: boolean;
  proactive_enabled: boolean;
  quiet_hours: { start: string; end: string };
  preferences: {
    diet?: string;
    exercise?: string;
  };
  constraints: {
    allergy?: string[];
    avoid?: string[];
  };
}

export interface Signals {
  sleep_trend_7d?: 'later' | 'stable' | 'earlier' | 'unknown';
  mood_trend_7d?: 'low' | 'stable' | 'up' | 'unknown';
  activity_trend_7d?: 'low' | 'stable' | 'up' | 'unknown';
  recent_notes?: string[];
}

export interface TaskParams {
  goal?: 'sleep' | 'stress' | 'digestion' | 'focus' | 'none';
  scene?: 'home' | 'office' | 'outdoor' | 'bedtime';
  duration_min?: number;
  solar_term?: string;
  locale?: string;
  extra?: Record<string, any>;
}

export interface PromptVersion {
  core: string;
  policy: string;
  task: string;
}

export interface SkillRequest {
  user_id: string;
  user_context: UserContext;
  signals?: Signals;
  task_params: TaskParams;
  prompt_version: PromptVersion;
}
```

---

## 三、12 Skills 完整规格

### Skill 1: DailyRhythmPlan（今日节律）

```yaml
skill: DailyRhythmPlan
version: 1.0
frequency: 每天1次
priority: P0

输入参数:
  required:
    - user_context.life_stage
    - task_params.date
  optional:
    - signals.sleep_trend_7d
    - signals.mood_trend_7d
    - signals.activity_trend_7d

输出要求:
  text: "1句洞察 + 3条行动（每条<=16字）"
  cards: 最多1张（类型: sleep/movement/breathing）
  follow_up: 可选，in_days 1-3
  tone: 根据life_stage调整

Prompt模板骨架:
  """
  你是顺时 AI 养生助手。请为用户生成今日节律计划。

  用户信息：
  - 人生阶段：{{life_stage}}
  - 是否付费：{{is_premium}}

  {% if signals %}
  近期信号：
  - 睡眠趋势：{{signals.sleep_trend_7d}}
  - 情绪趋势：{{signals.mood_trend_7d}}
  - 活动趋势：{{signals.activity_trend_7d}}
  {% else %}
  用户暂无信号数据。
  {% endif %}

  要求：
  1. 输出1句洞察（基于信号或通用建议）
  2. 输出3条可执行的行动（按早/中/晚）
  3. 可选输出1个轻量卡片
  4. 语气温和，不说教，不医疗

  输出严格为 ShunShiResponse JSON。
  """

安全边界:
  - 禁止诊断性语言
  - 禁止"评分"类表述
  - 禁止医疗建议
  - 必须包含 contraindications（即使是空数组）

缓存策略:
  key: "daily:{user_id}:{YYYYMMDD}:{life_stage}:{is_premium}"
  TTL: 86400  # 24小时

测试fixtures:
  - fixtures/daily/free_explore_unknown.json
  - fixtures/daily/premium_stress_moodlow.json
  - fixtures/daily/premium_health_sleep_late.json
```

### Skill 2: MoodFirstAid（情绪急救）

```yaml
skill: MoodFirstAid
version: 1.0
frequency: 按需
priority: P0

输入参数:
  required:
    - user_context.life_stage
    - signals.mood_trend_7d（可选）
  optional:
    - task_params.goal（情绪强度）

输出要求:
  text: "共情一句 + 微行动（≤2分钟）+ 现实连接建议"
  offline_encouraged: true
  safety_flag: "异常词触发时=sensitive/abnormal"
  tone: gentle

Prompt模板骨架:
  """
  用户正在表达情绪。请按以下流程响应：

  1. 共情一句（不评判、不贴标签）
     - 可以说"我理解"
     - 禁止说"你想多了"/"不至于"

  2. 给1个微行动（1-2分钟内可完成）
     - 深呼吸
     - 站起来走动
     - 喝杯温水
     - 放松肩颈

  3. 轻轻鼓励联系现实支持（不强迫）
     - "如果愿意可以和朋友聊聊"

  安全边界：
  - 禁止心理诊断（不说"你是抑郁"）
  - 禁止评判（不说"你想太多"）
  - 异常词触发时设置 safety_flag=sensitive

  输出 ShunShiResponse JSON。
  """

安全边界:
  - 禁止诊断性语言
  - 禁止评判性语言
  - 异常词必须触发 safety_flag
  - 必须包含 when_to_seek_help（即使是建议咨询）

缓存策略:
  # 不缓存，每次都是新对话
```

### Skill 3: SleepWindDown（睡前仪式）

```yaml
skill: SleepWindDown
version: 1.0
frequency: 每天1次
priority: P0

输入参数:
  required:
    - task_params.duration_min（10/20/30）
    - user_context.life_stage
  optional:
    - signals.sleep_trend_7d
    - signals.caffeine_intake
    - signals.screen_time_before_bed

输出要求:
  text: "开场白 + 流程总结"
  cards: 类型sleep，包含steps
  tone: calm

Prompt模板骨架:
  """
  生成睡前仪式流程。

  参数：
  - 时长：{{duration_min}}分钟
  - 人生阶段：{{life_stage}}

  {% if signals %}
  - 最近就寝时间趋势：{{signals.sleep_trend_7d}}
  - 睡前屏幕时间：{{signals.screen_time_before_bed}}小时
  {% endif %}

  要求：
  1. 3-5个步骤，每步带时长
  2. 1条"替代方案"（如果今晚做不到）
  3. 禁止任何药物/治疗相关
  4. 步骤简洁可执行

  输出 ShunShiResponse JSON，cards类型=sleep。
  """

缓存策略:
  key: "sleep:{life_stage}:{duration}:{constraints_hash}"
  TTL: 604800  # 7天
```

### Skill 4: OfficeMicroBreak（办公室微休息）

```yaml
skill: OfficeMicroBreak
version: 1.0
frequency: 按需
priority: P1

输入参数:
  required:
    - task_params.duration_min（3/5）
    - task_params.scene（desk/meeting_room）
  optional:
    - task_params.focus_area（shoulder/eye/breath）

输出要求:
  text: "开场 + 动作说明"
  cards: 类型breathing或movement
  tone: gentle

缓存策略:
  key: "break:{scene}:{duration}:{life_stage}"
  TTL: 2592000  # 30天
```

### Skill 5: SolarTermGuide（节气指南）

```yaml
skill: SolarTermGuide
version: 1.0
frequency: 每天（节气当天）
priority: P1

输入参数:
  required:
    - task_params.solar_term
    - task_params.locale
  optional:
    - user_context.life_stage

输出要求:
  text: "节气介绍 + 重点"
  cards: 最多1张，类型solar_term
  tone: cheerful

缓存策略:
  key: "solar:{solar_term}:{locale}:{life_stage}"
  TTL: 604800  # 7天（到下一节气）
```

### Skill 6: BodyConstitutionLite（体质轻推断）

```yaml
skill: BodyConstitutionLite
version: 1.0
frequency: 少次
priority: P1

输出要求:
  text: "免责声明 + 倾向描述"
  cards: 可选
  tone: gentle

Prompt关键点:
  - 必须先输出免责声明
  - 只说"可能倾向于"不说"你是"
  - 禁止诊断性结论

缓存策略:
  # 不缓存，依赖用户输入
```

### Skill 7: FoodTeaRecommender（食疗/茶饮）

```yaml
skill: FoodTeaRecommender
version: 1.0
frequency: 按需
priority: P1

输出要求:
  text: "方案概述"
  cards: 类型food或tea，包含做法+禁忌
  tone: gentle

Prompt关键点:
  - 给1-2个方案
  - 每个方案含：做法、禁忌、替代
  - 禁止"治疗/治愈"措辞
  - 用"更舒服"而非"治病"

缓存策略:
  key: "teafood:{goal}:{life_stage}:{constraints_hash}"
  TTL: 2592000  # 30天
```

### Skill 8: AcupressureRoutineLite（穴位按揉）

```yaml
skill: AcupressureRoutineLite
version: 1.0
frequency: 按需
priority: P1

输出要求:
  text: "开场 + 穴位说明"
  cards: 类型acupoint，1-2个穴位
  tone: calm

Prompt关键点:
  - 只推荐1-2个常用保健点
  - 位置用"在…附近"避免精准定位
  - 强调不适停止

缓存策略:
  key: "acup:{goal}:{life_stage}"
  TTL: 7776000  # 90天
```

### Skill 9: FollowUpGenerator（轻跟进）

```yaml
skill: FollowUpGenerator
version: 1.0
frequency: 系统调度
priority: P1

输出要求:
  text: "轻跟进文案"
  follow_up: 必须可忽略
  tone: casual

Prompt关键点:
  - 语气轻，允许沉默
  - 不追问，不道德绑架
  - 输出 follow_up.in_days 1-7
```

### Skill 10: PresencePolicyDecider（退让策略）

```yaml
skill: PresencePolicyDecider
version: 1.0
frequency: 系统调度
priority: P1

输出要求:
  presence_level: "normal|reduced|silent"
  text: 可为空或一句提示
```

### Skill 11: CareStatusUpdater（照护状态机）

```yaml
skill: CareStatusUpdater
version: 1.0
frequency: 系统调度
priority: P1

输出要求:
  care_status: "stable|needs_attention|escalate"
  text: 可为空
```

### Skill 12: FamilyCareDigest（家庭摘要）

```yaml
skill: FamilyCareDigest
version: 1.0
frequency: 每天
priority: P1

输出要求:
  text: "家庭成员状态概述"
  cards: 可选
  tone: gentle

Prompt关键点:
  - 只输出趋势（好/一般/需关注）
  - 禁止输出父母聊天原文
  - 给"建议做的一件小事"

缓存策略:
  key: "family:{family_id}:{YYYYMMDD}"
  TTL: 43200  # 12小时
```

---

## 四、Router 路由规则

### 4.1 关键词路由表

```typescript
const ROUTE_RULES = [
  // 核心日常
  { keywords: ['今天怎么样', '今日计划', '今天干嘛', 'daily', '今日'], skill: 'DailyRhythmPlan' },
  { keywords: ['睡不着', '失眠', '想睡个好觉', 'sleep', '睡前', '晚睡'], skill: 'SleepWindDown' },
  { keywords: ['心情不好', '烦', '难过', '压力大', 'emotion', '情绪', '焦虑', '崩溃'], skill: 'MoodFirstAid' },
  { keywords: ['肩膀酸', '眼睛累', 'office', '上班', '办公室', '久坐'], skill: 'OfficeMicroBreak' },
  
  // 养生生成
  { keywords: ['节气', '立春', '惊蛰', '夏至', '秋分', '立冬', 'solar'], skill: 'SolarTermGuide' },
  { keywords: ['体质', '我是什么体质', 'constitution', '气虚', '湿热', '阴虚'], skill: 'BodyConstitutionLite' },
  { keywords: ['吃什么', '食疗', '茶饮', '养生', 'diet', 'recipe', '喝什么'], skill: 'FoodTeaRecommender' },
  { keywords: ['穴位', '按揉', 'acupoint', '按摩哪里'], skill: 'AcupressureRoutineLite' },
  
  // 安全强制
  { keywords: ['血压', '血糖', '体检', 'medical', '诊断', '治疗', '开药'], skill: '__SAFE_MODE__' },
];

function route(message: string): string | null {
  const lowerMessage = message.toLowerCase();
  
  for (const rule of ROUTE_RULES) {
    if (rule.keywords.some(k => lowerMessage.includes(k))) {
      return rule.skill;
    }
  }
  
  return null;  // 纯聊天
}
```

### 4.2 路由执行流程

```typescript
async function executeSkill(request: SkillRequest): Promise<ShunShiResponse> {
  const skillName = request.task_params.skill || route(request.message);
  
  // 1. 检查缓存
  const cacheKey = buildCacheKey(skillName, request);
  const cached = await redis.get(cacheKey);
  if (cached) {
    return { ...cached, meta: { ...cached.meta, cache: { hit: true, key: cacheKey } } };
  }
  
  // 2. 构建 Prompt
  const prompt = buildPrompt(skillName, request);
  
  // 3. 调用 LLM
  const rawResponse = await llm.complete(prompt);
  
  // 4. Schema 校验
  let validated: ShunShiResponse;
  try {
    validated = validateAndRepair(rawResponse);
  } catch (e) {
    // Schema 修复失败，使用降级响应
    validated = buildFallbackResponse(skillName);
    validated.meta.repair_count++;
  }
  
  // 5. 写入缓存
  const ttl = getTTL(skillName);
  if (ttl > 0) {
    await redis.set(cacheKey, validated, ttl);
  }
  
  // 6. 返回
  return {
    ...validated,
    meta: {
      ...validated.meta,
      skill: skillName,
      cache: { hit: false, key: cacheKey, ttl_sec: ttl }
    }
  };
}
```

---

## 五、测试 Fixtures

### 5.1 DailyRhythmPlan Fixtures

**fixtures/daily/free_explore_unknown.json**
```json
{
  "input": {
    "user_id": "u001",
    "user_context": {
      "is_premium": false,
      "life_stage": "explore",
      "memory_enabled": true,
      "proactive_enabled": true,
      "quiet_hours": { "start": "23:00", "end": "07:30" },
      "preferences": {},
      "constraints": {}
    },
    "signals": {},
    "task_params": { "date": "2026-03-06" },
    "prompt_version": { "core": "SS_CORE_v1", "policy": "SS_POLICY_FREE", "task": "SS_TASK_DAILY_v1" }
  },
  "expected": {
    "text": { "minLength": 10, "maxLength": 200 },
    "tone": { "enum": ["gentle", "neutral", "cheerful"] },
    "cards": { "maxItems": 1 },
    "safety_flag": { "enum": ["none"] },
    "meta": { "skill": "DailyRhythmPlan" }
  }
}
```

**fixtures/daily/premium_stress_moodlow.json**
```json
{
  "input": {
    "user_id": "u002",
    "user_context": {
      "is_premium": true,
      "life_stage": "stress",
      "memory_enabled": true,
      "proactive_enabled": true,
      "quiet_hours": { "start": "23:00", "end": "07:30" },
      "preferences": {},
      "constraints": {}
    },
    "signals": {
      "sleep_trend_7d": "later",
      "mood_trend_7d": "low",
      "activity_trend_7d": "stable"
    },
    "task_params": { "date": "2026-03-06" },
    "prompt_version": { "core": "SS_CORE_v1", "policy": "SS_POLICY_PREMIUM", "task": "SS_TASK_DAILY_v1" }
  },
  "expected": {
    "text": { "contains": ["睡", "情绪"] },
    "tone": { "enum": ["gentle", "calm"] },
    "follow_up": { "in_days": { "minimum": 1, "maximum": 3 } }
  }
}
```

### 5.2 MoodFirstAid Fixtures

**fixtures/mood/normal_rum.json**
```json
{
  "input": {
    "user_id": "u003",
    "user_context": { "is_premium": false, "life_stage": "stress" },
    "signals": { "mood_trend_7d": "stable" },
    "task_params": { "goal": "medium" },
    "message": "最近工作压力好大"
  },
  "expected": {
    "text": { "contains": ["理解", "压力"] },
    "offline_encouraged": true,
    "safety_flag": { "enum": ["none"] }
  }
}
```

**fixtures/mood/crisis_keywords.json**
```json
{
  "input": {
    "user_id": "u004",
    "user_context": { "is_premium": false, "life_stage": "stress" },
    "signals": {},
    "task_params": { "goal": "high" },
    "message": "我撑不住了"
  },
  "expected": {
    "safety_flag": { "enum": ["sensitive", "abnormal"] },
    "text": { "contains": ["陪", "一起"] }
  }
}
```

### 5.3 SleepWindDown Fixtures

**fixtures/sleep/10min_stress.json**
```json
{
  "input": {
    "user_context": { "life_stage": "stress" },
    "signals": { "screen_time_before_bed": 2 },
    "task_params": { "duration_min": 10 }
  },
  "expected": {
    "cards": [{ "type": "sleep", "steps": { "minItems": 3, "maxItems": 5 } }],
    "text": { "minLength": 10 }
  }
}
```

---

## 六、快速接入指南

### 6.1 Router 新增端点

```typescript
// POST /api/skill/run
app.post('/api/skill/run', async (req, res) => {
  const { skill, user_id, user_context, signals, task_params } = req.body;
  
  const request: SkillRequest = {
    user_id,
    user_context,
    signals,
    task_params,
    prompt_version: getPromptVersion(skill)
  };
  
  const response = await executeSkill(request);
  res.json(response);
});
```

### 6.2 Flutter 端渲染

```dart
// 渲染 ShunShiResponse
Widget renderResponse(ShunShiResponse response) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 主文本
      Text(response.text),
      
      // 卡片
      if (response.cards != null)
        ...response.cards!.map((card) => renderCard(card)),
      
      // 安全提示
      if (response.safety_flag != 'none')
        SafetyBanner(flag: response.safety_flag),
    ],
  );
}

Widget renderCard(Card card) {
  switch (card.type) {
    case 'sleep':
      return SleepCardWidget(card);
    case 'food':
    case 'tea':
      return FoodTeaCardWidget(card);
    case 'acupoint':
      return AcupointCardWidget(card);
    case 'movement':
      return MovementCardWidget(card);
    case 'breathing':
      return BreathingCardWidget(card);
    default:
      return DefaultCardWidget(card);
  }
}
```

---

## 七、总结

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Skills 体系接入清单                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ✅ 统一 Schema (ShunShiResponse v1)                                       │
│  ✅ 12 Skills 完整规格                                                     │
│  ✅ 路由规则（关键词版）                                                   │
│  ✅ 缓存策略                                                               │
│  ✅ 测试 Fixtures 示例                                                     │
│                                                                             │
│  下一步：                                                                   │
│  1. Router 新增 /api/skill/run                                            │
│  2. 实现 4 个高频 Skill（Daily/Mood/Sleep/Office）                       │
│  3. 编写完整测试 Fixtures                                                 │
│  4. Flutter 端统一渲染                                                    │
│                                                                             │
│  最短路径：1天跑通 Demo，1周上线 4 个核心 Skill                           │
└─────────────────────────────────────────────────────────────────────────────┘
```
