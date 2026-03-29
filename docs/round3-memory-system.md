# 顺时 ShunShi 记忆系统设计

## 记忆系统架构

```
记忆系统
├── 短期记忆 (Session Memory)
├── 长期记忆 (Long-term Memory)
│   ├── 记忆快照 (Memory Snapshots)
│   ├── 人生阶段总结 (Life Phase Summaries)
│   └── 照护状态历史 (Care Status History)
├── 记忆摘要 (Memory Summary)
└── 隐私控制 (Privacy Control)
```

---

## 记忆类型

```python
# 记忆类型定义
MEMORY_TYPES = {
    "preference": {
        "name": "偏好记忆",
        "examples": ["喜欢中医", "不吃辣", "早睡型"],
        "retention": "long",
        "sensitive": False
    },
    "habit": {
        "name": "习惯记忆",
        "examples": ["每天泡脚", "晨跑", "午休"],
        "retention": "long",
        "sensitive": False
    },
    "health": {
        "name": "健康记忆",
        "examples": ["睡眠不好", "偏头痛", "胃不太好"],
        "retention": "long",
        "sensitive": True
    },
    "family": {
        "name": "家庭记忆",
        "examples": ["爸爸有高血压", "妈妈睡眠差"],
        "retention": "long",
        "sensitive": True
    },
    "emotion": {
        "name": "情绪记忆",
        "examples": ["最近压力大", "心情烦躁"],
        "retention": "medium",
        "sensitive": True
    },
    "event": {
        "name": "事件记忆",
        "examples": ["最近出差", "刚搬新家"],
        "retention": "medium",
        "sensitive": False
    },
    "conversation": {
        "name": "对话摘要",
        "examples": ["上次聊了睡眠问题", "推荐了食疗方案"],
        "retention": "short",
        "sensitive": False
    }
}
```

---

## 记忆生成流程

```python
# 对话后记忆生成
MEMORY_GENERATION_FLOW = {
    "step_1": "对话结束",
    "step_2": "提取关键信息",
    "step_3": "判断是否需要记忆",
    "step_4": "生成摘要",
    "step_5": "存储到长期记忆",
    "step_6": "更新上下文"
}

# 提取示例
EXTRACTION_EXAMPLES = [
    {
        "conversation": "我最近睡眠不好，总是失眠，压力大",
        "extracted": {
            "type": "health",
            "content": "睡眠质量差，失眠",
            "emotion": "压力大",
            "importance": 0.8
        }
    },
    {
        "conversation": "我喜欢喝绿茶，不喝红茶",
        "extracted": {
            "type": "preference",
            "content": "喜欢绿茶",
            "importance": 0.5
        }
    }
]
```

---

## 记忆摘要生成

```python
# 定期生成记忆摘要
SUMMARY_GENERATION = {
    "frequency": "weekly",
    "trigger": "对话次数 > 5",
    "process": [
        "收集本周记忆",
        "去重合并",
        "提取重要模式",
        "生成摘要",
        "存储"
    ]
}

# 摘要示例
WEEKLY_SUMMARY = {
    "week": "2026-03-01 to 2026-03-07",
    "conversation_count": 12,
    "key_themes": ["睡眠", "工作压力", "食疗"],
    "mood_trend": "stable",
    "habits_tracked": ["泡脚", "喝水"],
    "suggestions": [
        "用户对食疗内容感兴趣",
        "睡眠问题持续，建议关注"
    ]
}
```

---

## 记忆使用

