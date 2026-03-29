# 顺时 ShunShi Skill 操作系统完整设计文档

> 版本: 2.0  
> 日期: 2026-03-17  
> 状态: 架构设计终稿  
> 作者: AI Architecture Team  

---

## 目录

1. [Skill 系统架构](#1-skill-系统架构)
2. [300+ Skills 完整 JSON Schema](#2-300-skills-完整-json-schema)
3. [Skill 编排规则](#3-skill-编排规则)
4. [Skill → Model 映射表](#4-skill--model-映射表)
5. [Skill 输出 Schema 定义](#5-skill-输出-schema-定义)
6. [Skill Store 管理方案](#6-skill-store-管理方案)
7. [模型成本估算表](#7-模型成本估算表)
8. [国内版 vs 国际版 Skill 差异](#8-国内版-vs-国际版-skill-差异)

---

## 1. Skill 系统架构

### 1.1 整体调用链路

```
用户输入（文本/语音/点击）
    │
    ▼
┌──────────────────────┐
│   Intent 识别层       │  基于规则 + Embedding 双引擎
│   (Intent Detector)   │  输出: intent_type + confidence + entities
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Skill Router       │  intent → skill_set 映射
│   (技能路由器)        │  输出: 1~3个 skill_id + 执行顺序
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Skill Orchestrator │  依赖解析 + 优先级排序 + 降级决策
│   (技能编排器)        │  输出: execution_plan (有向无环图)
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Skill Execution    │  加载 Skill 定义 + 组装上下文
│   (技能执行器)        │  输出: prompt + model + params
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Prompt 生成器       │  Core Prompt + Policy + Task + Skill
│   (Prompt Builder)    │  输出: 完整 system_prompt + user_prompt
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Model Router       │  根据 skill.recommended_model 路由
│   (模型路由器)        │  含降级链: 首选 → 降级 → 缓存 → Mock
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Schema 解析器       │  JSON Schema 校验 + 自动修复
│   (Schema Validator)  │  输出: validated ShunShiResponse
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   UI 渲染引擎         │  text → 富文本 / cards → 组件树
│   (UI Renderer)       │  输出: Flutter Widget Tree JSON
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│   Follow-up 生成器    │  跟进策略 + 定时触发
│   (Follow-up Engine)  │  输出: follow_up plan (1~7天)
└──────────────────────┘
    │
    ▼
  用户界面展示
```

### 1.2 各层职责定义

| 层级 | 组件 | 职责 | 关键指标 |
|------|------|------|----------|
| L1 | Intent Detector | 文本分类、实体抽取、意图置信度 | 准确率 > 95%, P99 < 100ms |
| L2 | Skill Router | 意图→Skill映射、多Skill组合决策 | 路由准确率 > 98% |
| L3 | Skill Orchestrator | DAG编排、依赖解析、降级策略 | 编排延迟 < 50ms |
| L4 | Skill Execution | 上下文注入、参数校验、缓存查询 | 缓存命中率 > 40% |
| L5 | Prompt Builder | 模板渲染、版本管理、token预估 | token利用率 > 85% |
| L6 | Model Router | 模型选择、降级链、负载均衡 | 降级率 < 5% |
| L7 | Schema Validator | JSON校验、自动修复、兜底生成 | 校验通过率 > 97% |
| L8 | UI Renderer | 组件映射、动画编排、暗色适配 | 渲染帧率 > 60fps |
| L9 | Follow-up Engine | 跟进调度、频率控制、沉默策略 | 用户不打扰率 > 80% |

### 1.3 数据流图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        数据存储层                                     │
├─────────────┬──────────────┬──────────────┬─────────────────────────┤
│  PostgreSQL  │    Redis      │  Skill Registry │   ClickHouse          │
│  用户画像    │  响应缓存     │  (JSON Schema)  │  使用分析/成本追踪     │
│  对话历史    │  限流计数     │  300+ Skills   │  延迟/错误率           │
│  家庭关系    │  Session      │  Prompt模板    │  A/B实验指标          │
└─────────────┴──────────────┴──────────────┴─────────────────────────┘
        ▲              ▲              ▲                 ▲
        │              │              │                 │
        └──────────────┴──────┬───────┴─────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   AI Router Core  │
                    │   (FastAPI)       │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │   Flutter Client  │
                    └───────────────────┘
```

---

## 2. 300+ Skills 完整 JSON Schema

### 2.1 Skill 注册表 Schema（ShunShiSkill）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ShunShiSkill",
  "type": "object",
  "description": "顺时 Skill 注册表条目，定义一个完整的可执行技能单元",
  "properties": {
    "skill_id": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9_]{2,49}$",
      "description": "技能唯一标识符，小写字母开头，蛇形命名"
    },
    "category": {
      "type": "string",
      "enum": [
        "season",
        "constitution",
        "diet",
        "tea",
        "acupoint",
        "exercise",
        "sleep",
        "emotion",
        "lifestyle",
        "daily_plan",
        "reflection",
        "follow_up",
        "family",
        "safety",
        "meta"
      ],
      "description": "技能所属分类"
    },
    "sub_category": {
      "type": ["string", "null"],
      "description": "二级分类，如 season.solar_term、diet.breakfast",
      "pattern": "^[a-z][a-z0-9_]*$"
    },
    "name": {
      "type": "string",
      "minLength": 2,
      "maxLength": 50,
      "description": "技能中文名称"
    },
    "description": {
      "type": "string",
      "minLength": 10,
      "maxLength": 300,
      "description": "技能功能描述"
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "语义化版本号"
    },
    "priority": {
      "type": "string",
      "enum": ["P0", "P1", "P2"],
      "description": "P0=核心必须, P1=重要, P2=辅助"
    },
    "status": {
      "type": "string",
      "enum": ["active", "beta", "deprecated", "disabled"],
      "default": "active",
      "description": "技能生命周期状态"
    },
    "required_context": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "life_stage",
          "age_group",
          "is_premium",
          "solar_term",
          "current_time",
          "current_location",
          "sleep_data",
          "mood_data",
          "activity_data",
          "diet_preferences",
          "allergies",
          "family_members",
          "care_status",
          "conversation_history"
        ]
      },
      "description": "执行此技能必需的用户上下文字段"
    },
    "optional_context": {
      "type": "array",
      "items": { "type": "string" },
      "description": "可选上下文，存在时增强输出质量"
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[a-z][a-z0-9_]*$"
      },
      "maxItems": 20,
      "description": "技能标签，用于检索和分类"
    },
    "intent_keywords": {
      "type": "array",
      "items": { "type": "string" },
      "description": "触发此技能的关键词列表（用于Intent Router）"
    },
    "intent_embedding_threshold": {
      "type": "number",
      "minimum": 0,
      "maximum": 1,
      "default": 0.75,
      "description": "Embedding 相似度阈值，低于此值不触发"
    },
    "output_schema": {
      "$ref": "#/definitions/SkillOutputSpec",
      "description": "技能输出规格定义"
    },
    "recommended_model": {
      "type": "string",
      "enum": [
        "deepseek-v3.2",
        "glm-4.6",
        "qwen3-235b",
        "kimi-k2-thinking",
        "minimax-m2"
      ],
      "description": "推荐的 LLM 模型"
    },
    "fallback_models": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 3,
      "description": "降级模型列表，按优先级排序"
    },
    "max_tokens": {
      "type": "integer",
      "minimum": 100,
      "maximum": 8192,
      "description": "最大输出 token 数"
    },
    "temperature": {
      "type": "number",
      "minimum": 0,
      "maximum": 1,
      "default": 0.7,
      "description": "模型采样温度"
    },
    "prompt_template": {
      "$ref": "#/definitions/PromptTemplate",
      "description": "Prompt 模板定义"
    },
    "is_premium": {
      "type": "boolean",
      "default": false,
      "description": "是否为付费用户专属"
    },
    "available_markets": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["cn", "intl"]
      },
      "default": ["cn", "intl"],
      "description": "可用市场"
    },
    "cooldown_hours": {
      "type": "integer",
      "minimum": 0,
      "default": 0,
      "description": "冷却时间（小时），0=无冷却"
    },
    "rate_limit": {
      "type": "object",
      "properties": {
        "per_hour": { "type": "integer", "minimum": 1 },
        "per_day": { "type": "integer", "minimum": 1 }
      },
      "description": "调用频率限制"
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "skill_id": { "type": "string" },
          "type": { "type": "string", "enum": ["sequential", "parallel", "optional"] },
          "output_key": { "type": "string" },
          "condition": { "type": "string" }
        },
        "required": ["skill_id", "type"]
      },
      "description": "技能依赖关系"
    },
    "cache_config": {
      "type": "object",
      "properties": {
        "enabled": { "type": "boolean", "default": true },
        "ttl_sec": { "type": "integer", "minimum": 0 },
        "key_template": { "type": "string" },
        "vary_by": {
          "type": "array",
          "items": { "type": "string" },
          "description": "缓存分桶维度"
        }
      },
      "description": "缓存策略配置"
    },
    "safety_config": {
      "type": "object",
      "properties": {
        "requires_safety_check": { "type": "boolean", "default": false },
        "banned_phrases": { "type": "array", "items": { "type": "string" } },
        "required_phrases": { "type": "array", "items": { "type": "string" } },
        "crisis_detection": { "type": "boolean", "default": false },
        "medical_boundary": { "type": "boolean", "default": true }
      },
      "description": "安全配置"
    },
    "metrics": {
      "type": "object",
      "properties": {
        "target_latency_ms": { "type": "integer" },
        "target_success_rate": { "type": "number" },
        "cost_per_call_estimate": { "type": "number" }
      },
      "description": "性能与成本目标"
    },
    "changelog": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "version": { "type": "string" },
          "date": { "type": "string", "format": "date" },
          "changes": { "type": "string" },
          "author": { "type": "string" }
        },
        "required": ["version", "date", "changes"]
      },
      "description": "变更日志"
    }
  },
  "required": [
    "skill_id",
    "category",
    "name",
    "description",
    "version",
    "priority",
    "recommended_model",
    "max_tokens",
    "output_schema",
    "prompt_template",
    "safety_config"
  ],
  "definitions": {
    "SkillOutputSpec": {
      "type": "object",
      "properties": {
        "text": {
          "type": "object",
          "properties": {
            "required": { "type": "boolean", "default": true },
            "min_length": { "type": "integer", "minimum": 1 },
            "max_length": { "type": "integer", "maximum": 500 },
            "tone_constraints": {
              "type": "array",
              "items": { "type": "string" }
            }
          }
        },
        "cards": {
          "type": "object",
          "properties": {
            "allowed_types": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": [
                  "acupoint", "food", "tea", "movement",
                  "breathing", "sleep", "solar_term", "note",
                  "meditation", "stretch", "hydration",
                  "habit", "checklist", "tip", "quiz"
                ]
              }
            },
            "min_items": { "type": "integer", "minimum": 0, "default": 0 },
            "max_items": { "type": "integer", "maximum": 3, "default": 1 },
            "require_steps": { "type": "boolean", "default": false },
            "require_contraindications": { "type": "boolean", "default": false }
          }
        },
        "follow_up": {
          "type": "object",
          "properties": {
            "enabled": { "type": "boolean", "default": false },
            "min_days": { "type": "integer", "minimum": 1 },
            "max_days": { "type": "integer", "maximum": 7 }
          }
        },
        "safety_flag_allowed": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["none", "sensitive", "abnormal"]
          }
        }
      }
    },
    "PromptTemplate": {
      "type": "object",
      "properties": {
        "core_prompt_id": { "type": "string" },
        "policy_prompt_id": { "type": "string" },
        "task_prompt": {
          "type": "object",
          "properties": {
            "template": { "type": "string" },
            "variables": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": { "type": "string" },
                  "source": { "type": "string", "enum": ["user_context", "signals", "task_params", "dependency_output"] },
                  "required": { "type": "boolean" },
                  "default": {}
                }
              }
            }
          }
        },
        "system_suffix": { "type": "string" },
        "output_format_instruction": { "type": "string" }
      },
      "required": ["task_prompt"]
    }
  }
}
```

### 2.2 15个 Category 定义

| Category | ID | 中文名 | 说明 | Skill 数量 |
|----------|-----|--------|------|------------|
| season | `season` | 节气养生 | 24节气+季节性养生建议 | 28 |
| constitution | `constitution` | 体质调理 | 九种体质识别与调理 | 22 |
| diet | `diet` | 食疗方案 | 食材搭配、时令食谱、药膳替代 | 38 |
| tea | `tea` | 茶饮养生 | 茶饮推荐、花茶、养生汤饮 | 24 |
| acupoint | `acupoint` | 穴位保健 | 常用穴位按揉、经络导引 | 18 |
| exercise | `exercise` | 运动建议 | 轻量运动、拉伸、户外活动 | 32 |
| sleep | `sleep` | 睡眠管理 | 睡前仪式、睡眠改善、午休 | 26 |
| emotion | `emotion` | 情绪管理 | 情绪急救、正念冥想、解压 | 30 |
| lifestyle | `lifestyle` | 生活习惯 | 办公微休息、用眼、饮水提醒 | 22 |
| daily_plan | `daily_plan` | 每日计划 | 今日节律、时段建议、日程整合 | 18 |
| reflection | `reflection` | 周期总结 | 日/周/月复盘、趋势分析 | 15 |
| follow_up | `follow_up` | 跟进系统 | 系统调度跟进、频率控制 | 12 |
| family | `family` | 家庭关怀 | 家庭成员管理、远程关怀 | 14 |
| safety | `safety` | 安全系统 | 医疗边界、危机检测、红线保护 | 8 |
| meta | `meta` | 元技能 | 系统内部、调试、版本管理 | 10 |
| **合计** | | | | **317** |

---

## 3. Skill 编排规则

### 3.1 编排约束

```
┌─────────────────────────────────────────────┐
│              编排硬约束                        │
├─────────────────────────────────────────────┤
│  • 每次请求: 最少 1 个 Skill，最多 3 个       │
│  • 禁止纯模型自由发挥（零 Skill = 拒绝执行）    │
│  • 有依赖的 Skill 必须按拓扑序执行             │
│  • safety skill 在 DAG 中优先级最高            │
│  • 同一 skill_id 单次请求不可重复              │
│  • 并行 Skill 之间不得存在数据依赖             │
└─────────────────────────────────────────────┘
```

### 3.2 依赖关系解析算法（拓扑排序）

```python
class SkillDAG:
    """
    技能执行有向无环图(DAG)构建与解析
    
    算法: Kahn's Algorithm (BFS拓扑排序)
    复杂度: O(V + E)，V=节点数(≤3)，E=边数(≤3)
    """
    
    def __init__(self, skills: list[SkillDef]):
        self.graph: dict[str, list[str]] = {}      # skill_id -> dependents
        self.in_degree: dict[str, int] = {}
        self.skills = {s.skill_id: s for s in skills}
        
    def build(self) -> list[list[str]]:
        """
        返回: 分层执行计划，每层可并行执行
        例: [["safety_check"], ["daily_plan", "mood_check"], ["follow_up_gen"]]
        """
        # 初始化
        for skill_id in self.skills:
            self.graph[skill_id] = []
            self.in_degree[skill_id] = 0
        
        # 建图
        for skill_id, skill in self.skills.items():
            for dep in skill.dependencies:
                self.graph[dep["skill_id"]].append(skill_id)
                self.in_degree[skill_id] += 1
        
        # BFS拓扑排序
        queue = [sid for sid, deg in self.in_degree.items() if deg == 0]
        layers = []
        
        while queue:
            # 同一层（in_degree为0的节点可并行）
            layer = sorted(queue, key=lambda s: self.skills[s].priority)
            layers.append(layer)
            next_queue = []
            for node in layer:
                for dependent in self.graph[node]:
                    self.in_degree[dependent] -= 1
                    if self.in_degree[dependent] == 0:
                        next_queue.append(dependent)
            queue = next_queue
        
        # 环检测
        if sum(len(l) for l in layers) != len(self.skills):
            raise CyclicDependencyError("技能依赖存在环")
        
        return layers

    def validate(self):
        """校验: skill数量不超过3，无环，无自依赖"""
        assert len(self.skills) <= 3, "单次最多3个Skill"
        assert len(self.skills) >= 1, "至少需要1个Skill"
        for sid, skill in self.skills.items():
            for dep in skill.dependencies:
                assert dep["skill_id"] != sid, f"自依赖: {sid}"
                assert dep["skill_id"] in self.skills, f"依赖不存在: {dep['skill_id']}"
```

### 3.3 优先级排序规则

```
排序优先级（从高到低）:

1. Safety Category (category == "safety")
   → 危机检测时无条件最高优先级

2. User Explicit Request
   → 用户明确请求的 Skill（关键词命中）

3. Priority Field (P0 > P1 > P2)

4. Signal Relevance Score
   → 基于当前信号（睡眠/情绪/活动）计算相关度

5. Recency (最近未被调用的优先)
   → 避免连续推荐相同 Skill

6. Random Noise (低权重随机扰动)
   → 增加多样性
```

### 3.4 降级策略（四级降级链）

```
Level 0: 推荐模型（skill.recommended_model）
    │
    ▼  [模型不可用 / 超时 / 限流]
Level 1: 降级模型（skill.fallback_models[0]）
    │
    ▼  [降级模型也不可用]
Level 2: 缓存响应（Redis，TTL内命中）
    │
    ▼  [缓存未命中]
Level 3: Mock 响应（预定义安全兜底）
    │
    ▼  [Mock也没有（不应该发生）]
Level 4: 系统错误（友好提示 + 日志告警）
```

```python
class ModelDegradationChain:
    """四级降级链实现"""
    
    async def execute(self, skill: SkillDef, prompt: str) -> str:
        # Level 0: 推荐模型
        try:
            return await self.call_model(
                skill.recommended_model, prompt, 
                timeout=skill.metrics.target_latency_ms
            )
        except (ModelUnavailable, TimeoutError, RateLimitError):
            pass
        
        # Level 1: 降级模型
        for fb_model in skill.fallback_models:
            try:
                return await self.call_model(fb_model, prompt, timeout=10000)
            except (ModelUnavailable, TimeoutError, RateLimitError):
                continue
        
        # Level 2: 缓存
        cached = await self.cache.get(self.build_cache_key(skill))
        if cached:
            self.metrics.record("cache_fallback", skill.skill_id)
            return cached
        
        # Level 3: Mock
        mock = self.mock_store.get(skill.skill_id)
        if mock:
            self.metrics.record("mock_fallback", skill.skill_id)
            return mock
        
        # Level 4: 系统错误
        self.metrics.record("total_failure", skill.skill_id)
        self.alerting.fire("skill_execution_failure", skill=skill.skill_id)
        return self.safe_error_response()
```

### 3.5 危机场景强制 Safety Skill

```python
# 危机关键词检测 → 强制注入 SafetySkill
CRISIS_PATTERNS = [
    r"(不想活|想死|自杀|结束生命)",
    r"(自残|割腕|跳楼)",
    r"(家暴|被打|被虐待)",
    r"(胸痛|呼吸困难|昏迷|中风)",
    r"(自杀倾向|想不开)",
]

class SafetyGuard:
    async def check(self, message: str, context: UserContext) -> SafetyResult:
        for pattern in CRISIS_PATTERNS:
            if re.search(pattern, message):
                return SafetyResult(
                    flag="abnormal",
                    forced_skills=["crisis_hotline", "safety_boundary"],
                    override_all=True,    # 覆盖所有其他Skill
                    tone="serious",
                    offline_encouraged=True,
                    log_level="critical"
                )
        return SafetyResult(flag="none")
```

### 3.6 Skill 编排完整流程

```python
async def orchestrate(user_input: str, context: UserContext) -> ShunShiResponse:
    """
    完整编排流程
    
    步骤:
    1. Safety Pre-check
    2. Intent Detection
    3. Skill Selection (1~3)
    4. DAG Build & Sort
    5. Parallel/Sequential Execution
    6. Response Merge
    7. Follow-up Generation
    """
    
    # Step 1: 安全预检
    safety = await safety_guard.check(user_input, context)
    if safety.override_all:
        return await execute_safety_response(safety)
    
    # Step 2: 意图识别（规则 + Embedding 双引擎）
    intent = await intent_detector.detect(
        message=user_input,
        context=context,
        method="hybrid"  # 规则优先，Embedding兜底
    )
    
    # Step 3: Skill 选择
    selected_skills = skill_selector.select(
        intent=intent,
        context=context,
        max_skills=3,
        min_skills=1
    )
    assert 1 <= len(selected_skills) <= 3, "Skill数量越界"
    
    # Step 4: DAG 构建
    dag = SkillDAG(selected_skills)
    execution_plan = dag.build()
    
    # Step 5: 分层执行
    all_outputs = {}
    for layer in execution_plan:
        # 同层并行执行
        results = await asyncio.gather(*[
            execute_skill(skill, context, all_outputs)
            for skill in [selected_skills[sid] for sid in layer]
        ])
        for skill_id, output in zip(layer, results):
            all_outputs[skill_id] = output
    
    # Step 6: 合并响应
    merged = response_merger.merge(all_outputs, selected_skills)
    
    # Step 7: 生成跟进计划
    if any(s.output_schema.follow_up.enabled for s in selected_skills.values()):
        merged.follow_up = await followup_engine.generate(merged, context)
    
    return merged
```

---

## 4. Skill → Model 映射表

### 4.1 模型选型策略

| 模型 | 定位 | 优势 | 适用场景 | 单价(¥/M tokens) |
|------|------|------|----------|-------------------|
| glm-4.6 | 内容生成主力 | 中文能力强，结构化输出稳定 | 节气/食疗/茶饮/穴位/每日计划 | 输入1/输出2 |
| kimi-k2-thinking | 深度分析 | 长上下文，推理能力强 | 体质分析/情绪支持/睡眠分析/家庭 | 输入8/输出16 |
| deepseek-v3.2 | 轻量快速 | 响应快，成本低 | 运动/生活/安全/办公室微休息 | 输入1/输出2 |
| qwen3-235b | 深度总结 | 大参数，综合能力强 | 周期复盘/月度报告 | 输入4/输出8 |
| minimax-m2 | 低成本辅助 | 极低成本，适合简单任务 | 跟进生成/轻量聊天 | 输入0.5/输出1 |

### 4.2 Category → Model 映射

| Category | 推荐模型 | 降级链 | 理由 | 典型 max_tokens |
|----------|----------|--------|------|-----------------|
| `season` | glm-4.6 | deepseek-v3.2 → minimax-m2 | 内容生成，中文节气文案 | 2048 |
| `constitution` | kimi-k2-thinking | glm-4.6 → qwen3-235b | 复杂体质分析，需推理 | 4096 |
| `diet` | glm-4.6 | deepseek-v3.2 → minimax-m2 | 食疗方案，结构化输出 | 2048 |
| `tea` | glm-4.6 | deepseek-v3.2 → minimax-m2 | 茶饮推荐，中文内容生成 | 1536 |
| `acupoint` | glm-4.6 | deepseek-v3.2 → minimax-m2 | 穴位描述，结构化 | 1536 |
| `exercise` | deepseek-v3.2 | minimax-m2 → glm-4.6 | 轻量运动建议，简单 | 1024 |
| `sleep` | kimi-k2-thinking | glm-4.6 → deepseek-v3.2 | 睡眠分析需理解上下文 | 2048 |
| `emotion` | kimi-k2-thinking | glm-4.6 → deepseek-v3.2 | 情绪支持需共情理解 | 2048 |
| `lifestyle` | deepseek-v3.2 | minimax-m2 → glm-4.6 | 生活习惯建议，轻量 | 1024 |
| `daily_plan` | glm-4.6 | kimi-k2-thinking → deepseek-v3.2 | 综合每日计划，需稳定输出 | 3072 |
| `reflection` | qwen3-235b | kimi-k2-thinking → glm-4.6 | 深度复盘总结 | 4096 |
| `follow_up` | minimax-m2 | deepseek-v3.2 → glm-4.6 | 低成本跟进文本 | 512 |
| `family` | kimi-k2-thinking | glm-4.6 → deepseek-v3.2 | 家庭关系复杂场景 | 2048 |
| `safety` | deepseek-v3.2 | glm-4.6 → minimax-m2 | 快速响应，低延迟 | 1024 |
| `meta` | 系统内部 | N/A | 不调用外部模型 | 0 |

### 4.3 模型负载分配预估

```
基于日活 10,000 用户估算:

glm-4.6:        38% (season + diet + tea + acupoint + daily_plan ≈ 120 skills)
kimi-k2-thinking: 22% (constitution + sleep + emotion + family ≈ 92 skills)
deepseek-v3.2:   24% (exercise + lifestyle + safety ≈ 62 skills)
qwen3-235b:       6% (reflection ≈ 15 skills)
minimax-m2:      10% (follow_up ≈ 12 skills + 降级兜底)
```

### 4.4 317 Skills 完整分类清单

#### 4.4.1 season（28 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `solar_term_guide` | 24节气总览 | P0 | glm-4.6 | 2048 |
| `spring_start_guide` | 立春养生 | P1 | glm-4.6 | 1536 |
| `rain_water_guide` | 雨水养生 | P2 | glm-4.6 | 1536 |
| `awakening_insects` | 惊蛰养生 | P1 | glm-4.6 | 1536 |
| `spring_equinox` | 春分养生 | P1 | glm-4.6 | 1536 |
| `clear_bright` | 清明养生 | P1 | glm-4.6 | 1536 |
| `grain_rain` | 谷雨养生 | P2 | glm-4.6 | 1536 |
| `summer_start` | 立夏养生 | P1 | glm-4.6 | 1536 |
| `grain_buds` | 小满养生 | P2 | glm-4.6 | 1536 |
| `grain_in_ear` | 芒种养生 | P2 | glm-4.6 | 1536 |
| `summer_solstice` | 夏至养生 | P1 | glm-4.6 | 1536 |
| `minor_heat` | 小暑养生 | P2 | glm-4.6 | 1536 |
| `major_heat` | 大暑养生 | P2 | glm-4.6 | 1536 |
| `autumn_start` | 立秋养生 | P1 | glm-4.6 | 1536 |
| `end_of_heat` | 处暑养生 | P2 | glm-4.6 | 1536 |
| `white_dew` | 白露养生 | P2 | glm-4.6 | 1536 |
| `autumn_equinox` | 秋分养生 | P1 | glm-4.6 | 1536 |
| `cold_dew` | 寒露养生 | P2 | glm-4.6 | 1536 |
| `frost_descent` | 霜降养生 | P2 | glm-4.6 | 1536 |
| `winter_start` | 立冬养生 | P1 | glm-4.6 | 1536 |
| `minor_snow` | 小雪养生 | P2 | glm-4.6 | 1536 |
| `major_snow` | 大雪养生 | P2 | glm-4.6 | 1536 |
| `winter_solstice` | 冬至养生 | P1 | glm-4.6 | 1536 |
| `minor_cold` | 小寒养生 | P2 | glm-4.6 | 1536 |
| `major_cold` | 大寒养生 | P2 | glm-4.6 | 1536 |
| `seasonal_diet_adjust` | 季节饮食调整 | P1 | glm-4.6 | 2048 |
| `seasonal_exercise_plan` | 季节运动建议 | P1 | glm-4.6 | 1536 |
| `seasonal_mood_care` | 季节情绪调养 | P1 | glm-4.6 | 1536 |

#### 4.4.2 constitution（22 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `constitution_overview` | 九种体质总览 | P0 | kimi-k2-thinking | 4096 |
| `qi_deficiency_analysis` | 气虚质分析 | P1 | kimi-k2-thinking | 3072 |
| `yang_deficiency_analysis` | 阳虚质分析 | P1 | kimi-k2-thinking | 3072 |
| `yin_deficiency_analysis` | 阴虚质分析 | P1 | kimi-k2-thinking | 3072 |
| `phlegm_dampness_analysis` | 痰湿质分析 | P1 | kimi-k2-thinking | 3072 |
| `damp_heat_analysis` | 湿热质分析 | P1 | kimi-k2-thinking | 3072 |
| `blood_stasis_analysis` | 血瘀质分析 | P1 | kimi-k2-thinking | 3072 |
| `qi_stagnation_analysis` | 气郁质分析 | P1 | kimi-k2-thinking | 3072 |
| `special_constitution` | 特禀质分析 | P1 | kimi-k2-thinking | 3072 |
| `balanced_constitution` | 平和质确认 | P1 | kimi-k2-thinking | 2048 |
| `mixed_constitution` | 复合体质分析 | P1 | kimi-k2-thinking | 4096 |
| `constitution_diet_match` | 体质食疗匹配 | P1 | kimi-k2-thinking | 3072 |
| `constitution_exercise_match` | 体质运动匹配 | P1 | kimi-k2-thinking | 2048 |
| `constitution_sleep_match` | 体质睡眠建议 | P1 | kimi-k2-thinking | 2048 |
| `constitution_tea_match` | 体质茶饮匹配 | P1 | kimi-k2-thinking | 2048 |
| `constitution_season_adjust` | 体质四季调养 | P1 | kimi-k2-thinking | 3072 |
| `constitution_quiz_basic` | 体质初筛问卷 | P1 | kimi-k2-thinking | 2048 |
| `constitution_quiz_deep` | 体质深度问卷 | P2 | kimi-k2-thinking | 4096 |
| `constitution_trend_track` | 体质变化追踪 | P2 | kimi-k2-thinking | 2048 |
| `constitution_morning_routine` | 体质晨间建议 | P2 | kimi-k2-thinking | 1536 |
| `constitution_evening_routine` | 体质晚间建议 | P2 | kimi-k2-thinking | 1536 |
| `constitution_age_adjust` | 年龄体质调适 | P2 | kimi-k2-thinking | 2048 |

#### 4.4.3 diet（38 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_diet_plan` | 每日饮食建议 | P0 | glm-4.6 | 2048 |
| `breakfast_recommender` | 早餐推荐 | P1 | glm-4.6 | 1536 |
| `lunch_recommender` | 午餐推荐 | P1 | glm-4.6 | 1536 |
| `dinner_recommender` | 晚餐推荐 | P1 | glm-4.6 | 1536 |
| `snack_recommender` | 加餐推荐 | P2 | glm-4.6 | 1024 |
| `seasonal_food_list` | 当季食材清单 | P1 | glm-4.6 | 2048 |
| `diet_digestion_care` | 消化养护饮食 | P1 | glm-4.6 | 1536 |
| `diet_sleep_care` | 助眠饮食 | P1 | glm-4.6 | 1536 |
| `diet_stress_care` | 解压饮食 | P1 | glm-4.6 | 1536 |
| `diet_eye_care` | 护眼饮食 | P1 | glm-4.6 | 1536 |
| `diet_immunity_care` | 增强免疫力饮食 | P1 | glm-4.6 | 1536 |
| `diet_energy_boost` | 补充精力饮食 | P1 | glm-4.6 | 1536 |
| `diet_weight_manage` | 体重管理饮食 | P2 | glm-4.6 | 2048 |
| `diet_hydration_plan` | 每日饮水计划 | P1 | deepseek-v3.2 | 1024 |
| `diet_allergy_safe` | 过敏原规避饮食 | P1 | glm-4.6 | 1536 |
| `diet_office_worker` | 上班族饮食 | P1 | glm-4.6 | 1536 |
| `diet_student` | 学生饮食 | P1 | glm-4.6 | 1536 |
| `diet_elderly_care` | 老年饮食 | P1 | glm-4.6 | 1536 |
| `diet_child_care` | 儿童饮食 | P2 | glm-4.6 | 1536 |
| `diet_pregnancy_safe` | 孕期饮食 | P2 | glm-4.6 | 2048 |
| `diet_postpartum` | 产后饮食 | P2 | glm-4.6 | 2048 |
| `diet_warm_stomach` | 暖胃饮食 | P1 | glm-4.6 | 1536 |
| `diet_cooling_summer` | 清凉消暑饮食 | P1 | glm-4.6 | 1536 |
| `diet_warming_winter` | 温补冬季饮食 | P1 | glm-4.6 | 1536 |
| `diet_spring_liver` | 春季养肝饮食 | P1 | glm-4.6 | 1536 |
| `diet_autumn_lung` | 秋季润肺饮食 | P1 | glm-4.6 | 1536 |
| `meal_prep_guide` | 备餐指南 | P2 | glm-4.6 | 2048 |
| `dining_out_guide` | 外出就餐建议 | P2 | glm-4.6 | 1536 |
| `late_night_snack_alt` | 宵夜替代方案 | P2 | glm-4.6 | 1024 |
| `diet_mood_food` | 情绪食物推荐 | P1 | glm-4.6 | 1536 |
| `supermarket_guide` | 食材采购指南 | P2 | glm-4.6 | 2048 |
| `diet_coffee_tea_balance` | 咖啡茶饮平衡 | P2 | glm-4.6 | 1024 |
| `diet_before_exercise` | 运动前饮食 | P1 | glm-4.6 | 1024 |
| `diet_after_exercise` | 运动后饮食 | P1 | glm-4.6 | 1024 |
| `diet_morning_fast` | 晨起饮食建议 | P2 | glm-4.6 | 1024 |
| `diet_travel_adapt` | 旅行饮食调整 | P2 | glm-4.6 | 1536 |
| `diet_regional_specialty` | 地方饮食特色 | P2 | glm-4.6 | 1536 |
| `diet_quick_recipe` | 快手食谱 | P1 | glm-4.6 | 1536 |

#### 4.4.4 tea（24 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_tea_recommender` | 每日茶饮推荐 | P0 | glm-4.6 | 1536 |
| `morning_tea` | 晨起茶饮 | P1 | glm-4.6 | 1024 |
| `afternoon_tea` | 下午茶饮 | P1 | glm-4.6 | 1024 |
| `evening_tea` | 晚间茶饮 | P1 | glm-4.6 | 1024 |
| `flower_tea_guide` | 花茶指南 | P1 | glm-4.6 | 1536 |
| `herbal_tea_guide` | 草本茶指南 | P1 | glm-4.6 | 1536 |
| `fruit_tea_guide` | 水果茶指南 | P1 | glm-4.6 | 1536 |
| `green_tea_guide` | 绿茶指南 | P1 | glm-4.6 | 1536 |
| `black_tea_guide` | 红茶指南 | P1 | glm-4.6 | 1536 |
| `oolong_tea_guide` | 乌龙茶指南 | P2 | glm-4.6 | 1536 |
| `puer_tea_guide` | 普洱茶指南 | P2 | glm-4.6 | 1536 |
| `white_tea_guide` | 白茶指南 | P2 | glm-4.6 | 1536 |
| `tea_digestion` | 消化茶饮 | P1 | glm-4.6 | 1024 |
| `tea_calm_nerves` | 安神茶饮 | P1 | glm-4.6 | 1024 |
| `tea_cold_relieve` | 驱寒茶饮 | P1 | glm-4.6 | 1024 |
| `tea_cooling` | 清热茶饮 | P1 | glm-4.6 | 1024 |
| `tea_eye_care` | 护眼茶饮 | P1 | glm-4.6 | 1024 |
| `tea_immunity` | 增免茶饮 | P1 | glm-4.6 | 1024 |
| `tea_season_spring` | 春季茶饮 | P1 | glm-4.6 | 1536 |
| `tea_season_summer` | 夏季茶饮 | P1 | glm-4.6 | 1536 |
| `tea_season_autumn` | 秋季茶饮 | P1 | glm-4.6 | 1536 |
| `tea_season_winter` | 冬季茶饮 | P1 | glm-4.6 | 1536 |
| `tea_brewing_guide` | 泡茶技巧 | P2 | glm-4.6 | 1536 |
| `soup_recipe_guide` | 养生汤品 | P1 | glm-4.6 | 2048 |

#### 4.4.5 acupoint（18 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_acupoint_routine` | 每日穴位保健 | P0 | glm-4.6 | 1536 |
| `head_acupoint` | 头部穴位 | P1 | glm-4.6 | 1536 |
| `face_acupoint` | 面部穴位 | P1 | glm-4.6 | 1536 |
| `neck_shoulder_acupoint` | 颈肩穴位 | P1 | glm-4.6 | 1536 |
| `back_acupoint` | 背部穴位 | P1 | glm-4.6 | 1536 |
| `hand_acupoint` | 手部穴位 | P1 | glm-4.6 | 1536 |
| `foot_acupoint` | 足部穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_stress_relief` | 解压穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_sleep_aid` | 助眠穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_digestion` | 消化穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_eye_care` | 护眼穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_cold_prevention` | 防感穴位 | P1 | glm-4.6 | 1536 |
| `acupoint_menstrual` | 经期舒缓穴位 | P2 | glm-4.6 | 1536 |
| `acupoint_morning` | 晨起穴位 | P2 | glm-4.6 | 1024 |
| `acupoint_evening` | 晚间穴位 | P2 | glm-4.6 | 1024 |
| `acupoint_office` | 办公穴位 | P1 | glm-4.6 | 1536 |
| `meridian_stretch_guide` | 经络导引 | P2 | glm-4.6 | 2048 |
| `acupoint_safety_guide` | 穴位安全须知 | P0 | glm-4.6 | 1024 |

#### 4.4.6 exercise（32 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_exercise_plan` | 每日运动建议 | P0 | deepseek-v3.2 | 1536 |
| `morning_stretch` | 晨起拉伸 | P1 | deepseek-v3.2 | 1024 |
| `evening_walk` | 晚间散步 | P1 | deepseek-v3.2 | 1024 |
| `office_stretch_5min` | 5分钟办公拉伸 | P1 | deepseek-v3.2 | 1024 |
| `neck_relief_exercise` | 颈椎舒缓运动 | P1 | deepseek-v3.2 | 1024 |
| `shoulder_relief` | 肩部放松运动 | P1 | deepseek-v3.2 | 1024 |
| `back_strength` | 背部力量训练 | P1 | deepseek-v3.2 | 1024 |
| `core_exercise` | 核心训练 | P1 | deepseek-v3.2 | 1024 |
| `eye_exercise` | 护眼操 | P1 | deepseek-v3.2 | 1024 |
| `walking_guide` | 步行指南 | P1 | deepseek-v3.2 | 1024 |
| `jogging_guide` | 慢跑指南 | P2 | deepseek-v3.2 | 1536 |
| `yoga_gentle` | 轻柔瑜伽 | P1 | deepseek-v3.2 | 1536 |
| `tai_chi_brief` | 简易太极 | P2 | deepseek-v3.2 | 1536 |
| `standing_desk_exercise` | 站立办公运动 | P2 | deepseek-v3.2 | 1024 |
| `indoor_exercise_rain` | 雨天室内运动 | P2 | deepseek-v3.2 | 1536 |
| `outdoor_exercise_guide` | 户外运动指南 | P1 | deepseek-v3.2 | 1536 |
| `exercise_after_meal` | 饭后运动 | P1 | deepseek-v3.2 | 1024 |
| `exercise_before_sleep` | 睡前运动 | P1 | deepseek-v3.2 | 1024 |
| `exercise_warm_up` | 运动热身 | P1 | deepseek-v3.2 | 1024 |
| `exercise_cool_down` | 运动放松 | P1 | deepseek-v3.2 | 1024 |
| `exercise_weekend_plan` | 周末运动计划 | P2 | deepseek-v3.2 | 1536 |
| `exercise_beginner_plan` | 运动新手计划 | P1 | deepseek-v3.2 | 2048 |
| `exercise_senior_safe` | 老年安全运动 | P2 | deepseek-v3.2 | 1536 |
| `exercise_kid_play` | 儿童运动游戏 | P2 | deepseek-v3.2 | 1536 |
| `breathing_exercise_basic` | 基础呼吸练习 | P1 | deepseek-v3.2 | 1024 |
| `deep_breathing` | 深呼吸法 | P1 | deepseek-v3.2 | 1024 |
| `box_breathing` | 箱式呼吸 | P1 | deepseek-v3.2 | 1024 |
| `478_breathing` | 4-7-8呼吸法 | P1 | deepseek-v3.2 | 1024 |
| `posture_check_guide` | 体态自检 | P1 | deepseek-v3.2 | 1024 |
| `step_goal_guide` | 步数目标建议 | P2 | deepseek-v3.2 | 1024 |
| `exercise_habit_builder` | 运动习惯养成 | P1 | deepseek-v3.2 | 1536 |
| `exercise_recovery` | 运动恢复 | P2 | deepseek-v3.2 | 1024 |

#### 4.4.7 sleep（26 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_sleep_plan` | 每日睡眠建议 | P0 | kimi-k2-thinking | 2048 |
| `sleep_wind_down` | 睡前仪式 | P0 | kimi-k2-thinking | 2048 |
| `sleep_wind_down_10min` | 10分钟睡前 | P1 | kimi-k2-thinking | 1536 |
| `sleep_wind_down_20min` | 20分钟睡前 | P1 | kimi-k2-thinking | 1536 |
| `sleep_wind_down_30min` | 30分钟睡前 | P1 | kimi-k2-thinking | 2048 |
| `sleep_environment` | 睡眠环境优化 | P1 | kimi-k2-thinking | 1536 |
| `sleep_position_guide` | 睡姿建议 | P2 | kimi-k2-thinking | 1024 |
| `nap_guide` | 午休指南 | P1 | kimi-k2-thinking | 1024 |
| `sleep_caffeine_rule` | 咖啡因规则 | P1 | kimi-k2-thinking | 1024 |
| `sleep_screen_rule` | 屏幕使用建议 | P1 | kimi-k2-thinking | 1024 |
| `sleep_anxiety_relief` | 睡前焦虑缓解 | P1 | kimi-k2-thinking | 1536 |
| `sleep_wake_up_routine` | 晨起仪式 | P1 | kimi-k2-thinking | 1536 |
| `sleep_schedule_optimizer` | 作息优化 | P1 | kimi-k2-thinking | 2048 |
| `sleep_trend_analysis` | 睡眠趋势分析 | P1 | kimi-k2-thinking | 2048 |
| `sleep_score_interpret` | 睡眠数据解读 | P2 | kimi-k2-thinking | 2048 |
| `sleep_journey_record` | 睡眠日记 | P2 | kimi-k2-thinking | 1536 |
| `sleep_sound_guide` | 助眠声音 | P2 | kimi-k2-thinking | 1024 |
| `sleep_aromatherapy` | 助眠香薰 | P2 | kimi-k2-thinking | 1024 |
| `sleep_bath_guide` | 助眠泡脚/澡 | P1 | kimi-k2-thinking | 1024 |
| `sleep_diet_evening` | 晚间饮食建议 | P1 | kimi-k2-thinking | 1024 |
| `sleep_exercise_timing` | 运动时间建议 | P1 | kimi-k2-thinking | 1024 |
| `sleep_jet_lag` | 倒时差建议 | P2 | kimi-k2-thinking | 1536 |
| `sleep_shift_worker` | 倒班睡眠 | P2 | kimi-k2-thinking | 1536 |
| `sleep_child_guide` | 儿童睡眠 | P2 | kimi-k2-thinking | 1536 |
| `sleep_elderly_guide` | 老年睡眠 | P2 | kimi-k2-thinking | 1536 |
| `insomnia_coping` | 失眠应对 | P1 | kimi-k2-thinking | 2048 |

#### 4.4.8 emotion（30 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `mood_first_aid` | 情绪急救 | P0 | kimi-k2-thinking | 2048 |
| `mood_check_in` | 情绪签到 | P1 | kimi-k2-thinking | 1024 |
| `stress_management` | 压力管理 | P1 | kimi-k2-thinking | 2048 |
| `anxiety_coping` | 焦虑应对 | P1 | kimi-k2-thinking | 2048 |
| `anger_management` | 愤怒管理 | P1 | kimi-k2-thinking | 2048 |
| `sadness_comfort` | 悲伤安慰 | P1 | kimi-k2-thinking | 2048 |
| `loneliness_companionship` | 孤独陪伴 | P1 | kimi-k2-thinking | 2048 |
| `mindfulness_5min` | 5分钟正念 | P1 | kimi-k2-thinking | 1536 |
| `mindfulness_10min` | 10分钟正念 | P1 | kimi-k2-thinking | 1536 |
| `mindfulness_body_scan` | 身体扫描冥想 | P1 | kimi-k2-thinking | 2048 |
| `gratitude_journal` | 感恩日记 | P2 | kimi-k2-thinking | 1536 |
| `positive_affirmation` | 正向暗示 | P2 | kimi-k2-thinking | 1024 |
| `emotion_labeling` | 情绪命名 | P1 | kimi-k2-thinking | 1024 |
| `emotion_regulation` | 情绪调节 | P1 | kimi-k2-thinking | 2048 |
| `burnout_detection` | 倦怠检测 | P1 | kimi-k2-thinking | 2048 |
| `burnout_prevention` | 倦怠预防 | P1 | kimi-k2-thinking | 2048 |
| `work_life_balance` | 工作生活平衡 | P1 | kimi-k2-thinking | 2048 |
| `social_connection_guide` | 社交连接建议 | P2 | kimi-k2-thinking | 1536 |
| `nature_therapy` | 自然疗愈 | P2 | kimi-k2-thinking | 1536 |
| `art_therapy_suggest` | 艺术疗愈建议 | P2 | kimi-k2-thinking | 1536 |
| `music_therapy` | 音乐疗愈 | P2 | kimi-k2-thinking | 1536 |
| `journaling_guide` | 写作疗愈 | P2 | kimi-k2-thinking | 1536 |
| `self_compassion` | 自我关怀 | P1 | kimi-k2-thinking | 2048 |
| `worry_time_setting` | 设定担忧时间 | P2 | kimi-k2-thinking | 1024 |
| `emotion_wave_riding` | 情绪冲浪 | P1 | kimi-k2-thinking | 1536 |
| `seasonal_mood_care` | 季节情绪调养 | P1 | kimi-k2-thinking | 1536 |
| `pms_emotion_care` | 经期情绪 | P2 | kimi-k2-thinking | 1536 |
| `emotion_trend_analysis` | 情绪趋势分析 | P2 | kimi-k2-thinking | 2048 |
| `resilience_building` | 心理韧性构建 | P1 | kimi-k2-thinking | 2048 |
| `crisis_support` | 危机支持 | P0 | kimi-k2-thinking | 2048 |

#### 4.4.9 lifestyle（22 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `office_micro_break` | 办公微休息 | P0 | deepseek-v3.2 | 1024 |
| `hydration_reminder` | 饮水提醒 | P1 | deepseek-v3.2 | 512 |
| `eye_care_20_20_20` | 20-20-20护眼 | P1 | deepseek-v3.2 | 1024 |
| `posture_check` | 体态检查 | P1 | deepseek-v3.2 | 1024 |
| `screen_time_advice` | 屏幕时间建议 | P1 | deepseek-v3.2 | 1024 |
| `morning_routine` | 晨间惯例 | P1 | deepseek-v3.2 | 1536 |
| `evening_routine` | 晚间惯例 | P1 | deepseek-v3.2 | 1536 |
| `weekly_routine` | 周度惯例 | P2 | deepseek-v3.2 | 1536 |
| `commute_wellness` | 通勤养生 | P1 | deepseek-v3.2 | 1024 |
| `desk_ergonomics` | 桌面人体工学 | P1 | deepseek-v3.2 | 1024 |
| `lighting_advice` | 光照建议 | P2 | deepseek-v3.2 | 1024 |
| `temperature_advice` | 室温建议 | P2 | deepseek-v3.2 | 512 |
| `noise_management` | 噪音管理 | P2 | deepseek-v3.2 | 1024 |
| `plant_care_guide` | 绿植养护 | P2 | deepseek-v3.2 | 1024 |
| `digital_detox` | 数字断联 | P2 | deepseek-v3.2 | 1024 |
| `habit_tracking_setup` | 习惯追踪设置 | P1 | deepseek-v3.2 | 1024 |
| `micro_habit_builder` | 微习惯养成 | P1 | deepseek-v3.2 | 1536 |
| `time_management` | 时间管理 | P2 | deepseek-v3.2 | 1536 |
| `declutter_guide` | 整理空间 | P2 | deepseek-v3.2 | 1024 |
| `bathroom_wellness` | 洗漱养生 | P2 | deepseek-v3.2 | 1024 |
| `clothing_seasonal` | 季节穿衣 | P2 | deepseek-v3.2 | 1024 |
| `sun_exposure_guide` | 日晒建议 | P2 | deepseek-v3.2 | 1024 |

#### 4.4.10 daily_plan（18 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_rhythm_plan` | 今日节律 | P0 | glm-4.6 | 3072 |
| `morning_plan` | 早间计划 | P1 | glm-4.6 | 2048 |
| `afternoon_plan` | 午间计划 | P1 | glm-4.6 | 2048 |
| `evening_plan` | 晚间计划 | P1 | glm-4.6 | 2048 |
| `weekly_plan` | 本周计划 | P1 | glm-4.6 | 3072 |
| `monthly_plan` | 本月计划 | P2 | glm-4.6 | 4096 |
| `weekend_plan` | 周末计划 | P1 | glm-4.6 | 2048 |
| `holiday_plan` | 假日计划 | P2 | glm-4.6 | 2048 |
| `travel_wellness_plan` | 旅行养生计划 | P2 | glm-4.6 | 3072 |
| `workday_plan` | 工作日计划 | P1 | glm-4.6 | 2048 |
| `rest_day_plan` | 休息日计划 | P1 | glm-4.6 | 2048 |
| `plan_conflict_resolve` | 计划冲突解决 | P2 | glm-4.6 | 2048 |
| `daily_insight` | 每日洞察 | P1 | glm-4.6 | 1536 |
| `daily_affirmation` | 每日肯定语 | P2 | glm-4.6 | 512 |
| `time_block_suggest` | 时间块建议 | P2 | glm-4.6 | 1536 |
| `daily_three_things` | 每日三件事 | P1 | glm-4.6 | 1024 |
| `priority_matrix_guide` | 优先级矩阵 | P2 | glm-4.6 | 1536 |
| `schedule_flexibility` | 计划弹性建议 | P2 | glm-4.6 | 1536 |

#### 4.4.11 reflection（15 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `daily_reflection` | 每日复盘 | P1 | qwen3-235b | 3072 |
| `weekly_reflection` | 每周复盘 | P1 | qwen3-235b | 4096 |
| `monthly_reflection` | 每月复盘 | P2 | qwen3-235b | 4096 |
| `sleep_trend_report` | 睡眠趋势报告 | P1 | qwen3-235b | 3072 |
| `emotion_trend_report` | 情绪趋势报告 | P1 | qwen3-235b | 3072 |
| `activity_trend_report` | 活动趋势报告 | P2 | qwen3-235b | 3072 |
| `diet_trend_report` | 饮食趋势报告 | P2 | qwen3-235b | 3072 |
| `wellness_score_summary` | 养生评分汇总 | P2 | qwen3-235b | 2048 |
| `goal_progress_check` | 目标进度检查 | P1 | qwen3-235b | 2048 |
| `habit_streak_review` | 习惯打卡回顾 | P2 | qwen3-235b | 2048 |
| `season_transition_review` | 季节交替总结 | P1 | qwen3-235b | 3072 |
| `quarterly_review` | 季度总结 | P2 | qwen3-235b | 4096 |
| `yearly_review` | 年度总结 | P2 | qwen3-235b | 4096 |
| `personal_growth_insight` | 成长洞察 | P2 | qwen3-235b | 3072 |
| `wellness_prediction` | 养生趋势预测 | P2 | qwen3-235b | 2048 |

#### 4.4.12 follow_up（12 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `follow_up_generator` | 跟进生成器 | P1 | minimax-m2 | 512 |
| `follow_up_sleep` | 睡眠跟进 | P1 | minimax-m2 | 512 |
| `follow_up_emotion` | 情绪跟进 | P1 | minimax-m2 | 512 |
| `follow_up_habit` | 习惯跟进 | P1 | minimax-m2 | 512 |
| `follow_up_diet` | 饮食跟进 | P2 | minimax-m2 | 512 |
| `follow_up_exercise` | 运动跟进 | P2 | minimax-m2 | 512 |
| `follow_up_weekly_check` | 每周检查 | P1 | minimax-m2 | 512 |
| `follow_up_inactivity` | 沉默用户跟进 | P1 | minimax-m2 | 512 |
| `follow_up_returning` | 回归用户跟进 | P1 | minimax-m2 | 512 |
| `follow_up_milestone` | 里程碑跟进 | P2 | minimax-m2 | 512 |
| `presence_policy_decider` | 退让策略 | P1 | minimax-m2 | 256 |
| `care_status_updater` | 照护状态更新 | P1 | minimax-m2 | 256 |

#### 4.4.13 family（14 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `family_care_digest` | 家庭关怀摘要 | P1 | kimi-k2-thinking | 2048 |
| `family_member_profile` | 家庭成员画像 | P1 | kimi-k2-thinking | 2048 |
| `family_morning_check` | 家庭早安检查 | P1 | kimi-k2-thinking | 1536 |
| `family_evening_check` | 家庭晚安检查 | P1 | kimi-k2-thinking | 1536 |
| `parent_health_reminder` | 父母健康提醒 | P1 | kimi-k2-thinking | 1536 |
| `parent_solar_term` | 父母节气提醒 | P1 | kimi-k2-thinking | 1536 |
| `parent_exercise_remind` | 父母运动提醒 | P2 | kimi-k2-thinking | 1024 |
| `parent_diet_remind` | 父母饮食提醒 | P2 | kimi-k2-thinking | 1024 |
| `child_growth_track` | 儿童成长追踪 | P2 | kimi-k2-thinking | 2048 |
| `family_activity_suggest` | 家庭活动建议 | P1 | kimi-k2-thinking | 1536 |
| `family_emotional_check` | 家庭情绪关怀 | P1 | kimi-k2-thinking | 2048 |
| `care_distance_bridge` | 远程关怀桥梁 | P1 | kimi-k2-thinking | 1536 |
| `family_emergency_guide` | 家庭应急指南 | P2 | kimi-k2-thinking | 1536 |
| `family_wellness_report` | 家庭健康报告 | P2 | kimi-k2-thinking | 3072 |

#### 4.4.14 safety（8 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `safety_boundary` | 安全边界守护 | P0 | deepseek-v3.2 | 1024 |
| `medical_redirect` | 医疗需求引导 | P0 | deepseek-v3.2 | 1024 |
| `crisis_hotline` | 危机热线提供 | P0 | deepseek-v3.2 | 512 |
| `content_safety_filter` | 内容安全过滤 | P0 | deepseek-v3.2 | 512 |
| `medication_safety` | 用药安全提醒 | P0 | deepseek-v3.2 | 1024 |
| `emergency_guide` | 紧急情况指南 | P0 | deepseek-v3.2 | 1024 |
| `allergy_warning` | 过敏原警告 | P1 | deepseek-v3.2 | 1024 |
| `pregnancy_safety` | 孕期安全提醒 | P1 | deepseek-v3.2 | 1024 |

#### 4.4.15 meta（10 skills）

| skill_id | name | priority | recommended_model | max_tokens |
|----------|------|----------|-------------------|------------|
| `skill_registry_sync` | Skill注册表同步 | P0 | 系统内部 | 0 |
| `prompt_version_manager` | Prompt版本管理 | P0 | 系统内部 | 0 |
| `model_health_check` | 模型健康检查 | P0 | 系统内部 | 0 |
| `cache_warmer` | 缓存预热 | P1 | 系统内部 | 0 |
| `metrics_collector` | 指标收集 | P0 | 系统内部 | 0 |
| `ab_experiment_router` | A/B实验路由 | P1 | 系统内部 | 0 |
| `skill_deprecation_handler` | Skill废弃处理 | P2 | 系统内部 | 0 |
| `config_hot_reload` | 配置热加载 | P1 | 系统内部 | 0 |
| `audit_logger` | 审计日志 | P0 | 系统内部 | 0 |
| `system_diagnostic` | 系统诊断 | P2 | 系统内部 | 0 |

**317 Skills 总计统计:**

| Category | 数量 | P0 | P1 | P2 |
|----------|------|----|----|-----|
| season | 28 | 1 | 16 | 11 |
| constitution | 22 | 1 | 16 | 5 |
| diet | 38 | 1 | 25 | 12 |
| tea | 24 | 1 | 17 | 6 |
| acupoint | 18 | 2 | 12 | 4 |
| exercise | 32 | 1 | 20 | 11 |
| sleep | 26 | 2 | 16 | 8 |
| emotion | 30 | 2 | 20 | 8 |
| lifestyle | 22 | 1 | 13 | 8 |
| daily_plan | 18 | 1 | 10 | 7 |
| reflection | 15 | 0 | 5 | 10 |
| follow_up | 12 | 0 | 8 | 4 |
| family | 14 | 0 | 10 | 4 |
| safety | 8 | 6 | 2 | 0 |
| meta | 10 | 5 | 3 | 2 |
| **合计** | **317** | **24** | **193** | **100** |

---

## 5. Skill 输出 Schema 定义

### 5.1 ShunShiResponse v2 完整 Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ShunShiResponse",
  "type": "object",
  "description": "顺时 Skill 统一输出格式 v2，所有 Skill 必须遵循此 Schema",
  "required": [
    "version", "text", "tone", "care_status", "presence_level",
    "offline_encouraged", "safety_flag", "meta"
  ],
  "properties": {
    "version": {
      "type": "string",
      "enum": ["2.0"],
      "description": "Schema版本"
    },

    "text": {
      "type": "string",
      "minLength": 1,
      "maxLength": 500,
      "description": "对用户可见的主要文本内容（50-300字为宜）"
    },

    "tone": {
      "type": "string",
      "enum": ["gentle", "neutral", "cheerful", "calm", "serious"],
      "description": "回复语气，影响UI渲染风格"
    },

    "care_status": {
      "type": "string",
      "enum": ["stable", "needs_attention", "escalate"],
      "description": "内部照护状态（不直接展示给用户）"
    },

    "presence_level": {
      "type": "string",
      "enum": ["normal", "reduced", "silent"],
      "description": "触达级别，控制后续消息推送频率"
    },

    "offline_encouraged": {
      "type": "boolean",
      "default": false,
      "description": "是否鼓励用户线下/现实连接"
    },

    "safety_flag": {
      "type": "string",
      "enum": ["none", "sensitive", "abnormal"],
      "default": "none",
      "description": "安全标记：sensitive=敏感内容, abnormal=异常需人工"
    },

    "safety_details": {
      "type": ["object", "null"],
      "description": "当safety_flag不为none时提供详情",
      "properties": {
        "detected_pattern": { "type": "string" },
        "recommended_action": {
          "type": "string",
          "enum": ["log_only", "soft_redirect", "hotline_provide", "alert_human"]
        },
        "hotline_number": { "type": ["string", "null"] },
        "additional_resources": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },

    "cards": {
      "type": "array",
      "maxItems": 3,
      "description": "内容卡片数组，每个卡片对应一个UI组件",
      "items": {
        "type": "object",
        "required": ["type", "title"],
        "properties": {
          "type": {
            "type": "string",
            "enum": [
              "acupoint", "food", "tea", "movement", "breathing",
              "sleep", "solar_term", "note", "meditation", "stretch",
              "hydration", "habit", "checklist", "tip", "quiz",
              "progress", "comparison", "reminder"
            ],
            "description": "卡片类型，映射到Flutter Widget"
          },
          "title": {
            "type": "string",
            "maxLength": 50,
            "description": "卡片标题"
          },
          "subtitle": {
            "type": "string",
            "maxLength": 100,
            "description": "卡片副标题"
          },
          "emoji": {
            "type": "string",
            "maxLength": 4,
            "description": "卡片图标emoji"
          },
          "body": {
            "type": "string",
            "maxLength": 500,
            "description": "卡片正文内容"
          },
          "steps": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "step": { "type": "integer" },
                "instruction": { "type": "string", "maxLength": 100 },
                "duration_sec": { "type": "integer" },
                "image_url": { "type": ["string", "null"] }
              },
              "required": ["step", "instruction"]
            },
            "description": "分步操作指引"
          },
          "duration_min": {
            "type": "integer",
            "minimum": 1,
            "maximum": 120,
            "description": "建议持续时间（分钟）"
          },
          "contraindications": {
            "type": "array",
            "items": { "type": "string" },
            "description": "禁忌事项（医疗安全红线）"
          },
          "tips": {
            "type": "array",
            "items": { "type": "string" },
            "maxItems": 5,
            "description": "小贴士"
          },
          "media": {
            "type": "object",
            "properties": {
              "image_url": { "type": ["string", "null"] },
              "video_url": { "type": ["string", "null"] },
              "audio_url": { "type": ["string", "null"] },
              "image_id": { "type": ["string", "null"] },
              "video_id": { "type": ["string", "null"] }
            },
            "description": "多媒体资源"
          },
          "cta": {
            "type": "object",
            "properties": {
              "label": { "type": "string", "maxLength": 20 },
              "action": {
                "type": "string",
                "enum": ["open_detail", "save", "start_timer", "share", "navigate", "none"]
              },
              "payload": {
                "type": "object",
                "properties": {
                  "id": { "type": "string" },
                  "route": { "type": "string" },
                  "duration_min": { "type": "integer" }
                }
              }
            },
            "description": "行动号召按钮"
          },
          "color_theme": {
            "type": "string",
            "enum": ["green", "blue", "warm", "calm", "energy", "neutral"],
            "description": "卡片主题色"
          }
        }
      }
    },

    "suggestions": {
      "type": "array",
      "maxItems": 5,
      "description": "快捷建议（用户可点击）",
      "items": {
        "type": "object",
        "properties": {
          "text": { "type": "string", "maxLength": 50 },
          "action": {
            "type": "string",
            "enum": ["chat", "navigate", "skill_run", "timer"]
          },
          "payload": {
            "type": "object",
            "properties": {
              "message": { "type": "string" },
              "skill_id": { "type": "string" },
              "route": { "type": "string" },
              "duration_min": { "type": "integer" }
            }
          }
        },
        "required": ["text", "action"]
      }
    },

    "follow_up": {
      "type": ["object", "null"],
      "description": "跟进计划",
      "properties": {
        "in_days": {
          "type": "integer",
          "minimum": 1,
          "maximum": 7,
          "description": "几天后跟进"
        },
        "intent": {
          "type": "string",
          "enum": ["sleep_check", "emotion_check", "habit_check", "diet_check", "exercise_check", "none"],
          "description": "跟进意图"
        },
        "message_hint": {
          "type": "string",
          "maxLength": 200,
          "description": "跟进消息提示（给模型的参考）"
        },
        "allow_dismiss": {
          "type": "boolean",
          "default": true,
          "description": "是否允许用户忽略"
        }
      }
    },

    "status": {
      "type": "object",
      "description": "执行状态信息",
      "properties": {
        "skill_chain": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "skill_id": { "type": "string" },
              "status": {
                "type": "string",
                "enum": ["success", "fallback", "cached", "mock", "error"]
              },
              "latency_ms": { "type": "integer" }
            }
          },
          "description": "Skill执行链"
        },
        "model_used": {
          "type": "string",
          "description": "实际使用的模型"
        },
        "tokens": {
          "type": "object",
          "properties": {
            "input": { "type": "integer" },
            "output": { "type": "integer" },
            "total": { "type": "integer" }
          }
        }
      }
    },

    "meta": {
      "type": "object",
      "required": ["skill", "skill_version"],
      "properties": {
        "skill": { "type": "string", "description": "主Skill ID" },
        "skill_version": { "type": "string", "description": "Skill版本号" },
        "secondary_skills": {
          "type": "array",
          "items": { "type": "string" },
          "description": "辅助Skill列表"
        },
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
        "repair_count": {
          "type": "integer",
          "minimum": 0,
          "description": "Schema修复次数"
        },
        "ab_group": {
          "type": ["string", "null"],
          "description": "A/B实验分组"
        },
        "locale": {
          "type": "string",
          "enum": ["zh_CN", "zh_TW", "en_US"],
          "default": "zh_CN"
        }
      }
    }
  }
}
```

### 5.2 输出示例

```json
{
  "version": "2.0",
  "text": "今天春分，阴阳各半。你最近睡得晚了一些，试试今晚10:30放下手机，泡一杯百合枸杞茶，给身体一个平衡的起点。",
  "tone": "gentle",
  "care_status": "stable",
  "presence_level": "normal",
  "offline_encouraged": false,
  "safety_flag": "none",
  "cards": [
    {
      "type": "tea",
      "title": "春分安神茶",
      "subtitle": "百合5g + 枸杞3g + 冰糖适量",
      "emoji": "🍵",
      "steps": [
        { "step": 1, "instruction": "百合提前泡发30分钟" },
        { "step": 2, "instruction": "加水500ml大火煮开" },
        { "step": 3, "instruction": "转小火煮15分钟" },
        { "step": 4, "instruction": "加枸杞焖5分钟即可" }
      ],
      "duration_min": 20,
      "contraindications": ["糖尿病者少加冰糖", "感冒发热时停用"],
      "cta": { "label": "保存食谱", "action": "save", "payload": { "id": "tea_spring_equinox_001" } },
      "color_theme": "warm"
    }
  ],
  "suggestions": [
    { "text": "今晚试试睡前仪式", "action": "skill_run", "payload": { "skill_id": "sleep_wind_down_20min" } },
    { "text": "春分养生要点", "action": "skill_run", "payload": { "skill_id": "spring_equinox" } }
  ],
  "follow_up": {
    "in_days": 2,
    "intent": "sleep_check",
    "message_hint": "春分之后睡得怎么样",
    "allow_dismiss": true
  },
  "status": {
    "skill_chain": [
      { "skill_id": "solar_term_guide", "status": "success", "latency_ms": 820 },
      { "skill_id": "daily_tea_recommender", "status": "success", "latency_ms": 650 }
    ],
    "model_used": "glm-4.6",
    "tokens": { "input": 1280, "output": 856, "total": 2136 }
  },
  "meta": {
    "skill": "solar_term_guide",
    "skill_version": "1.0.0",
    "secondary_skills": ["daily_tea_recommender"],
    "prompt_version": { "core": "SS_CORE_v2", "policy": "SS_POLICY_FREE", "task": "SS_TASK_SOLAR_v1" },
    "cache": { "hit": false, "key": "solar:chunfen:cn:explore", "ttl_sec": 604800 },
    "repair_count": 0,
    "locale": "zh_CN"
  }
}
```

### 5.3 Tone → UI 渲染映射

| tone | Flutter Widget Style | 字体颜色 | 动画 | 背景 |
|------|---------------------|----------|------|------|
| gentle | RoundedCard + FadeIn | #5B7B6F (灰绿) | 柔和渐入 | 暖白 |
| neutral | StandardCard + SlideIn | #333333 (深灰) | 滑入 | 白色 |
| cheerful | BouncyCard + ScaleIn | #E8A838 (暖黄) | 弹跳 | 浅黄 |
| calm | BlurCard + DissolveIn | #6B8EAE (灰蓝) | 溶解 | 淡蓝 |
| serious | AlertCard + ShakeIn | #8B4513 (棕) | 轻震 | 暖灰 |

---

## 6. Skill Store 管理方案

### 6.1 版本管理

```yaml
版本策略: 语义化版本 (SemVer)

Major (X.0.0):
  - 输出Schema不兼容变更
  - 依赖模型变更
  - 核心逻辑重构

Minor (0.X.0):
  - 新增输出字段
  - 新增可选参数
  - Prompt优化迭代

Patch (0.0.X):
  - Bug修复
  - 文案微调
  - 安全规则更新

发布流程:
  1. Skill开发 → 提交PR到skill-registry仓库
  2. 自动运行Schema校验 + 单元测试
  3. 人工Review (至少1人)
  4. 合并到main → 自动构建
  5. 灰度发布 (见6.2)
  6. 全量发布
  7. 回滚机制: 一键回退到上一版本
```

### 6.2 灰度发布

```
灰度阶段:

Phase 0: 内部测试 (0.1%)
  - 仅限内部账号
  - 自动监控所有指标
  - 持续时间: 24h

Phase 1: 小流量灰度 (1%)
  - 随机1%用户
  - A/B对照组: 新版本 vs 旧版本
  - 持续时间: 48h
  - 退出条件: 错误率 < 0.1%, 延迟P99 < 3s

Phase 2: 中流量灰度 (10%)
  - 扩展到10%用户
  - 持续时间: 72h
  - 退出条件: 用户好评率 > 原版, 无安全事件

Phase 3: 全量 (100%)
  - 全部用户
  - 保留7天回滚窗口

自动回滚触发条件:
  - 错误率 > 1%
  - Schema校验通过率 < 90%
  - 安全标记 "abnormal" 率 > 5%
  - 平均延迟 > 5s
  - 人工标记紧急回滚
```

### 6.3 A/B 测试

```python
class ABExperiment:
    """
    A/B实验框架
    
    实验维度:
    - prompt版本 (v1 vs v2)
    - 模型选择 (glm vs kimi)
    - 输出格式 (text vs cards)
    - 跟进策略 (aggressive vs passive)
    """
    
    # 实验配置示例
    experiments = {
        "exp_daily_plan_prompt_v2": {
            "skill_id": "daily_rhythm_plan",
            "variants": {
                "control": {"prompt_version": "v1"},
                "treatment": {"prompt_version": "v2"}
            },
            "traffic_allocation": {"control": 0.5, "treatment": 0.5},
            "metrics": [
                "user_satisfaction_score",    # 主指标
                "follow_up_click_rate",       # 辅指标
                "card_interaction_rate",      # 辅指标
                "schema_validation_rate",     # 护栏指标
                "latency_p99"                 # 护栏指标
            ],
            "min_sample_size": 1000,
            "duration_days": 14,
            "significance_level": 0.05
        }
    }
    
    def assign_variant(self, user_id: str, experiment_id: str) -> str:
        """基于用户ID的确定性分流（同一用户始终在同一组）"""
        hash_val = hashlib.md5(f"{user_id}:{experiment_id}".encode()).hexdigest()
        bucket = int(hash_val[:8], 16) % 10000
        exp = self.experiments[experiment_id]
        cumulative = 0
        for variant, allocation in exp["traffic_allocation"].items():
            cumulative += int(allocation * 10000)
            if bucket < cumulative:
                return variant
        return "control"
```

### 6.4 使用统计

```
统计维度:

1. 调用量统计 (按日/周/月)
   - 每个skill_id的调用次数
   - 按category聚合
   - 按user_segment分桶 (free/premium/life_stage)

2. 质量指标
   - Schema校验通过率 (目标 > 97%)
   - 用户满意度评分 (1-5星)
   - follow_up点击率
   - card交互率
   - 不打扰率 (用户不打扰的比例)

3. 性能指标
   - P50/P95/P99延迟
   - 模型调用延迟
   - 缓存命中率
   - 降级率
   - 错误率

4. 业务指标
   - DAU/MAU
   - 用户留存率 (次日/7日/30日)
   - 付费转化率
   - 人均Skill调用次数

存储: ClickHouse (OLAP)，按天分区
展示: Grafana Dashboard + 内部管理后台
```

### 6.5 成本追踪

```python
class CostTracker:
    """
    成本追踪系统
    
    追踪维度: skill_id × model × date
    """
    
    # 每日成本报告结构
    daily_report = {
        "date": "2026-03-17",
        "total_cost_cny": 1234.56,
        "per_user_avg_cny": 0.12,
        "by_model": {
            "glm-4.6": {"calls": 50000, "cost": 450.0, "tokens_in": 12_500_000, "tokens_out": 8_000_000},
            "kimi-k2-thinking": {"calls": 28000, "cost": 380.0, "tokens_in": 7_000_000, "tokens_out": 4_500_000},
            "deepseek-v3.2": {"calls": 30000, "cost": 210.0, "tokens_in": 8_000_000, "tokens_out": 5_000_000},
            "qwen3-235b": {"calls": 8000, "cost": 120.0, "tokens_in": 2_000_000, "tokens_out": 1_200_000},
            "minimax-m2": {"calls": 15000, "cost": 74.56, "tokens_in": 4_000_000, "tokens_out": 2_500_000}
        },
        "by_category": {
            "season": {"cost": 85.0, "calls": 5000},
            "constitution": {"cost": 72.0, "calls": 2800},
            "diet": {"cost": 110.0, "calls": 7000},
            # ... 其他category
        },
        "top_expensive_skills": [
            {"skill_id": "daily_rhythm_plan", "cost": 45.0, "calls": 5000},
            {"skill_id": "constitution_overview", "cost": 38.0, "calls": 1200},
            # ...
        ],
        "budget_alert": {
            "daily_budget": 2000.0,
            "spent": 1234.56,
            "remaining": 765.44,
            "projected_total": 1850.0,
            "status": "within_budget"
        }
    }
```

---

## 7. 模型成本估算表

### 7.1 模型定价（2026年3月，人民币）

| 模型 | 输入价格 (¥/M tokens) | 输出价格 (¥/M tokens) | 上下文窗口 | 平均延迟(ms) | 可用性 |
|------|----------------------|----------------------|-----------|-------------|--------|
| deepseek-v3.2 | 1 | 2 | 128K | 800 | 99.9% |
| glm-4.6 | 1 | 2 | 128K | 900 | 99.8% |
| qwen3-235b | 4 | 8 | 128K | 1200 | 99.5% |
| kimi-k2-thinking | 8 | 16 | 1M | 2000 | 99.2% |
| minimax-m2 | 0.5 | 1 | 1M | 500 | 99.5% |

### 7.2 典型 Skill 调用成本

以平均一次 Skill 调用为例（输入 ~1500 tokens，输出 ~1000 tokens）:

| 模型 | 单次调用成本(¥) | 日均调用量(估) | 日均成本(¥) | 月均成本(¥) |
|------|----------------|---------------|------------|------------|
| deepseek-v3.2 | 0.0035 | 30,000 | 105 | 3,150 |
| glm-4.6 | 0.0035 | 48,000 | 168 | 5,040 |
| qwen3-235b | 0.014 | 8,000 | 112 | 3,360 |
| kimi-k2-thinking | 0.028 | 28,000 | 784 | 23,520 |
| minimax-m2 | 0.0018 | 15,000 | 27 | 810 |

**日均总成本估算（10,000 DAU）:**
- 模型调用: ~¥1,196/天 ≈ ¥35,880/月
- 缓存命中率40%抵消后: ~¥718/天 ≈ ¥21,540/月
- 含基础设施（服务器/Redis/ClickHouse）: ~¥850/天 ≈ ¥25,500/月

### 7.3 成本优化策略

| 策略 | 预估节省 | 实施难度 |
|------|---------|---------|
| 提高缓存命中率到60% | 20% | 中 |
| 长TTL Skill（节气/体质）预生成 | 15% | 低 |
| 降级模型用于低价值场景 | 10% | 低 |
| Prompt压缩（减少输入tokens） | 8% | 中 |
| 批量请求合并 | 5% | 高 |
| 用户沉默期暂停主动推送 | 12% | 中 |

**目标**: DAU 10,000 时，月模型成本控制在 ¥20,000 以内。

---

## 8. 国内版 vs 国际版 Skill 差异

### 8.1 版本对比总览

```
┌──────────────────────────────────────────────────────────────┐
│                        国内版 (CN)                            │
│ 中医特色 + 本土化养生                                          │
│  317 Skills (全量)                                           │
│  模型: 国产大模型 (glm/kimi/deepseek/qwen/minimax)           │
│  语言: 简体中文                                                │
│  合规: 国内数据合规                                            │
├──────────────────────────────────────────────────────────────┤
│                        国际版 (INTL)                          │
│ 通用养生 + 本地化适配                                          │
│  ~220 Skills (去除中医特有)                                    │
│  模型: GPT-4o-mini / Claude Haiku (备选)                      │
│  语言: 英文 + 多语言                                          │
│  合规: GDPR / CCPA                                           │
└──────────────────────────────────────────────────────────────┘
```

### 8.2 Category 差异详情

| Category | 国内版 | 国际版 | 差异说明 |
|----------|--------|--------|----------|
| **season** | ✅ 28 skills (24节气+季节) | ✅ 4 skills (四季通用) | 国际版保留四季，去掉24节气具体名称 |
| **constitution** | ✅ 22 skills (九种体质) | ❌ 0 skills 完全移除 | 九种体质为中医概念，国际版不适用 |
| **diet** | ✅ 38 skills (含药膳概念) | ✅ 30 skills (去掉药膳/食疗) | 国际版保留"healthy eating"，去掉"食疗"概念 |
| **tea** | ✅ 24 skills (花茶/草药茶) | ✅ 12 skills (herbal tea/warm drinks) | 国际版保留herbal tea，去掉花茶分类 |
| **acupoint** | ✅ 18 skills (穴位经络) | ❌ 0 skills 完全移除 | 穴位为中医概念，国际版不适用 |
| **exercise** | ✅ 32 skills | ✅ 35 skills (+瑜伽/冥想扩展) | 国际版增加yoga/meditation深度 |
| **sleep** | ✅ 26 skills | ✅ 26 skills (基本一致) | 基本相同 |
| **emotion** | ✅ 30 skills | ✅ 32 skills (+CBT概念) | 国际版增加CBT/self-compassion心理学 |
| **lifestyle** | ✅ 22 skills | ✅ 22 skills (基本一致) | 基本相同 |
| **daily_plan** | ✅ 18 skills | ✅ 18 skills (基本一致) | 基本相同 |
| **reflection** | ✅ 15 skills | ✅ 15 skills (基本一致) | 基本相同 |
| **follow_up** | ✅ 12 skills | ✅ 12 skills (基本一致) | 基本相同 |
| **family** | ✅ 14 skills | ✅ 14 skills (基本一致) | 基本相同 |
| **safety** | ✅ 8 skills | ✅ 10 skills (+本地热线) | 国际版增加各国心理热线 |
| **meta** | ✅ 10 skills | ✅ 10 skills (基本一致) | 基本相同 |
| **合计** | **317** | **~226** | 国际版减少约29% |

### 8.3 国际版新增/调整的 Skill

| skill_id | name | 来源 | 说明 |
|----------|------|------|------|
| `season_spring_general` | Spring Wellness Guide | 从season改编 | 去掉节气名称，保留季节养生 |
| `season_summer_general` | Summer Wellness Guide | 从season改编 | 同上 |
| `season_autumn_general` | Autumn Wellness Guide | 从season改编 | 同上 |
| `season_winter_general` | Winter Wellness Guide | 从season改编 | 同上 |
| `mindfulness_meditation_deep` | Deep Meditation | 新增 | 20分钟深度冥想 |
| `cbt_thought_record` | CBT Thought Record | 新增 | 认知行为疗法思想记录 |
| `body_scan_meditation` | Body Scan Meditation | 新增 | 身体扫描冥想（非中医经络） |
| `yoga_morning_flow` | Morning Yoga Flow | 新增 | 晨间瑜伽流 |
| `yoga_restorative` | Restorative Yoga | 新增 | 恢复性瑜伽 |
| `gratitude_practice` | Gratitude Practice | 新增 | 感恩练习 |
| `journaling_prompt` | Journaling Prompt | 新增 | 写作提示 |
| `breathwork_techniques` | Breathwork Techniques | 新增 | 呼吸技巧合集 |
| `hotline_us` | US Crisis Hotline | 新增 | 988 Suicide & Crisis Lifeline |
| `hotline_uk` | UK Crisis Helpline | 新增 | Samaritans 116 123 |
| `hotline_jp` | Japan Crisis Line | 新增 | Yorisoi Hotline |
| `hydration_tracking` | Water Tracking | 从lifestyle改编 | 更通用的饮水追踪 |

### 8.4 术语映射

| 国内版术语 | 国际版术语 | 说明 |
|-----------|-----------|------|
| 节气养生 | Seasonal Wellness | 去掉"节气"中医概念 |
| 体质调理 | Body Type Awareness | 不做诊断，仅做趋势描述 |
| 食疗 | Wholesome Eating | 去掉"疗"字，避免医疗暗示 |
| 穴位按揉 | Self-Massage Points | 去掉经络概念 |
| 药膳替代 | Nutritious Alternatives | 去掉"药"字 |
| 养生 | Wellness | 更通用的术语 |
| 舒缓 | Soothe / Relax | 英文直接对应 |
| 气虚/阳虚 | Energy / Warmth tendency | 仅描述倾向，不做诊断 |
| 经络导引 | Gentle Stretching | 去掉经络概念 |
| 湿热 | Internal balance | 避免具体中医术语 |

### 8.5 合规差异

| 维度 | 国内版 | 国际版 |
|------|--------|--------|
| 数据存储 | 国内服务器 (阿里云/腾讯云) | AWS EU-US (GDPR) |
| 健康声明 | "养生建议，非医疗" | "Wellness tips, not medical advice" |
| 红线 | 不诊断/不处方/不评分 | 不诊断/不处方/不评分 + FDA disclaimer |
| 年龄限制 | 无特殊限制 | 13岁以下需家长同意 (COPPA) |
| 数据导出 | 个人信息保护法 | GDPR Right to Access |
| 删除权 | 注销即删除 | GDPR Right to Erasure |
| 医疗转介 | "建议就医" | "Consult a healthcare professional" |
| 危机热线 | 全国心理援助: 400-161-9995 | 988 (US) / 116 123 (UK) / 各国本地 |

### 8.6 国际版模型选型

| 场景 | 国内版模型 | 国际版模型 | 理由 |
|------|-----------|-----------|------|
| 内容生成 | glm-4.6 | GPT-4o-mini | 英文内容质量优秀 |
| 深度分析 | kimi-k2-thinking | Claude 3.5 Haiku | 推理+多语言 |
| 轻量快速 | deepseek-v3.2 | GPT-4o-mini | 成本低+速度快 |
| 深度总结 | qwen3-235b | Claude 3.5 Sonnet | 长文本总结 |
| 低成本辅助 | minimax-m2 | GPT-4o-mini | 成本优势 |

---

## 附录

### A. Skill 生命周期状态机

```
                  ┌──────────┐
                  │  draft   │  开发中，不可调用
                  └────┬─────┘
                       │ review通过
                       ▼
                  ┌──────────┐
                  │   beta   │  灰度测试中，仅部分用户可见
                  └────┬─────┘
                       │ 灰度通过
                       ▼
            ┌──────────────────┐
            │     active        │  正式上线，全量可用
            └────┬─────────┬───┘
                 │         │ 发现问题
                 │         ▼
                 │    ┌──────────┐
                 │    │ disabled │  紧急下线，保留数据
                 │    └────┬─────┘
                 │         │ 修复后
                 │         ▼
                 │    ┌──────────┐
                 │    │   beta   │  重新灰度
                 │    └──────────┘
                 │ 版本过旧
                 ▼
            ┌──────────────────┐
            │   deprecated     │  标记废弃，仍可调用但提示升级
            └────┬─────────────┘
                 │ 30天后
                 ▼
            ┌──────────────────┐
            │    removed       │  完全移除，不可调用
            └──────────────────┘
```

### B. 缓存分层策略

| 层级 | 存储 | TTL | 用途 | 容量 |
|------|------|-----|------|------|
| L1: 本地内存 | 进程内LRU | 5min | 热点Skill响应 | 1000条 |
| L2: Redis | Redis Cluster | 1h~90天 | 按Skill配置TTL | 100万条 |
| L3: 预生成 | PostgreSQL | 永久 | 节气/体质等可预计算 | 全量 |

### C. 监控告警规则

| 指标 | 警告阈值 | 严重阈值 | 通知渠道 |
|------|---------|---------|---------|
| Skill错误率 | > 1% | > 5% | Slack + 邮件 |
| Schema校验失败率 | > 3% | > 10% | Slack + 邮件 |
| P99延迟 | > 3s | > 5s | Slack |
| 缓存命中率 | < 30% | < 20% | 邮件 |
| 日成本超出预算 | > 80% | > 100% | 邮件 + 短信 |
| safety_flag=abnormal | > 1% | > 3% | Slack + 电话 |
| 模型不可用 | 任意降级 | 全部降级 | 电话 |

---

> 本文档为顺时 Skill 操作系统 v2.0 架构设计终稿。  
> 所有 317 个 Skill 的完整 JSON 定义存储于 `skill-registry/` 仓库，  
> 每个Skill以独立JSON文件管理，遵循本文档定义的Schema。