# 顺时 AI 模型路由系统 v1

> 顺时 AI Router - 生产级模型路由架构

## 概述

顺时 AI 模型路由系统是整个顺时后端的核心，负责：
- 用户意图识别 (Intent Detection)
- Skill 调用 (Skill Routing)
- 模型选择 (Model Selection)
- Prompt 管理 (Prompt Management)
- Safety 控制 (Safety Control)
- Schema 校验 (Schema Validation)
- Follow-up 生成 (Follow-up Generation)
- Audit 记录 (Audit Logging)

## 架构图

```
用户请求
    ↓
API Gateway
    ↓
AI Router
    ├── Intent Detection
    ├── Skill Routing
    ├── Model Router ← 核心
    ├── Prompt Registry
    ├── AI Cache
    ├── Safety Layer
    └── Audit Logger
    ↓
LLM (DeepSeek/GLM/Qwen/Kimi/MiniMax)
    ↓
响应 + 缓存 + 审计
```

## 核心特性

### 1. 四层模型体系

| 层级 | 作用 | 模型 | 占比 |
|------|------|------|------|
| 默认对话层 | 高频聊天 | DeepSeek-V3.2 | 80% |
| 内容生成层 | 节气/食疗 | GLM-4.6 | 15% |
| 深度分析层 | 周报/月报 | Qwen3-235B | 3% |
| 复杂Agent层 | 多skill调用 | Kimi K2 | 2% |

### 2. 模型选择策略

- **用户身份**: 免费用户只能用 DeepSeek/MiniMax，会员可使用全部模型
- **请求复杂度**: 简单问题用 DeepSeek，复杂问题升级到 Kimi/Qwen
- **Skill 触发**: 特定 skill 强制使用特定模型
- **上下文长度**: >40k tokens 自动升级到 Kimi/Qwen

### 3. 降级策略

```
Qwen3-235B → Kimi K2 → DeepSeek-V3.2
Kimi K2 → GLM-4.6 → DeepSeek-V3.2
DeepSeek-V3.2 → MiniMax-M2
```

### 4. 成本控制

- 默认 80% 请求走 DeepSeek (成本 $0.0005/1k tokens)
- 15% 请求走 GLM (成本 $0.001/1k tokens)
- 5% 请求走 Kimi/Qwen (成本 $0.01/1k tokens)

**预估成本**: 10万日活 × 3次请求/天 = 30万请求/天 ≈ $120-250/天

## 目录结构

```
shunshi-backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI 主入口
│   ├── router/                 # 路由模块
│   │   ├── __init__.py
│   │   ├── config.py           # 路由配置
│   │   └── router.py          # 核心路由逻辑
│   ├── cache/                  # 缓存模块
│   │   ├── __init__.py
│   │   └── cache.py            # AI Cache
│   ├── prompts/                # Prompt 模块
│   │   ├── __init__.py
│   │   └── registry.py         # Prompt Registry
│   ├── audit/                  # 审计模块
│   │   ├── __init__.py
│   │   └── logger.py           # Audit Logger
│   └── skills/                 # Skills 模块
│       └── __init__.py
├── requirements.txt
└── README.md
```

## API 接口

### 模型路由

```bash
POST /route
{
    "user_id": "user_001",
    "user_tier": "premium",
    "api_path": "/chat/send",
    "prompt": "今天适合吃什么",
    "skill_name": null,
    "context_length": 100
}
```

响应:
```json
{
    "selected_model": "deepseek-v3.2",
    "fallback_model": "minimax-m2",
    "reasoning": "综合决策",
    "estimated_cost": 0.0005,
    "cacheable": true
}
```

### 完整对话

```bash
POST /chat
{
    "user_id": "user_001",
    "message": "今天适合吃什么"
}
```

### 统计信息

```bash
GET /stats
```

## 快速开始

```bash
# 安装依赖
pip install fastapi uvicorn pydantic

# 启动服务
python -m app.main

# 或
uvicorn app.main:app --reload --port 8000
```

## 核心模块

### Model Router (`router/router.py`)

核心选择逻辑：

```python
router = ModelRouter()
result = router.select_model(context)

# result.selected_model  # 选择的模型
# result.fallback_model  # 降级模型
# result.estimated_cost  # 预估成本
# result.cacheable       # 是否可缓存
```

### AI Cache (`cache/cache.py`)

基于 prompt + skill + user_stage 的缓存：

```python
# 获取缓存
cached = ai_cache.get(prompt, skill="solar_term_guide")

# 设置缓存
ai_cache.set(prompt, response, skill="solar_term_guide")

# 统计
stats = ai_cache.get_stats()
```

### Prompt Registry (`prompts/registry.py`)

版本化 Prompt 管理：

```python
# 获取当前激活版本
content = prompt_registry.get("core")

# 获取带元数据
prompt = prompt_registry.get_with_metadata("skill_emotion")

# 更新版本
prompt_registry.update("core", "v1.1", new_content, activate=True)
```

### Audit Logger (`audit/logger.py`)

全量请求审计：

```python
# 记录请求
audit_logger.log_request(event_id, user_id, api_path, prompt, model)

# 记录响应
audit_logger.log_response(event_id, response, tokens, latency, cost)

# 记录降级
audit_logger.log_fallback(event_id, from_model, to_model, reason)

# 统计
stats = audit_logger.get_stats()
```

## 配置说明

### MODEL_CONFIG

在 `router/config.py` 中配置模型参数：

```python
MODEL_CONFIG = {
    "deepseek-v3.2": {
        "provider": "deepseek",
        "tier": "default",
        "cost_per_1k_input": 0.0005,
        "fallback": "minimax-m2",
    },
    # ...
}
```

### API_MODEL_MAP

API 到模型的映射：

```python
API_MODEL_MAP = {
    "/chat/send": {
        "default_model": "deepseek-v3.2",
        "premium_model": "glm-4.6",
    },
    "/skill/run": {
        "skill_models": {
            "solar_term_guide": "glm-4.6",
            # ...
        },
    },
}
```

## 监控指标

- **请求量**: total_requests
- **成本**: total_cost_usd
- **缓存命中率**: cache_hit_rate
- **降级次数**: fallbacks
- **错误率**: errors

## 未来升级

- [ ] 接入真实 LLM API (SiliconFlow/OpenAI)
- [ ] 实现 Skill 执行引擎
- [ ] 添加实时监控面板
- [ ] 支持模型灰度发布
- [ ] 实现完整的安全过滤层

---

**作者**: Claw 🦅  
**日期**: 2026-03-09  
**版本**: v1.0.0
