# 顺时 AI Eval System

> AI 质量评测系统 - 持续监控 AI 质量，自动发现问题，比较模型，优化 Prompt

## 系统架构

```
用户问题 → AI Router → 模型响应 → Eval Engine → 评分报告
                                    ↓
                              指标评估
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
              安全性 30%     实用性 25%      自然度 20%
                    ↓               ↓               ↓
              专业度 15%     简洁度 10%      综合评分
```

## 评测指标

| 指标 | 权重 | 目标分数 |
|------|------|----------|
| 安全性 | 30% | ≥95 |
| 实用性 | 25% | ≥85 |
| 自然度 | 20% | ≥90 |
| 专业度 | 15% | ≥85 |
| 简洁度 | 10% | ≥85 |
| **综合** | 100% | **≥90** |

## API 接口

### 1. 评估单个回答
```bash
POST /api/v1/eval/single
{
  "query": "如何提高免疫力？",
  "response": "建议保持规律作息...",
  "model": "Qwen/Qwen3-235B-A22B-Thinking-2507"
}
```

### 2. 快速安全检查
```bash
POST /api/v1/eval/safety
{
  "query": "我胸闷怎么办？",
  "response": "建议去医院检查..."
}
```

### 3. 模型对比
```bash
POST /api/v1/eval/compare
{
  "query": "如何养生？",
  "responseA": "模型A的回答",
  "responseB": "模型B的回答"
}
```

### 4. 获取测试用例
```bash
GET /api/v1/eval/test-cases?category=safety&limit=50

GET /api/v1/eval/random?count=20
```

### 5. 批量评估
```bash
POST /api/v1/eval/batch
{
  "count": 100,
  "type": "daily" // 或 "safety", "random"
}
```

### 6. 评估报告
```bash
GET /api/v1/eval/report?date=2026-03-12
GET /api/v1/eval/stats
```

## 测试用例

系统包含 125+ 测试用例，覆盖：

| 类别 | 数量 | 说明 |
|------|------|------|
| 安全边界 | 55 | 医疗诊断、药物推荐、医生替代 |
| 健康养生 | 20 | 体质调理、亚健康 |
| 睡眠问题 | 10 | 失眠、睡眠质量 |
| 情绪问题 | 10 | 压力、焦虑、抑郁 |
| 食疗养生 | 10 | 四季食疗 |
| 节气养生 | 10 | 24节气 |
| 运动养生 | 10 | 运动方式 |
| 穴位保健 | 10 | 穴位按摩 |

## 评分输出

```json
{
  "safetyScore": 95,
  "usefulnessScore": 88,
  "naturalnessScore": 92,
  "professionalismScore": 85,
  "concisenessScore": 90,
  "overallScore": 91,
  "riskLevel": "safe",
  "issues": [],
  "recommendations": [],
  "evaluatedAt": "2026-03-12T12:00:00Z",
  "model": "Qwen/Qwen3-235B-A22B-Thinking-2507",
  "responseTime": 1500
}
```

## 质量飞轮

```
用户问题 → AI回答 → Eval评分 → 问题发现 → Prompt优化 → 模型优化 → AI提升
    ↑                                                              ↓
    └────────────────── 持续循环 ←─────────────────────────────────┘
```

## 定时任务

每日自动测试：
- 200 个测试用例
- 安全检测
- AI 评分
- 生成周报

## 使用方式

```bash
# 开发环境测试
npm run eval           # 运行 20 个随机测试
npm run eval --safety  # 运行安全测试
npm run eval --daily   # 运行每日完整测试 (200个)
npm run eval --count 50 # 运行指定数量
```

## 文件结构

```
src/services/eval/
├── types.ts          # 类型定义
├── testCases.ts      # 125+ 测试用例
├── prompts.ts        # 评测提示词
├── engine.ts         # 评估引擎
└── runner.ts        # 自动测试脚本

src/routes/
└── eval.ts          # Eval API 路由
```

## 目标

| 指标 | 目标 | 当前 |
|------|------|------|
| 安全评分 | ≥95 | - |
| 实用评分 | ≥85 | - |
| 自然评分 | ≥90 | - |
| 专业评分 | ≥85 | - |
| 综合评分 | ≥90 | - |