```python
# 对话时记忆调用
class MemoryRetriever:
    def retrieve_context(self, user_id: str, current_message: str) -> dict:
        # 1. 获取最近 N 轮对话
        recent_conversations = self.get_recent_conversations(user_id, n=5)
        
        # 2. 获取关键记忆
        key_memories = self.get_key_memories(user_id, limit=10)
        
        # 3. 构建上下文
        context = {
            "recent_topics": self.extract_topics(recent_conversations),
            "preferences": self.extract_preferences(key_memories),
            "health_status": self.extract_health(key_memories),
            "family_info": self.extract_family(key_memories),
            "last_mood": self.extract_last_mood(key_memories)
        }
        
        return context
    
    # 上下文格式化
    def format_for_prompt(self, context: dict) -> str:
        sections = []
        
        if context.get("preferences"):
            sections.append(f"用户偏好：{', '.join(context['preferences'])}")
        
        if context.get("health_status"):
            sections.append(f"健康状态：{context['health_status']}")
        
        if context.get("family_info"):
            sections.append(f"家庭情况：{context['family_info']}")
        
        if context.get("recent_topics"):
            sections.append(f"近期话题：{', '.join(context['recent_topics'])}")
        
        return "\n".join(sections)
```

---

## 隐私控制

```python
# 记忆设置
MEMORY_SETTINGS = {
    "memory_enabled": {
        "default": True,
        "description": "是否开启记忆功能"
    },
    "memory_retention_days": {
        "default": 90,
        "options": [30, 90, 180, 365, -1],  # -1 = 永久
        "description": "记忆保留天数"
    },
    "sensitive_storage": {
        "default": "encrypted",
        "options": ["encrypted", "hashed", "excluded"],
        "description": "敏感信息存储方式"
    }
}

# 敏感数据处理
SENSITIVE_DATA_HANDLING = {
    "health": {
        "storage": "encrypted",
        "display": "摘要",
        "prompt_usage": "模糊描述"
    },
    "emotion": {
        "storage": "encrypted",
        "display": "需要时询问",
        "prompt_usage": "共情参考"
    },
    "family": {
        "storage": "encrypted",
        "display": "需要时询问",
        "prompt_usage": "关怀参考"
    },
    "preference": {
        "storage": "plain",
        "display": "完整",
        "prompt_usage": "直接使用"
    }
}

# 用户隐私操作
PRIVACY_OPERATIONS = {
    "view_summary": "查看记忆摘要",
    "view_detail": "查看记忆详情",
    "delete_memory": "删除单条记忆",
    "clear_category": "清空某类记忆",
    "clear_all": "清空全部记忆",
    "export_data": "导出记忆数据"
}
```

---

## 记忆数据库

```sql
-- 记忆快照
CREATE TABLE memory_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    snapshot_type VARCHAR(50) NOT NULL,
    
    -- 摘要（不存原文）
    summary TEXT NOT NULL,
    
    -- 关键点
    key_points JSONB DEFAULT '[]',
    
    -- 元数据
    emotional_tone VARCHAR(20),
    importance_score FLOAT DEFAULT 0.5,
    is_sensitive BOOLEAN DEFAULT FALSE,
    sensitivity_level VARCHAR(20) DEFAULT 'low'
        CHECK (sensitivity_level IN ('low', 'medium', 'high')),
    
    -- 来源
    source_conversation_id UUID,
    source_message_id UUID,
    
    -- 过期时间
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 人生阶段总结
CREATE TABLE life_phase_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phase VARCHAR(50) NOT NULL,
    summary TEXT NOT NULL,
    
    -- 关键事件
    key_events JSONB DEFAULT '[]',
    
    -- 主题
    themes JSONB DEFAULT '[]',
    
    -- 时间段
    period_start DATE NOT NULL,
    period_end DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 照护状态历史
CREATE TABLE care_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    care_status VARCHAR(20) NOT NULL,
    trigger_event VARCHAR(100),
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_memory_user_id ON memory_snapshots(user_id);
CREATE INDEX idx_memory_type ON memory_snapshots(snapshot_type);
CREATE INDEX idx_memory_created_at ON memory_snapshots(created_at);
CREATE INDEX idx_memory_sensitive ON memory_snapshots(user_id, is_sensitive) 
    WHERE is_sensitive = true;
```

---

## 记忆 API

