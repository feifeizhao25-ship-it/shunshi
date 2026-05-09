# 顺时 ShunShi 生命周期系统设计

## 生命周期阶段

```python
# 四大生命周期阶段
LIFE_STAGES = {
    "exploring": {
        "name": "探索阶段",
        "age_range": "18-25岁",
        "primary_needs": [
            "睡眠管理",
            "情绪支持",
            "压力缓解",
            "生活节律",
            "轻陪伴"
        ],
        "product_priorities": [
            "今日节律",
            "睡前放松",
            "情绪支持",
            "轻行动建议",
            "极简体验"
        ],
        "ai_role": "生活朋友",
        "payment_reason": "习惯养成、个人成长"
    },
    "stressed": {
        "name": "压力阶段",
        "age_range": "25-40岁",
        "primary_needs": [
            "工作压力",
            "家庭压力",
            "睡眠改善",
            "亚健康调理",
            "节律恢复"
        ],
        "product_priorities": [
            "今日计划",
            "压力调节",
            "办公室微休息",
            "睡眠趋势",
            "家庭入口"
        ],
        "ai_role": "生活顾问",
        "payment_reason": "效率提升、家庭关怀"
    },
    "healthy": {
        "name": "健康阶段",
        "age_range": "40-60岁",
        "primary_needs": [
            "体质调理",
            "节气养生",
            "食疗茶饮",
            "穴位保健",
            "运动功法"
        ],
        "product_priorities": [
            "节气系统",
            "体质系统",
            "食疗内容",
            "穴位系统",
            "家庭关怀"
        ],
        "ai_role": "养生顾问",
        "payment_reason": "健康管理、家庭共享"
    },
    "companion": {
        "name": "陪伴阶段",
        "age_range": "60岁以上",
        "primary_needs": [
            "陪伴",
            "语音交互",
            "睡眠关怀",
            "情绪支持",
            "简单养生"
        ],
        "product_priorities": [
            "语音对话",
            "大字体",
            "每日一句",
            "简单建议",
            "家庭动态"
        ],
        "ai_role": "温和陪伴者",
        "payment_reason": "陪伴、子女连接"
    }
}
```

---

## 生命周期判定

```python
# 判定因素
LIFE_STAGE_FACTORS = {
    "age": {
        "weight": 0.4,
        "rules": {
            "exploring": [18, 25],
            "stressed": [26, 40],
            "healthy": [41, 60],
            "companion": [61, 999]
        }
    },
    "behavior": {
        "weight": 0.3,
        "signals": {
            "exploring": ["late_night", "mood_focus", "stress_keywords"],
            "stressed": ["work_mentions", "family_mentions", "sleep_issues"],
            "healthy": ["health_interest", "food_interest", "exercise_interest"],
            "companion": ["simple_ui_preference", "voice_preference"]
        }
    },
    "questionnaire": {
        "weight": 0.2,
        "questions": [
            "你目前最关心什么？",
            "你的日常生活主要围绕？",
            "你希望顺时帮你做什么？"
        ]
    },
    "manual": {
        "weight": 0.1,
        "description": "用户主动选择"
    }
}

# 判定算法
class LifeStageDecider:
    def decide(
        self,
        age: int,
        behavior_signals: dict,
        questionnaire_answers: list,
        manual_choice: str = None
    ) -> str:
        scores = {"exploring": 0, "stressed": 0, "healthy": 0, "companion": 0}
        
        # 年龄分数
        age_score = self._calculate_age_score(age)
        scores[age_score] += 0.4
        
        # 行为分数
        behavior_score = self._calculate_behavior_score(behavior_signals)
        scores[behavior_score] += 0.3
        
        # 问卷分数
        questionnaire_score = self._calculate_questionnaire_score(questionnaire_answers)
        scores[questionnaire_score] += 0.2
        
        # 手动选择
        if manual_choice:
            scores[manual_choice] += 0.1
        
        return max(scores, key=scores.get)
    
    def _calculate_age_score(self, age: int) -> str:
        if age < 26:
            return "exploring"
        elif age < 41:
            return "stressed"
        elif age < 61:
            return "healthy"
        else:
            return "companion"
```

---

## 生命周期动态更新

```python
# 动态更新触发条件
LIFE_STAGE_UPDATE_TRIGGERS = {
    "behavior_change": {
        "threshold": "行为信号持续 30 天变化",
        "example": "从 stress_keywords 变为 health_interest"
    },
    "age_milestone": {
        "threshold": "年龄跨入新阶段",
        "example": "25岁 → 26岁"
    },
    "questionnaire_resubmit": {
        "threshold": "用户重新填写问卷",
        "example": "主动更新"
    },
    "manual_change": {
        "threshold": "用户手动选择",
        "example": "设置中切换"
    }
}

# 更新流程
UPDATE_FLOW = {
    "step_1": "收集新数据",
    "step_2": "计算新阶段分数",
    "step_3": "与当前阶段对比",
    "step_4": "如果变化 > 阈值，执行更新",
    "step_5": "记录变更历史",
    "step_6": "平滑过渡 UI"
}
```

---

## 生命周期对产品的影响

