# 顺时 Skills 体系：Contentless → Skillful 实施方案

> 不存内容，存技能生成器。用 LLM + Skills 现场生成个性化内容。

---

## 一、总体架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Skills 体系架构                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    User Request                                                              │
│         │                                                                    │
│         ▼                                                                    │
│   ┌─────────────┐                                                           │
│   │  AI Router │  Intent Detection                                        │
│   └─────────────┘             │                                           │
│         │                     ▼                                            │
│         │          ┌─────────────────────────────┐                         │
│         │          │     Skill Router            │                         │
│         │          │  • Intent → Skill 路由     │                         │
│         ▼          └─────────────────────────────┘                         │
│   ┌─────────────┐             │                                           │
│   │ Skill Engine│             ▼                                           │
│   │   (LLM)    │  ┌─────────────────────────────┐                         │
│   └─────────────┘  │     Skill Engine           │                         │
│         │          │  • 组装 Prompt              │                         │
│         ▼          │  • 调用 LLM                │                         │
│   ┌─────────────┐  └─────────────────────────────┘                         │
│   │   Schema   │             │                                           │
│   │  Validator │             ▼                                           │
│   └─────────────┘  ┌─────────────────────────────┐                         │
│         │          │     Cache Layer (Redis)     │                         │
│         ▼          │  • 按 skill+params 分桶     │                         │
│   ┌─────────────┐  │  • TTL: 1h ~ 24h            │                         │
│   │    Cache   │  └─────────────────────────────┘                         │
│   └─────────────┘                                                       │
│         │                                                                    │
│         ▼                                                                    │
│      Response                                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、12 个核心 Skills

### 2.1 Skills 总览

| 分类 | Skill 名称 | 频次 | 复杂度 | 付费 |
|------|------------|------|--------|------|
| **核心日常** | DailyRhythmPlan | 每天1次 | 中 | Free |
| | SleepWindDown | 每天1次 | 低 | Free |
| | OfficeMicroBreak | 多次 | 低 | Free |
| | MoodFirstAid | 多次 | 高 | Free |
| **养生生成** | SolarTermGuide | 每天1次 | 中 | Free |
| | BodyConstitutionLite | 少次 | 中 | Premium |
| | FoodTeaRecommender | 多次 | 中 | Premium |
| | AcupressureRoutineLite | 多次 | 低 | Free |
| **结构化陪伴** | FollowUpGenerator | 多次 | 低 | Free |
| | PresencePolicyDecider | 多次 | 低 | Free |
| | CareStatusUpdater | 多次 | 中 | Free |
| | FamilyCareDigest | 每天1次 | 中 | Premium |

---

## 三、每个 Skill 详细规格

### 3.1 DailyRhythmPlan（今日节律）

**用途**: 每日首页核心内容 - 洞察 + 3行动 + 1卡片

**输入参数**:
```typescript
interface DailyRhythmPlanInput {
  user_context: {
    life_stage: 'exploration' | 'stress' | 'health' | 'companionship';
    age_group: string;
    is_premium: boolean;
    preferences: {
      tone: '活泼' | '温暖' | '专业' | '耐心';
      detail_level: 'short' | 'medium' | 'detailed';
    };
  };
  signals: {
    sleep?: { trend: string; quality_score: number };
    mood?: { trend: string; score: number };
    activity?: { steps: number; trend: string };
  } | null;
  task_params: { date: string; };
}
```

**输出 Schema**:
```typescript
interface DailyRhythmPlanOutput {
  skill: 'DailyRhythmPlan';
  version: '1.0';
  
  text: string;  // 对用户说的话，50-150字
  
  insight: {
    title: string;
    content: string;
    emoji: string;
  };
  
  actions: Array<{
    time_period: 'morning' | 'afternoon' | 'evening';
    items: string[];
  }>;
  
  card?: {
    type: 'suggestion' | 'diet' | 'exercise' | 'acupoint';
    title: string;
    content: string;
    emoji: string;
  };
  
  follow_up?: { type: string; message: string; };
  safety_flag: 'none' | 'watch' | 'escalate';
  presence_level: 'normal' | 'reduced' | 'silent';
  contraindications: string[];
  when_to_seek_help: string | null;
}
```

**缓存策略**: TTL当天，分桶键 `skill=daily_rhythm_plan|user_id|date`

---

### 3.2 SleepWindDown（睡前仪式）

**输入**: life_stage, signals (睡眠时间/质量/咖啡因), task_params (时长: 10/20/30min, 场景)

**输出**: text, steps[], tips[], safety_flag, contraindications

**缓存**: TTL 12小时

---

### 3.3 OfficeMicroBreak（办公室3分钟放松）

