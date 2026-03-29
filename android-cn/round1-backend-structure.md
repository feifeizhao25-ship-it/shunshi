# 顺时 ShunShi 后端目录结构

## 项目信息

- **项目名称**：shunshi_backend
- **技术栈**：Python 3.11 + FastAPI + Pydantic + PostgreSQL + Redis
- **部署方式**：Docker + Kubernetes (长期)

---

## 目录结构

```
shunshi_backend/
├── app/
│   ├── main.py                      # FastAPI 入口
│   ├── config.py                    # 配置管理
│   ├── constants.py                 # 常量定义
│   │
│   ├── api/                         # API 路由
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py           # 主路由
│   │   │   │
│   │   │   ├── auth/               # 认证模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   ├── endpoints.py
│   │   │   │   └── schemas.py
│   │   │   │
│   │   │   ├── users/              # 用户模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   ├── endpoints.py
│   │   │   │   └── schemas.py
│   │   │   │
│   │   │   ├── chat/               # 对话模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   ├── endpoints.py
│   │   │   │   └── schemas.py
│   │   │   │
│   │   │   ├── wellness/            # 养生模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   ├── solar_term/
│   │   │   │   ├── constitution/
│   │   │   │   ├── content/
│   │   │   │   └── habits/
│   │   │   │
│   │   │   ├── family/             # 家庭模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   └── endpoints.py
│   │   │   │
│   │   │   ├── subscription/       # 订阅模块
│   │   │   │   ├── __init__.py
│   │   │   │   ├── router.py
│   │   │   │   └── endpoints.py
│   │   │   │
│   │   │   └── health.py           # 健康检查
│   │   │
│   │   └── dependencies.py         # 依赖注入
│   │
│   ├── core/                       # 核心功能
│   │   ├── security/
│   │   │   ├── password.py
│   │   │   ├── token.py
│   │   │   └── jwt.py
│   │   │
│   │   ├── database/
│   │   │   ├── connection.py
│   │   │   ├── session.py
│   │   │   └── migrations/
│   │   │
│   │   ├── cache/
│   │   │   ├── redis_client.py
│   │   │   └── cache_decorator.py
│   │   │
│   │   └── storage/
│   │       ├── oss_client.py
│   │       └── file_utils.py
│   │
│   ├── models/                     # SQLAlchemy 模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── conversation.py
│   │   ├── message.py
│   │   ├── memory.py
│   │   ├── skill.py
│   │   ├── content.py
│   │   ├── wellness.py
│   │   ├── family.py
│   │   ├── subscription.py
│   │   └── audit.py
│   │
│   ├── schemas/                    # Pydantic Schema
│   │   ├── user.py
│   │   ├── chat.py
│   │   ├── wellness.py
│   │   ├── family.py
│   │   └── subscription.py
│   │
│   ├── services/                   # 业务服务
│   │   ├── auth_service.py
│   │   ├── user_service.py
│   │   ├── chat_service.py
│   │   ├── ai_router_service.py
│   │   ├── skill_service.py
│   │   ├── prompt_service.py
│   │   ├── memory_service.py
│   │   ├── wellness_service.py
│   │   ├── family_service.py
│   │   ├── subscription_service.py
│   │   ├── notification_service.py
│   │   └── analytics_service.py
│   │
│   ├── ai/                         # AI 核心
│   │   ├── router/
│   │   │   ├── __init__.py
│   │   │   ├── router.py           # AI Router 主逻辑
│   │   │   ├── intent_detector.py  # 意图检测
│   │   │   ├── skill_selector.py   # Skill 路由
│   │   │   ├── model_selector.py   # 模型选择
│   │   │   ├── prompt_builder.py   # Prompt 构造
│   │   │   ├── safety_guard.py     # 安全 guard
│   │   │   ├── schema_validator.py # 输出校验
│   │   │   ├── response_repair.py  # 响应修复
│   │   │   ├── cache_layer.py      # 缓存层
│   │   │   └── presence_policy.py  # 存在感策略
│   │   │
│   │   ├── llm/
│   │   │   ├── __init__.py
│   │   │   ├── base.py             # LLM 抽象
│   │   │   ├── openai_client.py
│   │   │   ├── anthropic_client.py
│   │   │   └── local_client.py     # 本地模型
│   │   │
│   │   ├── skills/                 # Skills 实现
│   │   │   ├── __init__.py
│   │   │   ├── base.py             # Skill 基类
│   │   │   ├── daily_rhythm_plan.py
│   │   │   ├── mood_first_aid.py
│   │   │   ├── sleep_wind_down.py
│   │   │   ├── office_micro_break.py
│   │   │   ├── solar_term_guide.py
│   │   │   ├── body_constitution_lite.py
│   │   │   ├── food_tea_recommender.py
│   │   │   ├── acupressure_routine_lite.py
│   │   │   ├── follow_up_generator.py
│   │   │   ├── presence_policy_decider.py
│   │   │   ├── care_status_updater.py
│   │   │   └── family_care_digest.py
│   │   │
│   │   └── prompts/                # Prompt 管理
│   │       ├── __init__.py
│   │       ├── registry.py         # Prompt 注册表
│   │       ├── versions.py         # 版本管理
│   │       ├── core.py             # Core Prompt
│   │       ├── policy.py           # Policy Prompt
│   │       ├── task.py             # Task Prompt
│   │       └── safety.py           # Safety Prompt
│   │
│   └── utils/                      # 工具
│       ├── datetime_utils.py
│       ├── validators.py
│       ├── logger.py
│       └── decorators.py
│
├── scripts/
│   ├── init_db.py
│   ├── seed_data.py
│   └── test_ai.py
│
├── tests/
│   ├── api/
│   ├── services/
│   ├── ai/
│   └── fixtures/
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── nginx/
│   └── nginx.conf
│
├── helm/
│   └── shunshi/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── pyproject.toml
├── requirements.txt
├── .env.example
└── README.md
```