```python
# 影响映射
LIFE_STAGE_IMPACTS = {
    "home_page": {
        "exploring": {
            "priority_modules": ["today_rhythm", "mood_support", "light_habits"],
            "ai_greeting_style": "轻松友好",
            "content_tone": "轻量建议"
        },
        "stressed": {
            "priority_modules": ["daily_plan", "stress_relief", "office_break"],
            "ai_greeting_style": "关心理解",
            "content_tone": "实用高效"
        },
        "healthy": {
            "priority_modules": ["solar_term", "constitution", "food_tea"],
            "ai_greeting_style": "养生顾问",
            "content_tone": "专业温和"
        },
        "companion": {
            "priority_modules": ["voice_chat", "simple_care", "family"],
            "ai_greeting_style": "温暖陪伴",
            "content_tone": "简单直白"
        }
    },
    
    "chat": {
        "exploring": {
            "quick_chips": ["睡眠", "情绪", "今天干嘛", "随便聊聊"],
            "response_style": "轻松有趣"
        },
        "stressed": {
            "quick_chips": ["减压", "睡眠", "工作计划", "家庭"],
            "response_style": "高效实用"
        },
        "healthy": {
            "quick_chips": ["养生", "食疗", "节气", "穴位"],
            "response_style": "专业顾问"
        },
        "companion": {
            "quick_chips": ["聊天", "养生", "天气", "新闻"],
            "response_style": "温暖陪伴"
        }
    },
    
    "notifications": {
        "exploring": {
            "frequency": "low",
            "types": ["morning", "evening"],
            "tone": "轻松"
        },
        "stressed": {
            "frequency": "medium",
            "types": ["morning", "reminder", "care"],
            "tone": "关心"
        },
        "healthy": {
            "frequency": "medium",
            "types": ["solar_term", "habit", "seasonal"],
            "tone": "专业"
        },
        "companion": {
            "frequency": "high",
            "types": ["morning", "evening", "family", "reminder"],
            "tone": "温暖"
        }
    }
}
```

---

## 生命周期前端适配

```dart
// 主页动态内容
class HomePageAdapter {
    Widget buildHomePage(LifeStage stage) {
        switch (stage) {
            case LifeStage.exploring:
                return ExploringHomePage();
            case LifeStage.stressed:
                return StressedHomePage();
            case LifeStage.healthy:
                return HealthyHomePage();
            case LifeStage.companion:
                return CompanionHomePage();
        }
    }
}

// 聊天快捷 Chips
class QuickChipsAdapter {
    List<String> getChips(LifeStage stage) {
        switch (stage) {
            case LifeStage.exploring:
                return ["睡眠", "情绪", "今天干嘛", "随便聊聊"];
            case LifeStage.stressed:
                return ["减压", "睡眠", "工作计划", "家庭"];
            case LifeStage.healthy:
                return ["养生", "食疗", "节气", "穴位"];
            case LifeStage.companion:
                return ["聊天", "养生", "天气", "新闻"];
        }
    }
}

// 通知频率
class NotificationAdapter {
    int getFrequency(LifeStage stage) {
        switch (stage) {
            case LifeStage.exploring:
                return 2;  // 每天2条
            case LifeStage.stressed:
                return 4;  // 每天4条
            case LifeStage.healthy:
                return 3;  // 每天3条
            case LifeStage.companion:
                return 6;  // 每天6条
        }
    }
}
```

---

## 生命周期数据库

```sql
-- 生命周期历史
CREATE TABLE life_stage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    life_stage VARCHAR(20) NOT NULL,
    confidence FLOAT DEFAULT 1.0,
    source VARCHAR(50) DEFAULT 'auto' 
        CHECK (source IN ('auto', 'age', 'behavior', 'questionnaire', 'manual')),
    factors JSONB DEFAULT '{}',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, started_at)
);

-- 用户资料中的阶段字段
ALTER TABLE user_profiles ADD COLUMN life_stage VARCHAR(20);

-- 索引
CREATE INDEX idx_life_stage_user_id ON life_stage_history(user_id);
CREATE INDEX idx_life_stage_started_at ON life_stage_history(started_at);
```

---

## 生命周期 API

```python
# API 接口

# 获取当前生命周期
GET /api/v1/users/me/life-stage

# 获取生命周期历史
GET /api/v1/users/me/life-stage/history

# 更新生命周期（手动）
PUT /api/v1/users/me/life-stage
{
    "life_stage": "healthy"
}

# 获取生命周期相关内容
GET /api/v1/users/me/life-stage/content
{
    "types": ["home", "chat", "notification"]
}
```

---

## 用户体验设计

### 不强制归类

```dart
// 原则
PRINCIPLES = {
    "soft_transition": "软过渡 - UI 逐渐变化，不突兀",
    "user_control": "用户控制 - 可手动调整",
    "no_stigma": "无标签化 - 不说'你是XX阶段的人'",
    "gradual": "渐进式 - 内容慢慢变化"
}

// 过渡动画
TRANSITION_ANIMATION = {
    "duration": "30天",
    "method": "权重渐变",
    "ui_change": "模块顺序微调"
}
```