**输入**: life_stage, task_params (部位: shoulder/eye/breath, 时长: 3/5min, 空间: desk/meeting_room)

**输出**: text, exercise{steps[]}, tips[], safety_flag

---

### 3.4 MoodFirstAid（情绪急救）

**输入**: life_stage, signals (情绪趋势/对话上下文), task_params (强度: low/medium/high, 诱因)

**输出**: text, empathy, micro_action?, reality_connection?, follow_up?, safety_flag (关键), contraindications, when_to_seek_help

**安全边界**:
- 不诊断、不贴标签
- 不评判
- 永远给 when_to_seek_help
- 自伤倾向 → safety_flag = escalate

---

### 3.5 SolarTermGuide（节气指南）

**输入**: life_stage, age_group, task_params (节气名, 日期, 地区)

**输出**: text, content{proverb, focus, diet[], lifestyle[]}, cards[], safety_flag

**缓存**: TTL 15天（到下一节气）

---

### 3.6 BodyConstitutionLite（体质轻推断）

**输入**: life_stage, is_premium, task_params (问卷答案 或 症状描述)

**输出**: disclaimer(必须), primary_constitution?, secondary_constitutions[], lifestyle_guidance, contraindications, when_to_seek_help, safety_flag

**安全边界**:
- 只说"倾向于"不说"你是"
- 必须给 when_to_seek_help
- 不开药方

---

### 3.7 FoodTeaRecommender（食疗/茶饮生成）

**输入**: life_stage, constitution?, is_premium, signals (症状, 季节), task_params (类型: diet/tea/soup, 目标, 禁忌)

**输出**: recommendations[]{name, ingredients, benefits, prep_method, emoji}, contraindications, when_to_seek_help, safety_flag

**缓存**: TTL 24小时

---

### 3.8 AcupressureRoutineLite（穴位按揉流程）

**输入**: life_stage, task_params (目标: relaxation/energy/sleep/headache/digestion, 时长, 经验水平)

**输出**: disclaimer, acupoints[]{name, location, method, duration, benefits, emoji}, steps, contraindications, when_to_seek_help, safety_flag

---

### 3.9 FollowUpGenerator（轻跟进生成）

**输入**: life_stage, signals (pending_topics[], days_since_last_interaction), task_params (类型: check_in/reminder/continue_topic)

**输出**: should_follow_up, message?, skip_reason?, presence_level

---

### 3.10 PresencePolicyDecider（退让策略）

**输入**: timezone, quiet_hours, notification_preference, signals (last_active, interactions, care_status)

**输出**: decision{should_reach, reason, recommended_channels[]}, next_check_time?, presence_level

---

### 3.11 CareStatusUpdater（照护状态机）

**输入**: current_status, signals (recent_messages[], interaction_frequency, sleep_trend)

**输出**: updated_status{overall, emotion_trend, recommended_care_level}, triggers[], recommended_actions[]

---

### 3.12 FamilyCareDigest（家庭可感知摘要）

**输入**: is_premium, family_members[]{user_id, relation, age}

**输出**: disclaimer, members[]{name, relation, status_summary, trend, alerts?, last_updated}, recommendations?

---

## 四、路由策略

### Intent → Skill 路由规则

| 意图关键词 | Skill | 备用 |
|-----------|-------|------|
| 今天怎么样/今日计划 | DailyRhythmPlan | - |
| 睡不着/失眠/睡前 | SleepWindDown | MoodFirstAid |
| 肩膀酸/眼睛累/上班 | OfficeMicroBreak | - |
| 心情不好/烦/压力大 | MoodFirstAid | - |
| 节气/立春/惊蛰 | SolarTermGuide | - |
| 体质/我是什么体质 | BodyConstitutionLite | - |
| 吃什么/食疗/茶饮 | FoodTeaRecommender | - |
| 穴位/按揉/按摩 | AcupressureRoutineLite | - |
| 血压/血糖/体检/诊断 | - | SafeMode (强制) |
| (默认) | - | 纯聊天 |

---

## 五、缓存策略

| Skill | TTL | 分桶键 |
|-------|-----|--------|
| DailyRhythmPlan | 当天 | skill + user_id + date |
| SleepWindDown | 12h | skill + user_id + duration |
| SolarTermGuide | 15天 | skill + term + region |
| FoodTeaRecommender | 24h | skill + goal + constraints_hash |
| MoodFirstAid | 不缓存 | - |
| OfficeMicroBreak | 6h | skill + user_id + focus_area |
| BodyConstitutionLite | 30天 | skill + user_id |
| FamilyCareDigest | 6h | skill + user_id + family_hash |

---

## 六、安全与合规

### Safety Flag 定义

- **none**: 正常
- **watch**: 关注，需要后续跟进
- **escalate**: 升级，需要危机响应