---

## API 接口定义

### 认证接口
| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/v1/auth/register | 注册 |
| POST | /api/v1/auth/login | 登录 |
| POST | /api/v1/auth/refresh | 刷新Token |
| POST | /api/v1/auth/logout | 登出 |
| POST | /api/v1/auth/forgot-password | 忘记密码 |

### 用户接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/users/me | 获取当前用户 |
| PUT | /api/v1/users/me | 更新用户信息 |
| GET | /api/v1/users/me/profile | 获取用户资料 |
| PUT | /api/v1/users/me/settings | 更新设置 |
| GET | /api/v1/users/me/life-stage | 获取生命周期阶段 |

### 对话接口
| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/v1/chat/send | 发送消息 |
| GET | /api/v1/chat/conversations | 对话列表 |
| GET | /api/v1/chat/conversations/{id} | 获取对话 |
| DELETE | /api/v1/chat/conversations/{id} | 删除对话 |

### 日常计划接口
| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/v1/daily-plan/generate | 生成今日计划 |
| GET | /api/v1/daily-plan/today | 获取今日计划 |
| PUT | /api/v1/daily-plan/complete | 完成计划项 |

### Skills 接口
| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/v1/skill/run | 运行 Skill |
| GET | /api/v1/skill/list | 技能列表 |
| GET | /api/v1/skill/{code} | 获取技能详情 |

### 节气接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/solar-terms/current | 当前节气 |
| GET | /api/v1/solar-terms | 节气列表 |
| GET | /api/v1/solar-terms/{id} | 节气详情 |

### 体质接口
| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/v1/constitution/test | 体质测试 |
| GET | /api/v1/constitution/result | 测试结果 |

### 内容接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/content/food | 食疗列表 |
| GET | /api/v1/content/tea | 茶饮列表 |
| GET | /api/v1/content/acupoint | 穴位列表 |
| GET | /api/v1/content/{id} | 内容详情 |

### 习惯接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/habits | 习惯列表 |
| POST | /api/v1/habits | 创建习惯 |
| PUT | /api/v1/habits/{id} | 更新习惯 |
| DELETE | /api/v1/habits/{id} | 删除习惯 |
| POST | /api/v1/habits/{id}/log | 打卡 |

### 家庭接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/family | 家庭信息 |
| POST | /api/v1/family/invite | 邀请家人 |
| POST | /api/v1/family/join | 加入家庭 |
| GET | /api/v1/family/digest | 家庭动态 |
| POST | /api/v1/family/care | 发送关怀 |

### 订阅接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/subscription/products | 产品列表 |
| GET | /api/v1/subscription/current | 当前订阅 |
| POST | /api/v1/subscription/purchase | 购买 |
| POST | /api/v1/subscription/restore | 恢复购买 |

### 记忆接口
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/memory/summary | 记忆摘要 |
| PUT | /api/v1/memory/toggle | 开关记忆 |
| DELETE | /api/v1/memory | 清空记忆 |

### 健康检查
| 方法 | 路径 | 描述 |
|------|------|------|
| GET | /api/v1/health | 服务状态 |

---

## 数据库总览

### 核心表关系

```
users (用户)
    │
    ├── user_auth_accounts (第三方登录)
    ├── user_profiles (用户资料)
    ├── user_settings (用户设置)
    ├── life_stage_history (生命周期历史)
    │
    ├── conversations (对话)
    │       └── messages (消息)
    │
    ├── memory_snapshots (记忆快照)
    ├── life_phase_summaries (人生阶段总结)
    ├── care_status_history (照护状态历史)
    │
    ├── daily_plans (每日计划)
    ├── habits (习惯)
    │       └── habit_logs (打卡记录)
    ├── wellness_journals (养生日志)
    │
    ├── notifications (通知)
    ├── follow_up_plans (跟进计划)
    │
    └── subscription (订阅)
            └── gift_subscriptions (礼物订阅)

family_groups (家庭组)
    │
    ├── family_members (家庭成员)
    ├── family_digests (家庭动态)
    └── family_invitations (邀请)

skills (技能)
    └── skill_prompts (技能Prompt版本)

content_items (内容)
    └── content_collections (内容集)

audit_logs (审计日志)
ai_eval_results (AI评测结果)
```

---

## 部署架构

```
                    ┌─────────────────────┐
                    │     CDN (阿里云)     │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │  API Gateway (Nginx) │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      ┌───────▼───────┐ ┌────▼────┐ ┌───────▼───────┐
      │   Auth SVC    │ │ Chat SVC │ │ Wellness SVC  │
      └───────┬───────┘ └────┬────┘ └───────┬───────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
                    ┌─────────▼───────────┐
                    │    AI Router SVC    │
                    └─────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      ┌───────▼───────┐ ┌────▼────┐ ┌───────▼───────┐
      │  小模型 (7B)   │ │大模型   │ │   Skills      │
      │               │ │ (72B)   │ │   Engine      │
      └───────────────┘ └─────────┘ └───────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
      ┌───────▼───────┐ ┌────▼────┐ ┌───────▼───────┐
      │  PostgreSQL   │ │  Redis  │ │     OSS       │
      │   (主从)      │ │ (集群)  │ │   (文件存储)  │
      └───────────────┘ └─────────┘ └───────────────┘
```