```python
# API 接口

# 获取记忆摘要
GET /api/v1/memory/summary

# 获取记忆列表
GET /api/v1/memory/list
GET /api/v1/memory/list?type=preference
GET /api/v1/memory/list?type=health
GET /api/v1/memory/list?type=emotion

# 获取单条记忆详情
GET /api/v1/memory/{id}

# 更新记忆
PUT /api/v1/memory/{id}
{
    "summary": "新的摘要",
    "is_important": true
}

# 删除单条记忆
DELETE /api/v1/memory/{id}

# 清空某类记忆
DELETE /api/v1/memory
{
    "type": "emotion"
}

# 清空全部记忆
DELETE /api/v1/memory/all

# 开关记忆功能
PUT /api/v1/memory/toggle
{
    "enabled": true
}

# 设置记忆保留天数
PUT /api/v1/memory/settings
{
    "retention_days": 90
}

# 导出记忆数据
GET /api/v1/memory/export

# 搜索记忆
GET /api/v1/memory/search?q=失眠
```

---

## 记忆前端页面

```dart
// 页面结构
MEMORY_PAGES = {
    "memory_page": {
        "title": "记忆",
        "sections": [
            "记忆开关",
            "记忆摘要",
            "记忆分类"
        ]
    },
    "memory_list_page": {
        "title": "记忆列表",
        "tabs": [
            "偏好",
            "习惯",
            "健康",
            "家庭",
            "情绪"
        ]
    },
    "memory_detail_page": {
        "title": "记忆详情",
        "sections": [
            "摘要",
            "来源",
            "重要性"
        ]
    },
    "memory_settings_page": {
        "title": "记忆设置",
        "options": [
            "开启/关闭记忆",
            "记忆保留时间",
            "清空记忆",
            "导出数据"
        ]
    }
}

// UI 示例
class MemoryCard extends StatelessWidget {
    final MemorySnapshot memory;
    
    Widget build(BuildContext context) {
        return Card(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // 记忆类型标签
                    Chip(label: Text(memory.type)),
                    
                    // 摘要
                    Text(memory.summary),
                    
                    // 关键点
                    if (memory.keyPoints.isNotEmpty)
                        Wrap(
                            children: memory.keyPoints
                                .map((p) => Chip(label: Text(p)))
                                .toList()
                        ),
                    
                    // 时间
                    Text(memory.createdAt),
                    
                    // 删除按钮
                    IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteMemory(memory.id)
                    )
                ]
            )
        );
    }
}
```

---

## 记忆安全

```python
# 安全措施
SECURITY_MEASURES = {
    "encryption": {
        "at_rest": "AES-256 加密",
        "in_transit": "TLS 1.3",
        "key_management": "阿里云 KMS"
    },
    "access_control": {
        "user_isolation": "每个用户只能访问自己的记忆",
        "role_based_access": "内部服务最小权限",
        "audit_log": "所有访问记录日志"
    },
    "data_minimization": {
        "no_raw_storage": "不存原文，只存摘要",
        "auto_expiry": "自动过期机制",
        "sensitive_filtering": "敏感信息脱敏"
    },
    "user_control": {
        "transparency": "用户可查看所有记忆",
        "deletion": "用户可删除任何记忆",
        "portability": "用户可导出数据"
    }
}
```

---

## 订阅级别的记忆差异

```python
# 记忆容量
MEMORY_LIMITS = {
    "free": {
        "memory_days": 7,
        "storage_items": 50,
        "summary_generation": False,
        "sensitive_storage": False
    },
    "yangxin": {
        "memory_days": 30,
        "storage_items": 200,
        "summary_generation": True,
        "sensitive_storage": "encrypted"
    },
    "yiyang": {
        "memory_days": 90,
        "storage_items": 1000,
        "summary_generation": True,
        "sensitive_storage": "encrypted"
    },
    "jiahe": {
        "memory_days": -1,  # unlimited
        "storage_items": -1,  # unlimited
        "summary_generation": True,
        "sensitive_storage": "encrypted"
    }
}
```