### 危机响应流程

1. 记录危机事件日志
2. 发送温暖响应 + 心理援助热线
3. 通知家人（如已绑定）
4. 设置 presence_level = silent

### 必带安全字段

每个 Skill 输出**必须**包含：
- `safety_flag`: 'none' | 'watch' | 'escalate'
- `presence_level`: 'normal' | 'reduced' | 'silent'
- `contraindications`: string[] (禁忌)
- `when_to_seek_help`: string | null (建议就医场景)

---

## 七、API 接口

### POST /api/skill/run

```json
// 请求
{
  "skill": "DailyRhythmPlan",
  "user_id": "user_123",
  "user_context": { "life_stage": "stress", "is_premium": true },
  "task_params": { "date": "2026-03-06" }
}

// 响应
{
  "skill": "DailyRhythmPlan",
  "version": "1.0",
  "data": { ... },
  "cached": false,
  "generated_at": "2026-03-06T08:30:00Z"
}
```

### POST /api/chat/send

```json
// 请求
{
  "user_id": "user_123",
  "message": "睡不着怎么办"
}

// 响应
{
  "skill_used": "SleepWindDown",
  "response": {
    "text": "...",
    "cards": [...]
  },
  "safety_flag": "none"
}
```

---

## 八、Flutter 渲染

### 统一响应模型

```dart
class ShunshiResponse {
  final String text;
  final List<ContentCard>? cards;
  final String safetyFlag;
  
  factory ShunshiResponse.fromJson(Map<String, dynamic> json) {
    return ShunshiResponse(
      text: json['text'] ?? '',
      cards: (json['cards'] as List?)
          ?.map((c) => ContentCard.fromJson(c))
          .toList(),
      safetyFlag: json['safety_flag'] ?? 'none',
    );
  }
}

class ContentCard {
  final String type;  // 'diet' | 'acupoint' | 'exercise' | 'suggestion'
  final String title;
  final String content;
  final String emoji;
  
  Widget render() {
    switch (type) {
      case 'diet': return DietCardWidget(...);
      case 'acupoint': return AcupointCardWidget(...);
      case 'exercise': return ExerciseCardWidget(...);
      default: return SuggestionCardWidget(...);
    }
  }
}
```

---

## 九、版本管理

```typescript
const SKILL_VERSIONS = {
  'DailyRhythmPlan': { prompt_version: '1.0', status: 'stable' },
  'FoodTeaRecommender': { prompt_version: '2.0', status: 'beta', rollout: 10 },
  // ...
};
```

---

## 十、总结

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Skills 体系成功公式                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│     灵活 = 12 Skills × 按需组合 × LLM 生成                                │
│                                                                             │
│     可控 = 统一 Schema × 强制安全字段 × 版本管理                          │
│                                                                             │
│     省钱 = 缓存命中 × 小模型优先                                          │
│                                                                             │
│     安全 = 边界写死 × 危机响应 × 强制就医提醒                             │
│                                                                             │
│     12 个 Skills 够用一生                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 附：可直接给 AI Router 的系统提示词

```markdown
你是顺时 ShunShi 的 AI Router 架构师。我们不建设大规模专业内容库，而是内置一组可组合 Skills（技能生成器）。要求：每个 Skill 以严格 JSON Schema 输出，可测试、可缓存、可灰度回滚。

12 个 Skills：
1. DailyRhythmPlan - 今日节律（洞察+3行动+1卡片）
2. SleepWindDown - 睡前仪式
3. OfficeMicroBreak - 办公室3分钟放松
4. MoodFirstAid - 情绪急救
5. SolarTermGuide - 节气指南
6. BodyConstitutionLite - 体质轻推断
7. FoodTeaRecommender - 食疗/茶饮生成
8. AcupressureRoutineLite - 穴位按揉流程
9. FollowUpGenerator - 轻跟进生成
10. PresencePolicyDecider - 退让策略
11. CareStatusUpdater - 照护状态机
12. FamilyCareDigest - 家庭可感知摘要

每个 Skill 输出必须包含：
- text: string
- cards[]?: {type, title, content, emoji}
- follow_up?: {type, message}
- safety_flag: 'none' | 'watch' | 'escalate'
- presence_level: 'normal' | 'reduced' | 'silent'
- contraindications: string[]
- when_to_seek_help: string | null

安全边界：
- 不诊断、不用药、不解读报告
- 异常优先 SafeMode
- 鼓励现实连接
- 强制 when_to_seek_help

路由规则：
- 关键词命中 → 对应 Skill
- 闲聊 → 纯对话（输出仍用 Schema）
- 医疗/用药 → SafeMode

输出：总览架构 → Skills 列表 → 路由与缓存 → 接口示例
```
