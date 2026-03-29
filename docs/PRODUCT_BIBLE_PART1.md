# 顺时 ShunShi — 完整产品开发文档（第一部分 · 第1–11章）

> **版本：** v1.0.0-draft  
> **更新日期：** 2026-03-17  
> **文档状态：** 工程化设计稿，可直接指导开发  
> **适用范围：** 移动端（iOS/Android）+ 后端服务

---

## 目录

- [第一章 系统总览](#第一章-系统总览)
- [第二章 模块划分](#第二章-模块划分)
- [第三章 用户注册登录系统](#第三章-用户注册登录系统)
- [第四章 会员购买系统](#第四章-会员购买系统)
- [第五章 首页节律系统](#第五章-首页节律系统)
- [第六章 AI对话系统](#第六章-ai对话系统)
- [第七章 AI Router系统](#第七章-ai-router系统)
- [第八章 内容库系统](#第八章-内容库系统)
- [第九章 知识库/RAG系统](#第九章-知识库rag系统)
- [第十章 体质系统](#第十章-体质系统)
- [第十一章 节气系统](#第十一章-节气系统)

---

# 第一章 系统总览

## 1.1 概述

顺时 ShunShi 是一款面向中国家庭的**中医智慧养生管家**，以"顺天时而养"为核心理念，融合中医体质学说、二十四节气养生智慧与 AI 技术，为用户提供个性化的全周期健康管理方案。

### 产品定位

- **一句话定义：** 基于中医体质与节气智慧的 AI 养生管家
- **目标用户：** 25-55 岁关注健康养生的中国城市家庭
- **核心场景：** 日常养生指导、节气调养方案、家庭健康管理、情绪关怀
- **差异化：** 不是医疗工具，而是生活方式引导系统；不是通用AI，而是专业中医养生AI

### 核心理念

1. **顺天时：** 以二十四节气为时间轴，动态调整养生建议
2. **知体质：** 基于中医九种体质理论，千人千方
3. **养全家：** 以家庭为单位，提供差异化家庭成员方案
4. **AI赋能：** 对话式交互降低中医养生门槛，长期记忆实现持续精进
5. **轻干预：** 不替代医疗，而是预防性生活方式引导

### 产品边界（不做什么）

| 边界 | 说明 |
|------|------|
| ❌ 不做诊断 | 绝不提供疾病诊断，遇到医疗问题引导就医 |
| ❌ 不做处方 | 不推荐具体药物及剂量，不替代医生处方 |
| ❌ 不做急救 | 不提供紧急医疗指导，遇到紧急情况拨打120 |
| ❌ 不做医疗设备对接 | 不接入血压计、血糖仪等医疗级设备数据 |
| ❌ 不做社交 | 不做社区/朋友圈等社交功能 |
| ❌ 不做电商 | 不卖保健品、中药材等实体商品 |
| ❌ 不做短视频 | 不做内容创作/UGC平台 |

---

## 1.2 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        客户端层 (Flutter)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │
│  │  iOS App │ │Android App│ │  Widget  │ │  Notification    │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬──────────┘  │
│       └────────────┼────────────┘                  │             │
│              ┌─────┴─────┐                         │             │
│              │  BLoC/Riverpod State Management     │             │
│              └─────┬─────┘                         │             │
└────────────────────┼───────────────────────────────┼─────────────┘
                     │ HTTPS / WebSocket              │
┌────────────────────┼───────────────────────────────┼─────────────┐
│              API Gateway (Nginx / Traefik)         │             │
│              - Rate Limiting                       │             │
│              - SSL Termination                     │             │
│              - Load Balancing                      │             │
└────────────────────┼───────────────────────────────┼─────────────┘
                     │                               │
┌────────────────────┼───────────────────────────────┼─────────────┐
│              应用服务层 (FastAPI)                    │             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐ │
│  │ 用户服务  │ │ AI服务   │ │ 内容服务  │ │会员服务 │ │通知服务  │ │
│  │ Auth     │ │ Router   │ │ Content  │ │Sub      │ │Push     │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬────┘ └────┬────┘ │
│       └────────────┼────────────┼────────────┼──────────┼────── │
│              ┌─────┴────────────┴────────────┴──────────┘      │
│              │          Service Mesh / Message Queue           │
│              └────────────────────┬─────────────────────────── │
└───────────────────────────────────┼────────────────────────────┘
                                    │
┌───────────────────────────────────┼────────────────────────────┐
│                        数据层                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │  MySQL   │ │  Redis   │ │  Milvus  │ │   阿里云 OSS     │  │
│  │ 主数据库  │ │ 缓存/会话 │ │ 向量数据库│ │ 媒体/文档存储    │  │
│  │ 用户/订单 │ │ 热数据   │ │ 知识向量  │ │ 图片/音频/视频   │  │
│  │ 内容/体质 │ │ Token    │ │ Embedding │ │ 用户头像         │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                                    │
┌───────────────────────────────────┼────────────────────────────┐
│                     外部服务层                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ 通义千问  │ │ 文心一言  │ │ 支付宝   │ │ APNs / FCM     │  │
│  │ 主模型    │ │ 情绪模型  │ │ IAP      │ │ 推送服务        │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

---

## 1.3 技术栈总览

| 层级 | 技术选型 | 版本 | 说明 |
|------|---------|------|------|
| **移动端** | Flutter | 3.x+ | 跨平台，一套代码覆盖 iOS/Android |
| **状态管理** | Riverpod | 2.x | 编译时安全，支持异步 |
| **本地存储** | Hive + Drift | - | KV存储 + 关系型本地DB |
| **后端框架** | FastAPI | 0.110+ | 异步高性能，自动API文档 |
| **ORM** | SQLAlchemy 2.0 | 2.0+ | 异步支持，类型安全 |
| **任务队列** | Celery + Redis | - | 异步任务处理 |
| **数据库** | MySQL | 8.0+ | 主数据库，InnoDB引擎 |
| **缓存** | Redis | 7.x | 会话缓存、热数据、分布式锁 |
| **向量数据库** | Milvus | 2.3+ | 知识检索Embedding存储 |
| **对象存储** | 阿里云 OSS | - | 媒体文件、文档存储 |
| **CDN** | 阿里云 CDN | - | 静态资源加速 |
| **消息推送** | APNs + FCM | - | iOS/Android推送 |
| **支付** | 支付宝 + Apple IAP + Google Billing | - | 三端支付 |
| **CI/CD** | GitHub Actions | - | 自动化构建部署 |
| **监控** | Prometheus + Grafana | - | 服务监控 |
| **日志** | ELK Stack | - | 日志聚合分析 |
| **AI模型** | 通义千问 qwen-plus / qwen-turbo | - | 主力对话模型 |
| | 文心一言 ernie-bot | - | 情绪识别/情绪关怀 |
| | 通义千问 qwen-turbo | - | 轻量路由模型 |

---

## 1.4 模块依赖关系图

```
                          ┌──────────┐
                          │  用户服务  │
                          │  (Auth)  │
                          └────┬─────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
       │  会员服务    │ │  体质服务    │ │  节气服务    │
       │ (Member)   │ │ (Constitu.) │ │  (Solar)   │
       └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │    AI Router 核心    │
                    │  ┌───────────────┐  │
                    │  │ Intent Class  │  │
                    │  │ Safety Guard  │  │
                    │  │ Model Router  │  │
                    │  │ Schema Valid. │  │
                    │  └───────────────┘  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
       │  AI对话服务  │ │  内容库服务  │ │  RAG知识库   │
       │  (Chat)    │ │ (Content)   │ │   (RAG)     │
       └──────┬──────┘ └──────────┘ └──────────────┘
              │
       ┌──────┴──────┐
       │  首页节律    │
       │ (Dashboard) │
       └─────────────┘

  独立模块（弱依赖）：
  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
  │ 通知服务  │ │ 埋点服务  │ │ CMS后台   │ │ 家庭服务  │
  │ (Notify) │ │(Analytics)│ │ (Admin)  │ │(Family)  │
  └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

---

## 1.5 里程碑规划

### Phase 1：MVP（8周）

| 周次 | 交付内容 |
|------|---------|
| W1-2 | 用户注册登录（手机号+验证码）、基础用户体系 |
| W3-4 | 首页节律（静态数据）、节气展示、内容浏览 |
| W5-6 | AI对话基础（单轮）、体质测试 |
| W7 | 会员体系（免费+养心两档）、支付宝支付 |
| W8 | 集成测试、Bug修复、TestFlight/Internal Test |

**MVP核心指标：**
- 完成体质测试用户 > 60%
- AI对话使用率 > 40%
- 7日留存 > 30%

### Phase 2：成长期（8周）

| 周次 | 交付内容 |
|------|---------|
| W9-10 | AI多轮对话、长期记忆、意图分类 |
| W11-12 | RAG知识库上线、节气动态推荐 |
| W13-14 | 颐养会员层、Apple IAP |
| W15-16 | 家庭功能（添加家庭成员、差异化建议） |

**Phase 2 核心指标：**
- AI对话日均使用 > 2次
- 30日留存 > 25%
- 付费转化率 > 3%

### Phase 3：成熟期（8周）

| 周次 | 交付内容 |
|------|---------|
| W17-18 | 家和会员层、Google Billing |
| W19-20 | AI安全体系完善、Schema Validator |
| W21-22 | 内容推荐算法、个性化首页 |
| W23-24 | CMS后台、运营工具、数据报表 |

**Phase 3 核心指标：**
- MAU > 10万
- 付费用户 > 5000
- 家庭功能使用率 > 20%

### Phase 4：优化期（持续）

- AI模型持续优化（A/B测试）
- 节气内容年度更新
- 营养/运动深度功能
- 智能硬件联动探索

---

## 1.6 与其他模块的关系

系统总览作为顶层设计，定义了所有模块的边界和接口规范。后续每章详细展开各模块的设计，并通过"与其他模块的关系"小节明确跨模块调用约定。

---

# 第二章 模块划分

## 2.1 概述

顺时 ShunShi 系统采用**领域驱动设计（DDD）**思想，将系统划分为 18 个核心模块。每个模块对应一个限界上下文（Bounded Context），拥有独立的数据表、API接口和业务逻辑。

---

## 2.2 18个核心模块列表及职责

### 2.2.1 用户服务模块 (User Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `user` |
| **职责** | 用户注册、登录、认证、信息管理、账号安全 |
| **核心能力** | 手机号验证码登录、第三方OAuth（Apple/微信）、JWT Token管理、多设备登录态、账号注销与删除 |
| **关键指标** | 注册转化率、登录成功率、Token刷新成功率 |

### 2.2.2 会员服务模块 (Membership Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `membership` |
| **职责** | 会员层级管理、订阅购买、支付集成、权益控制、订单管理 |
| **核心能力** | 四档会员（免费/养心/颐养/家和）、支付宝/Apple IAP/Google Billing、权益矩阵中间件、订阅生命周期管理 |
| **关键指标** | 付费转化率、续费率、ARPU、LTV |

### 2.2.3 首页节律模块 (Dashboard Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `dashboard` |
| **职责** | 个性化首页数据聚合、每日计划生成、节律建议展示 |
| **核心能力** | 生命周期感知的首页布局、体质+节气+情绪动态建议、数据聚合与缓存 |
| **关键指标** | 首页停留时长、每日计划点击率、建议采纳率 |

### 2.2.4 AI对话服务模块 (AI Chat Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `ai-chat` |
| **职责** | AI对话会话管理、消息收发、上下文管理、记忆管理 |
| **核心能力** | 8类对话能力、多轮上下文滑动窗口、长期偏好记忆、阶段摘要记忆(LifePhase) |
| **关键指标** | 对话轮次、满意度、AI响应时间P99、Token消耗 |

### 2.2.5 AI Router模块 (AI Router)

| 属性 | 说明 |
|------|------|
| **模块ID** | `ai-router` |
| **职责** | AI请求路由、意图分类、安全拦截、模型选择、Prompt管理、Schema校验 |
| **核心能力** | 9类意图分类、Safety Guard（5层拦截）、Model Router（3模型路由）、Prompt Registry + 版本管理、RAG集成 |
| **关键指标** | 意图分类准确率、安全拦截率、P99延迟、Token成本 |

### 2.2.6 内容库模块 (Content Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `content` |
| **职责** | 养生内容管理、分类、搜索、推荐、媒体资源管理 |
| **核心能力** | 8大类内容体系、全文搜索、标签过滤、OSS媒体存储、CDN分发、媒体降级策略 |
| **关键指标** | 内容曝光量、阅读完成率、搜索命中率 |

### 2.2.7 知识库/RAG模块 (RAG Knowledge Base)

| 属性 | 说明 |
|------|------|
| **模块ID** | `rag` |
| **职责** | 中医知识向量化存储、语义检索、知识切片管理 |
| **核心能力** | 6类知识源、主题/节气/体质三维切片、Milvus向量存储、Top-K语义检索 |
| **关键指标** | 检索召回率、检索延迟P99、知识覆盖率 |

### 2.2.8 体质测试模块 (Constitution Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `constitution` |
| **职责** | 中医九种体质测试、评分计算、体质解读、养生方案关联 |
| **核心能力** | 25题标准问卷、加权计分算法、主要+倾向体质判定、AI体质解读生成 |
| **关键指标** | 测试完成率、测试重测率、体质分布统计 |

### 2.2.9 节气服务模块 (Solar Term Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `solar-term` |
| **职责** | 二十四节气计算与展示、节气调养方案管理、节气提醒 |
| **核心能力** | 24节气精确计算、7维度调养方案、节气切换检测、推荐关联 |
| **关键指标** | 节气内容点击率、提醒打开率、方案收藏率 |

### 2.2.10 家庭服务模块 (Family Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `family` |
| **职责** | 家庭成员管理、成员间差异化方案、家庭席位管理 |
| **核心能力** | 家庭创建/邀请、成员健康档案、差异化的体质/节气方案 |
| **关键指标** | 家庭创建率、成员添加数、家庭方案采纳率 |

### 2.2.11 通知服务模块 (Notification Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `notification` |
| **职责** | 推送通知、站内消息、提醒调度 |
| **核心能力** | APNs/FCM集成、定时提醒、消息模板、免打扰设置 |
| **关键指标** | 推送送达率、点击率、免打扰使用率 |

### 2.2.12 埋点分析模块 (Analytics Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `analytics` |
| **职责** | 用户行为追踪、数据上报、分析报表 |
| **核心能力** | 事件采集、漏斗分析、留存分析、A/B实验 |
| **关键指标** | 数据上报成功率、事件覆盖率 |

### 2.2.13 支付服务模块 (Payment Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `payment` |
| **职责** | 支付接口封装、支付回调处理、对账 |
| **核心能力** | 支付宝集成、Apple IAP集成、Google Billing集成、退款处理 |
| **关键指标** | 支付成功率、退款率、对账准确率 |

### 2.2.14 媒体服务模块 (Media Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `media` |
| **职责** | 媒体文件上传/下载/转码、缩略图生成 |
| **核心能力** | OSS对接、图片压缩、视频转码、CDN预热 |
| **关键指标** | 上传成功率、转码耗时、CDN命中率 |

### 2.2.15 缓存服务模块 (Cache Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `cache` |
| **职责** | 统一缓存管理、缓存策略配置、缓存预热与失效 |
| **核心能力** | Redis多级缓存、热点自动检测、缓存穿透/雪崩防护 |
| **关键指标** | 缓存命中率、缓存更新延迟 |

### 2.2.16 搜索服务模块 (Search Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `search` |
| **职责** | 全文搜索、搜索建议、热门搜索 |
| **核心能力** | 中文分词、同义词扩展、搜索排序、搜索纠错 |
| **关键指标** | 搜索响应时间P99、搜索无结果率 |

### 2.2.17 CMS后台模块 (Admin CMS)

| 属性 | 说明 |
|------|------|
| **模块ID** | `admin-cms` |
| **职责** | 运营后台、内容管理、数据报表、用户管理 |
| **核心能力** | 内容编辑器、用户管理、订单管理、数据看板 |
| **关键指标** | 后台DAU、内容发布效率 |

### 2.2.18 配置中心模块 (Config Service)

| 属性 | 说明 |
|------|------|
| **模块ID** | `config` |
| **职责** | 应用配置管理、特性开关、AB实验配置 |
| **核心能力** | 动态配置更新、灰度发布控制、AB实验分流 |
| **关键指标** | 配置更新延迟、灰度覆盖率 |

---

## 2.3 模块间依赖关系

```
层级 0（基础设施，无依赖）：
  └── config-service          # 配置中心
  └── cache-service           # 缓存服务
  └── media-service           # 媒体服务

层级 1（核心基础服务）：
  └── user-service            # 依赖：config, cache
  └── content-service         # 依赖：config, cache, media, search
  └── solar-term-service      # 依赖：config, cache
  └── constitution-service    # 依赖：config, cache
  └── rag-service             # 依赖：config, cache, content

层级 2（业务核心服务）：
  └── ai-router               # 依赖：user, rag, config, cache
  └── ai-chat-service         # 依赖：ai-router, user, cache
  └── membership-service      # 依赖：user, payment, config, cache
  └── payment-service         # 依赖：user, config, cache
  └── family-service          # 依赖：user, constitution, config, cache

层级 3（聚合服务）：
  └── dashboard-service       # 依赖：user, ai-chat, solar-term, constitution, membership, family, cache
  └── notification-service    # 依赖：user, solar-term, dashboard, config

层级 4（支撑服务）：
  └── analytics-service       # 依赖：全部（只读事件消费）
  └── admin-cms               # 依赖：全部（管理操作）
  └── search-service          # 依赖：content, config
```

---

## 2.4 优先级排序

| 优先级 | 模块 | 说明 |
|--------|------|------|
| **P0** | user-service | 用户认证是所有功能的前提 |
| **P0** | config-service | 配置中心是所有服务的基础 |
| **P0** | cache-service | 缓存是性能保障的基础设施 |
| **P0** | ai-router | AI核心，产品差异化关键 |
| **P0** | ai-chat-service | 核心交互功能 |
| **P1** | constitution-service | 个性化基础数据 |
| **P1** | solar-term-service | 核心差异化内容 |
| **P1** | content-service | 内容消费基础 |
| **P1** | membership-service | 商业化基础 |
| **P1** | payment-service | 支付能力 |
| **P1** | media-service | 内容媒体支撑 |
| **P1** | dashboard-service | 首页体验 |
| **P2** | rag-service | AI知识增强 |
| **P2** | family-service | 家庭功能 |
| **P2** | notification-service | 用户召回 |
| **P2** | analytics-service | 数据驱动 |
| **P2** | search-service | 内容发现 |
| **P2** | admin-cms | 运营效率 |

---

## 2.5 模块负责人建议

| 模块 | 建议角色 | 技能要求 | 建议人数 |
|------|---------|---------|---------|
| user-service | 后端工程师 | FastAPI, JWT, OAuth, 安全 | 1 |
| config-service | 后端工程师 | Redis, 配置管理 | 0.5（兼职） |
| cache-service | 后端工程师 | Redis, 缓存策略 | 0.5（兼职） |
| ai-router | AI工程师 | LLM, Prompt Engineering, 意图识别 | 1-2 |
| ai-chat-service | 全栈工程师 | FastAPI, Flutter, WebSocket | 1 |
| constitution-service | 后端工程师 | 算法设计, 中医知识 | 0.5 |
| solar-term-service | 后端工程师 | 算法, 数据建模 | 0.5 |
| content-service | 后端工程师 | 搜索, CDN, OSS | 1 |
| membership-service | 后端工程师 | 支付系统, 订阅模型 | 1 |
| payment-service | 后端工程师 | 支付宝SDK, IAP, Billing | 1 |
| media-service | 后端工程师 | OSS, 转码, CDN | 0.5 |
| dashboard-service | 全栈工程师 | Flutter, 聚合服务 | 1 |
| rag-service | AI工程师 | Milvus, Embedding, 检索 | 1 |
| family-service | 后端工程师 | 权限设计, 关系管理 | 0.5 |
| notification-service | 后端工程师 | APNs, FCM, 调度 | 0.5 |
| analytics-service | 数据工程师 | 埋点, ETL, 分析 | 1 |
| search-service | 后端工程师 | 全文搜索, 分词 | 0.5 |
| admin-cms | 前端+后端 | React/Vue, 管理后台 | 1 |
| Flutter 客户端 | 移端工程师 | Flutter, Riverpod | 2-3 |

---

## 2.6 与其他模块的关系

模块划分为后续每一章的详细设计提供框架。每个模块的详细设计将在对应章节中展开，包括数据表设计、API设计、状态机等。模块间的接口通过内部 HTTP/gRPC 调用，所有跨模块调用需要通过认证中间件。

---

# 第三章 用户注册登录系统

## 3.1 概述

用户注册登录系统是顺时 ShunShi 的基础服务，负责用户身份管理、认证鉴权和账号安全。系统支持多种注册登录方式，采用 JWT 双 Token 机制，并提供完善的安全策略。

### 核心目标

- 多方式注册登录，降低注册门槛
- 安全可靠的 Token 管理
- 完善的账号生命周期管理
- 跨设备登录态同步

---

## 3.2 注册方式

### 3.2.1 手机号注册

**流程：**

```
用户输入手机号 → 请求发送验证码 → 后端生成6位数字验证码 → 存入Redis(TTL 5min)
→ 发送短信(阿里云SMS) → 用户输入验证码 → 校验验证码 → 创建用户记录
→ 生成JWT Token对 → 返回Token → 注册完成
```

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string(11) | Y | 中国大陆手机号 |
| code | string(6) | Y | SMS验证码 |
| nickname | string(20) | N | 昵称，默认生成"顺时用户XXXX" |

**验证码规则：**

- 格式：6位纯数字
- 有效期：5分钟
- 频率限制：同一手机号60秒内限1次，1小时限5次，1天限10次
- IP限制：同一IP 1小时限20次

### 3.2.2 Apple 注册

**流程：**

```
客户端获取Apple ID Token → 发送到后端 → 后端验证Apple公钥签名
→ 提取user_id和email → 检查是否已绑定 → 未绑定则创建新用户
→ 记录auth_provider → 生成JWT → 注册完成
```

### 3.2.3 微信注册

**流程：**

```
客户端调起微信授权 → 获取auth_code → 发送到后端
→ 后端用code换取access_token → 获取openid/unionid
→ 检查是否已绑定 → 未绑定则创建新用户 → 记录auth_provider
→ 生成JWT → 注册完成
```

### 3.2.4 游客模式

**流程：**

```
客户端生成UUID作为device_id → 发送device_id到后端
→ 后端创建临时用户（标记guest=true）→ 生成JWT
→ 游客可体验基础功能 → 后续可升级为正式用户
```

**限制：**

- 游客最多创建3个会话
- 游客无法使用家庭功能
- 游客数据不跨设备同步
- 游客账号30天未升级自动清理

---

## 3.3 登录方式

### 3.3.1 手机号 + 验证码登录

与注册流程类似，区别在于用户已存在时直接返回 Token。

### 3.3.2 Apple 登录

使用 Apple ID Token 验证后返回已绑定用户的 Token。

### 3.3.3 微信登录

使用微信授权码换取用户信息后返回 Token。

### 3.3.4 一键登录（本机号码认证）

```
客户端获取运营商预取号 → 调起一键登录授权页 → 获取token
→ 发送到后端 → 后端调用运营商SDK验证 → 获取手机号
→ 查找或创建用户 → 生成JWT → 登录完成
```

---

## 3.4 用户状态机

```
                    ┌──────────┐
         注册       │  未注册   │
        ┌─────────→│ (访客)   │
        │          └──────────┘
        │                │ 手机号/Apple/微信/游客
        │                ▼
        │          ┌──────────┐
        │          │  已注册   │──── 未验证手机号 ──→ 需要补充手机号
        │          │          │
        │          └────┬─────┘
        │               │ 登录成功
        │               ▼
        │          ┌──────────┐
        │          │  已登录   │
        │          │ (Active) │
        │          └────┬─────┘
        │               │
        │       ┌───────┼───────┐
        │       │       │       │
        │       ▼       ▼       ▼
        │  ┌────────┐┌──────┐┌────────┐
        │  │ 已注销 ││冻结中││ 已删除 │
        │  │(Logged ││(Frozen││Deleted │
        │  │  Out)  ││      ││        │
        │  └───┬────┘└──┬───┘└────────┘
        │      │         │
        │      │重新登录  │管理员解冻
        │      ▼         ▼
        │  ┌──────────┐┌──────────┐
        └──│  已登录   ││  已登录   │
           └──────────┘└──────────┘
```

**状态定义：**

| 状态 | 值 | 说明 |
|------|---|------|
| 未注册 | `GUEST` | 访客状态，未创建用户记录 |
| 已注册 | `REGISTERED` | 已创建用户记录，未登录 |
| 已登录 | `ACTIVE` | 正常活跃状态 |
| 已注销 | `LOGGED_OUT` | 用户主动退出登录 |
| 冻结中 | `FROZEN` | 因违规或安全原因被冻结 |
| 已删除 | `DELETED` | 用户申请删除账号（软删除30天） |

---

## 3.5 用户数据字段定义

### users 表主字段

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| uuid | VARCHAR(36) | Y | UNIQUE | 用户UUID（对外暴露） |
| phone | VARCHAR(20) | N | UNIQUE | 手机号（加密存储） |
| phone_hash | VARCHAR(64) | N | INDEX | 手机号SHA256哈希（用于查询） |
| email | VARCHAR(255) | N | UNIQUE | 邮箱（Apple登录提供） |
| password_hash | VARCHAR(255) | N | - | 密码哈希（预留，当前不用密码） |
| nickname | VARCHAR(50) | Y | - | 映射名称，默认"顺时用户XXXX" |
| avatar_url | VARCHAR(512) | N | - | 头像OSS URL |
| gender | TINYINT | N | - | 0-未知, 1-男, 2-女, 3-其他 |
| birthday | DATE | N | INDEX | 生日 |
| life_stage | VARCHAR(20) | N | INDEX | 生命阶段：youth/student/career/marriage/parenting/middle/elder |
| status | TINYINT | Y | INDEX | 1-正常, 2-注销, 3-冻结, 4-已删除 |
| is_guest | BOOLEAN | Y | INDEX | 是否游客用户 |
| guest_expires_at | DATETIME | N | - | 游客过期时间 |
| last_login_at | DATETIME | N | - | 最后登录时间 |
| last_login_ip | VARCHAR(45) | N | - | 最后登录IP |
| last_login_device | VARCHAR(255) | N | - | 最后登录设备标识 |
| login_count | INT | Y | - | 累计登录次数，默认0 |
| risk_level | TINYINT | Y | - | 风险等级：0-低, 1-中, 2-高 |
| created_at | DATETIME | Y | INDEX | 注册时间 |
| updated_at | DATETIME | Y | - | 最后更新时间 |
| deleted_at | DATETIME | N | INDEX | 软删除时间 |
| deleted_reason | VARCHAR(255) | N | - | 删除原因（用户选择） |

### user_profiles 扩展字段

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| user_id | BIGINT | Y | UNIQUE | 关联users.id |
| constitution_type | VARCHAR(30) | N | INDEX | 主要体质类型 |
| constitution_sub_type | VARCHAR(30) | N | - | 倾向体质类型 |
| constitution_tested_at | DATETIME | N | - | 最近体质测试时间 |
| province | VARCHAR(50) | N | - | 所在省份 |
| city | VARCHAR(50) | N | - | 所在城市 |
| sleep_quality | TINYINT | N | - | 睡眠质量自评：1-5 |
| mood_status | TINYINT | N | - | 情绪状态：1-低落, 2-一般, 3-平静, 4-愉悦, 5-兴奋 |
| health_concerns | JSON | N | - | 健康关注标签列表 |
| diet_preferences | JSON | N | - | 饮食偏好标签列表 |
| ai_interaction_count | INT | Y | - | AI交互累计次数，默认0 |
| content_view_count | INT | Y | - | 内容浏览累计次数，默认0 |
| bio | TEXT | N | - | 个人简介 |
| updated_at | DATETIME | Y | - | 最后更新时间 |

### user_preferences 设置字段

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| user_id | BIGINT | Y | UNIQUE | 关联users.id |
| language | VARCHAR(10) | Y | - | 语言设置，默认"zh-CN" |
| push_enabled | BOOLEAN | Y | - | 推送开关，默认true |
| push_mute_start | TIME | N | - | 免打扰开始时间 |
| push_mute_end | TIME | N | - | 免打扰结束时间 |
| daily_reminder_enabled | BOOLEAN | Y | - | 每日养生提醒，默认true |
| daily_reminder_time | TIME | N | - | 提醒时间，默认"08:00" |
| solar_term_reminder | BOOLEAN | Y | - | 节气提醒，默认true |
| ai_voice_enabled | BOOLEAN | Y | - | AI语音回复，默认false |
| ai_style | VARCHAR(20) | Y | - | AI对话风格：warm/professional/friendly，默认"warm" |
| data_collection | BOOLEAN | Y | - | 数据收集授权，默认true |
| updated_at | DATETIME | Y | - | 最后更新时间 |

### user_auth_providers 第三方登录

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| user_id | BIGINT | Y | INDEX | 关联users.id |
| provider | VARCHAR(20) | Y | INDEX | 提供方：apple/wechat/phone |
| provider_uid | VARCHAR(255) | Y | INDEX | 提供方用户ID |
| provider_token | TEXT | N | - | 加密存储的provider token（refresh用） |
| provider_token_expires | DATETIME | N | - | token过期时间 |
| linked_at | DATETIME | Y | - | 绑定时间 |
| last_used_at | DATETIME | N | - | 最后使用时间 |
| UNIQUE(provider, provider_uid) | | | | 复合唯一索引 |

---

## 3.6 JWT Access Token + Refresh Token 机制

### 3.6.1 Token 设计

| Token 类型 | 有效期 | 存储位置 | 用途 |
|-----------|--------|---------|------|
| Access Token | 30分钟 | 内存+本地安全存储 | 接口鉴权 |
| Refresh Token | 30天 | 本地安全存储（加密） | 刷新Access Token |

### 3.6.2 Access Token Payload

```json
{
  "sub": "uuid-string",
  "user_id": 12345,
  "device_id": "device-uuid",
  "role": "user",
  "membership": "free",
  "type": "access",
  "iat": 1709462400,
  "exp": 1709464200,
  "jti": "unique-token-id"
}
```

### 3.6.3 Refresh Token Payload

```json
{
  "sub": "uuid-string",
  "user_id": 12345,
  "device_id": "device-uuid",
  "type": "refresh",
  "iat": 1709462400,
  "exp": 1712054400,
  "jti": "unique-refresh-id"
}
```

### 3.6.4 Token 签名配置

- 算法：RS256（RSA非对称）
- Access Token 使用 `ACCESS_TOKEN_PRIVATE_KEY` 签名
- Refresh Token 使用 `REFRESH_TOKEN_PRIVATE_KEY` 签名
- 密钥定期轮换（90天），支持多密钥验证

---

## 3.7 Token 过期与刷新流程

```
客户端请求API
    │
    ▼
Access Token 有效？
    ├── 是 → 正常处理请求 → 返回数据
    │
    └── 否 → 返回 401 (token_expired)
              │
              ▼
        客户端自动使用 Refresh Token
        调用 POST /auth/refresh
              │
              ▼
        Refresh Token 有效？
            ├── 是 → 生成新 Access Token（+ 可选新 Refresh Token）
            │        → 返回 200 + 新Token对
            │
            └── 否 → 返回 401 (refresh_expired)
                     → 客户端清除本地Token
                     → 跳转登录页
```

**安全策略：**

- Refresh Token 一次性使用（Rotation）：每次刷新后旧的 Refresh Token 立即失效
- Refresh Token 家族检测：如果检测到已使用的旧 Token 被再次使用，说明可能泄露，立即吊销该用户所有 Refresh Token
- 最大并发 Refresh Token 数量：每用户每设备最多3个

---

## 3.8 设备登录态管理

### 设备注册

| 字段 | 说明 |
|------|------|
| device_id | 客户端生成的UUID |
| device_name | 设备名称（如"iPhone 15 Pro"） |
| device_model | 设备型号 |
| os_version | 操作系统版本 |
| app_version | App版本号 |
| push_token | 推送Token（APNs/FCM） |

### 多设备策略

- 免费用户：最多2台设备同时登录
- 养心会员：最多3台设备
- 颐养会员：最多5台设备
- 家和会员：最多10台设备

超出设备上限时，踢出最早登录的设备。

### 设备Token黑名单

使用 Redis 存储设备级 Token 黑名单：

```
Key: device:blacklist:{device_id}
Value: SET of jti
TTL: 与Token过期时间一致
```

---

## 3.9 风险登录检测

### 风险评估维度

| 维度 | 权重 | 检测规则 |
|------|------|---------|
| IP异常 | 30% | 与常用登录城市不在同一省份 |
| 设备异常 | 25% | 新设备首次登录 |
| 频率异常 | 20% | 1小时内登录失败>5次 |
| Token异常 | 15% | Refresh Token家族冲突 |
| 行为异常 | 10% | 短时间大量敏感操作 |

### 风险等级处理

| 等级 | 阈值 | 处理方式 |
|------|------|---------|
| 低 (0) | 0-30分 | 正常放行 |
| 中 (1) | 31-60分 | 要求短信二次验证 |
| 高 (2) | 61-100分 | 冻结账号，发送邮件/短信通知，需人工申诉 |

---

## 3.10 注销后 Token 失效

**机制：**

1. 客户端调用 `POST /auth/logout`，携带当前 Refresh Token
2. 后端将该 Refresh Token 的 jti 加入黑名单
3. 后端将该设备关联的所有 Access Token jti 加入 Redis 黑名单
4. 清除服务端 Session 缓存（如 Redis 中的用户状态缓存）
5. 返回成功，客户端清除本地 Token 存储

**Redis 黑名单结构：**

```
Key: token:blacklist:{jti}
Value: "1"
TTL: Token剩余过期时间
```

---

## 3.11 账号删除后数据清理流程

### 删除流程

```
用户请求删除
    │
    ▼
二次确认（输入"确认删除我的账号"）
    │
    ▼
标记 deleted_at = NOW(), status = DELETED
    │
    ├── 活跃订阅？→ 提示先取消订阅
    │
    ├── 家庭中是创建者？→ 提示先转让或解散家庭
    │
    └── 无阻塞条件 → 执行软删除
```

### 软删除（立即）

- 用户记录标记 `status = DELETED`, `deleted_at = NOW()`
- 所有Token立即失效
- 用户从搜索结果中移除
- 其他用户不可见该用户

### 硬删除（30天宽限期后）

通过 Celery 定时任务执行：

| 数据 | 处理方式 |
|------|---------|
| users | 物理删除 |
| user_profiles | 物理删除 |
| user_preferences | 物理删除 |
| user_auth_providers | 物理删除 |
| conversations | 物理删除（含messages） |
| conversation_messages | 物理删除 |
| constitution_tests/answers | 物理删除 |
| subscription_orders | 保留（财务合规） |
| analytics_events | 匿名化聚合后删除 |

### 恢复机制

30天宽限期内用户重新登录可恢复账号，所有数据恢复。

---

## 3.12 数据表DDL

```sql
-- users
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    phone_hash VARCHAR(64) DEFAULT NULL,
    email VARCHAR(255) DEFAULT NULL,
    password_hash VARCHAR(255) DEFAULT NULL,
    nickname VARCHAR(50) NOT NULL DEFAULT '',
    avatar_url VARCHAR(512) DEFAULT NULL,
    gender TINYINT DEFAULT 0 COMMENT '0-未知 1-男 2-女 3-其他',
    birthday DATE DEFAULT NULL,
    life_stage VARCHAR(20) DEFAULT NULL,
    status TINYINT NOT NULL DEFAULT 1 COMMENT '1-正常 2-注销 3-冻结 4-已删除',
    is_guest BOOLEAN NOT NULL DEFAULT FALSE,
    guest_expires_at DATETIME DEFAULT NULL,
    last_login_at DATETIME DEFAULT NULL,
    last_login_ip VARCHAR(45) DEFAULT NULL,
    last_login_device VARCHAR(255) DEFAULT NULL,
    login_count INT NOT NULL DEFAULT 0,
    risk_level TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
    deleted_reason VARCHAR(255) DEFAULT NULL,
    UNIQUE KEY uk_uuid (uuid),
    UNIQUE KEY uk_phone_hash (phone_hash),
    UNIQUE KEY uk_email (email),
    INDEX idx_status (status),
    INDEX idx_life_stage (life_stage),
    INDEX idx_is_guest (is_guest),
    INDEX idx_created_at (created_at),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_profiles
CREATE TABLE user_profiles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    constitution_type VARCHAR(30) DEFAULT NULL,
    constitution_sub_type VARCHAR(30) DEFAULT NULL,
    constitution_tested_at DATETIME DEFAULT NULL,
    province VARCHAR(50) DEFAULT NULL,
    city VARCHAR(50) DEFAULT NULL,
    sleep_quality TINYINT DEFAULT NULL,
    mood_status TINYINT DEFAULT NULL,
    health_concerns JSON DEFAULT NULL,
    diet_preferences JSON DEFAULT NULL,
    ai_interaction_count INT NOT NULL DEFAULT 0,
    content_view_count INT NOT NULL DEFAULT 0,
    bio TEXT DEFAULT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_constitution (constitution_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_preferences
CREATE TABLE user_preferences (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    language VARCHAR(10) NOT NULL DEFAULT 'zh-CN',
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    push_mute_start TIME DEFAULT NULL,
    push_mute_end TIME DEFAULT NULL,
    daily_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    daily_reminder_time TIME DEFAULT '08:00:00',
    solar_term_reminder BOOLEAN NOT NULL DEFAULT TRUE,
    ai_voice_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ai_style VARCHAR(20) NOT NULL DEFAULT 'warm',
    data_collection BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_auth_providers
CREATE TABLE user_auth_providers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    provider VARCHAR(20) NOT NULL,
    provider_uid VARCHAR(255) NOT NULL,
    provider_token TEXT DEFAULT NULL,
    provider_token_expires DATETIME DEFAULT NULL,
    linked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at DATETIME DEFAULT NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_provider (provider),
    UNIQUE KEY uk_provider_uid (provider, provider_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_devices（设备管理）
CREATE TABLE user_devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_id VARCHAR(64) NOT NULL,
    device_name VARCHAR(100) DEFAULT NULL,
    device_model VARCHAR(100) DEFAULT NULL,
    os_version VARCHAR(50) DEFAULT NULL,
    app_version VARCHAR(50) DEFAULT NULL,
    push_token VARCHAR(512) DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_active_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    UNIQUE KEY uk_device_id (device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 3.13 API 设计

### POST /api/v1/auth/send-code

发送短信验证码。

**Request:**

```json
{
  "phone": "13800138000",
  "purpose": "register"   // register | login | bind | reset
}
```

**Response (200):**

```json
{
  "code": 0,
  "message": "验证码已发送",
  "data": {
    "expire_in": 300,
    "retry_after": 60
  }
}
```

**Error:**

| HTTP | code | 说明 |
|------|------|------|
| 429 | 10001 | 发送过于频繁 |
| 400 | 10002 | 手机号格式不正确 |
| 400 | 10003 | 该手机号已注册 |

### POST /api/v1/auth/register

注册新用户。

**Request:**

```json
{
  "phone": "13800138000",
  "code": "123456",
  "nickname": "养生达人",
  "register_source": "app"
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "user": {
      "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "nickname": "养生达人",
      "avatar_url": null,
      "is_guest": false
    },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "expires_in": 1800,
      "refresh_expires_in": 2592000
    }
  }
}
```

### POST /api/v1/auth/login

登录。

**Request（手机号验证码登录）:**

```json
{
  "phone": "13800138000",
  "code": "123456",
  "device_id": "device-uuid",
  "device_name": "iPhone 15 Pro",
  "device_model": "iPhone15,2",
  "os_version": "17.3",
  "app_version": "1.0.0",
  "push_token": "apns-token-xxx"
}
```

**Request（Apple登录）:**

```json
{
  "provider": "apple",
  "identity_token": "apple-id-token-xxx",
  "authorization_code": "apple-auth-code-xxx",
  "device_id": "device-uuid",
  "device_name": "iPhone 15 Pro"
}
```

**Request（微信登录）:**

```json
{
  "provider": "wechat",
  "code": "wx-auth-code-xxx",
  "device_id": "device-uuid",
  "device_name": "iPhone 15 Pro"
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "user": {
      "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "nickname": "养生达人",
      "avatar_url": "https://oss.../avatar.jpg",
      "membership_level": "free",
      "life_stage": "career"
    },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "expires_in": 1800,
      "refresh_expires_in": 2592000
    },
    "risk_action": null,
    "new_device": false
  }
}
```

### POST /api/v1/auth/refresh

刷新Token。

**Request:**

```json
{
  "refresh_token": "eyJ..."
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 1800,
    "refresh_expires_in": 2592000
  }
}
```

### POST /api/v1/auth/logout

注销登录。

**Request:**

```json
{
  "refresh_token": "eyJ...",
  "device_id": "device-uuid"
}
```

**Response (200):**

```json
{
  "code": 0,
  "message": "已注销"
}
```

### POST /api/v1/auth/delete-account

申请删除账号。

**Request:**

```json
{
  "reason": "privacy_concern",  // privacy_concern | no_longer_use | not_satisfied | other
  "confirmation": "确认删除我的账号"
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "deletion_scheduled_at": "2026-04-16T19:36:00+08:00",
    "grace_period_days": 30
  }
}
```

### POST /api/v1/auth/restore-account

恢复已删除账号（30天内）。

**Request:**

```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

### GET /api/v1/auth/me

获取当前用户信息。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "nickname": "养生达人",
    "avatar_url": "https://oss.../avatar.jpg",
    "gender": 1,
    "life_stage": "career",
    "membership": {
      "level": "yangxin",
      "expire_at": "2026-06-17"
    },
    "constitution": {
      "type": "qi_xu",
      "sub_type": "yang_xu"
    },
    "preferences": {
      "push_enabled": true,
      "daily_reminder_time": "08:00",
      "ai_style": "warm"
    }
  }
}
```

### PUT /api/v1/auth/profile

更新用户资料。

**Request:**

```json
{
  "nickname": "新昵称",
  "gender": 1,
  "birthday": "1990-05-20",
  "province": "浙江",
  "city": "杭州",
  "bio": "热爱养生"
}
```

---

## 3.14 错误码设计

| 错误码 | HTTP | 说明 |
|--------|------|------|
| 10001 | 429 | 验证码发送过于频繁 |
| 10002 | 400 | 手机号格式不正确 |
| 10003 | 400 | 该手机号已注册 |
| 10004 | 400 | 该手机号未注册 |
| 10005 | 401 | 验证码错误或已过期 |
| 10006 | 401 | Access Token无效或已过期 |
| 10007 | 401 | Refresh Token无效或已过期 |
| 10008 | 403 | 账号已被冻结 |
| 10009 | 403 | 账号已被删除 |
| 10010 | 400 | 第三方授权失败 |
| 10011 | 409 | 该第三方账号已绑定其他用户 |
| 10012 | 400 | 确认文字不匹配 |
| 10013 | 400 | 账号有活跃订阅，请先取消 |
| 10014 | 400 | 账号是家庭创建者，请先转让或解散 |
| 10015 | 403 | 设备数量超出上限 |
| 10016 | 401 | 检测到Token泄露，所有设备已登出 |
| 10017 | 403 | 风险操作需二次验证 |
| 10018 | 400 | 游客账号已过期 |

---

## 3.15 安全策略

### 密码安全（预留）

- bcrypt 哈希，cost factor = 12
- 密码复杂度：至少8位，含大小写字母+数字+特殊字符

### 短信安全

- 验证码仅6位数字，5分钟有效
- 同一手机号频率限制
- 服务端验证码不返回给前端（仅存储比对）

### Token 安全

- RS256 非对称签名
- Token Rotation（每次刷新生成新对）
- Refresh Token 家族检测
- Token 黑名单（Redis）
- Token Payload 不含敏感信息

### 数据安全

- 手机号 AES-256 加密存储，查询用 hash
- 敏感字段（email等）脱敏返回
- 接口限流（IP + 用户维度）
- CORS 白名单
- SQL注入防护（ORM参数化查询）
- XSS防护（输出编码）

### 传输安全

- 全量 HTTPS
- TLS 1.2+
- HSTS
- Certificate Pinning（移动端）

---

## 3.16 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| membership | 依赖 | 用户UUID是会员订阅的外键 |
| ai-chat | 依赖 | 用户ID关联所有对话记录 |
| constitution | 依赖 | 用户ID关联体质测试结果 |
| dashboard | 依赖 | 首页需获取用户信息 |
| family | 依赖 | 家庭模块需要用户认证 |
| notification | 依赖 | 推送需要设备信息 |
| analytics | 依赖 | 注册/登录事件上报 |

---

# 第四章 会员购买系统

## 4.1 概述

会员购买系统管理顺时 ShunShi 的商业化体系，定义四档会员层级、权益矩阵、订阅生命周期和支付集成。系统通过权益中间件实现精细化的功能权限控制。

---

## 4.2 会员层级

| 层级 | 代码 | 定位 | 核心卖点 |
|------|------|------|---------|
| 免费 | `free` | 基础体验 | 体质测试、节气浏览、每日3次AI对话 |
| 养心 | `yangxin` | 入门会员 | AI无限对话、内容解锁、体质详解 |
| 颐养 | `yiyang` | 进阶会员 | 家庭2席位、AI深度分析、节气定制方案 |
| 家和 | `jiahe` | 家庭会员 | 家庭5席位、全家AI、家庭健康报告 |

---

## 4.3 权益矩阵

### 4.3.1 功能权益矩阵

| 功能项 | 免费 | 养心 | 颐养 | 家和 |
|--------|:----:|:----:|:----:|:----:|
| 体质测试 | ✅ 1次/月 | ✅ 无限 | ✅ 无限 | ✅ 无限 |
| 节气浏览 | ✅ 基础 | ✅ 基础 | ✅ 深度 | ✅ 深度 |
| 每日AI对话 | 3次/天 | 无限 | 无限 | 无限 |
| AI记忆周期 | 当次 | 7天 | 30天 | 永久 |
| AI响应速度 | 普通 | 优先 | 优先 | 最高优先 |
| AI模型 | qwen-turbo | qwen-plus | qwen-plus | qwen-plus |
| 内容浏览 | 基础 | 全部 | 全部 | 全部 |
| 内容收藏 | 10篇 | 100篇 | 无限 | 无限 |
| 节气提醒 | ✅ | ✅ | ✅ + 详情 | ✅ + 详情 |
| 每日计划 | 1条 | 3条 | 5条 | 5条 |
| 情绪日记 | ❌ | ✅ | ✅ + 分析 | ✅ + 分析 |
| 家庭席位 | 0 | 0 | 2 | 5 |
| 家庭健康报告 | ❌ | ❌ | ✅ 月报 | ✅ 周报+月报 |
| 专属客服 | ❌ | ❌ | ❌ | ✅ |
| 去广告 | ❌ | ✅ | ✅ | ✅ |
| 优先体验新功能 | ❌ | ❌ | ✅ | ✅ |

### 4.3.2 AI能力权益矩阵

| AI能力 | 免费 | 养心 | 颐养 | 家和 |
|--------|:----:|:----:|:----:|:----:|
| 基础养生问答 | ✅ | ✅ | ✅ | ✅ |
| 体质解读 | 简要 | 详细 | 详细+建议 | 详细+建议 |
| 节气调养方案 | ❌ | ✅ | ✅ | ✅ |
| 情绪关怀 | ❌ | 基础 | 深度 | 深度 |
| 食谱推荐 | ❌ | 3个/次 | 10个/次 | 无限 |
| 穴位推荐 | ❌ | ❌ | ✅ | ✅ |
| 运动方案 | ❌ | 基础 | 定制 | 定制 |
| 家庭成员分析 | ❌ | ❌ | ❌ | ✅ |

---

## 4.4 SKU管理

### 4.4.1 产品定义 (products 表)

| product_id | 名称 | 层级 | 平台 | 价格(¥) | 原价(¥) | 周期(天) | 标签 |
|-----------|------|------|------|---------|---------|---------|------|
| yangxin_month_alipay | 养心月卡 | yangxin | alipay | 18 | 28 | 30 | - |
| yangxin_quarter_alipay | 养心季卡 | yangxin | alipay | 48 | 84 | 90 | 省30% |
| yangxin_year_alipay | 养心年卡 | yangxin | alipay | 168 | 336 | 365 | 省50% |
| yangxin_month_ios | 养心月卡 | yangxin | ios | 28 | 28 | 30 | - |
| yangxin_year_ios | 养心年卡 | yangxin | ios | 268 | 336 | 365 | 省20% |
| yiyang_month_alipay | 颐养月卡 | yiyang | alipay | 38 | 58 | 30 | - |
| yiyang_quarter_alipay | 颐养季卡 | yiyang | alipay | 98 | 174 | 90 | 省30% |
| yiyang_year_alipay | 颐养年卡 | yiyang | alipay | 368 | 696 | 365 | 省47% |
| yiyang_month_ios | 颐养月卡 | yiyang | ios | 48 | 58 | 30 | - |
| yiyang_year_ios | 颐养年卡 | yiyang | ios | 548 | 696 | 365 | 省21% |
| jiahe_month_alipay | 家和月卡 | jiahe | alipay | 68 | 98 | 30 | - |
| jiahe_quarter_alipay | 家和季卡 | jiahe | alipay | 178 | 294 | 90 | 省40% |
| jiahe_year_alipay | 家和年卡 | jiahe | alipay | 588 | 1176 | 365 | 省50% |
| jiahe_month_ios | 家和月卡 | jiahe | ios | 88 | 98 | 30 | - |
| jiahe_year_ios | 家和年卡 | jiahe | ios | 898 | 1176 | 365 | 省24% |

### 4.4.2 试用策略

| 层级 | 试用时长 | 试用条件 | 试用权益 |
|------|---------|---------|---------|
| 养心 | 3天 | 新注册用户首次 | 养心全部权益 |
| 颐养 | 3天 | 养心到期后首次升级 | 颐养全部权益 |
| 家和 | 无试用 | - | - |

---

## 4.5 购买流程

```
用户进入会员页面
    │
    ▼
GET /api/v1/membership/products → 商品列表
    │
    ▼
用户选择商品
    │
    ▼
POST /api/v1/membership/create-order → 创建订单
    │
    ├── 支付宝 → 返回支付宝支付参数 → 调起支付宝SDK
    │
    ├── Apple IAP → 返回product_id → 调起StoreKit
    │
    └── Google Billing → 返回product_id → 调起BillingClient
    │
    ▼
用户完成支付
    │
    ▼
支付平台回调 → POST /api/v1/membership/payment-callback
    │
    ├── 验签成功 → 更新订单状态为PAID
    │              → 激活/续期订阅
    │              → 更新权益缓存
    │              → 发送确认通知
    │
    └── 验签失败 → 记录异常日志 → 人工审核
    │
    ▼
客户端轮询/推送 → 订单状态变为PAID → 展示购买成功
```

---

## 4.6 订单流转图

```
                    ┌──────────┐
                    │  待创建   │
                    └────┬─────┘
                         │ create-order
                         ▼
                    ┌──────────┐
               ┌───│  待支付   │
               │   │ PENDING  │
               │   └────┬─────┘
               │        │
               │   ┌────┼───────────────┐
               │   │    │               │
               │   ▼    ▼               ▼
               │ ┌──────┐ ┌──────┐ ┌────────┐
               │ │已支付│ │已取消│ │ 支付中 │
               │ │ PAID │ │CANCEL│ │PAYING │
               │ └──┬───┘ └──────┘ └───┬────┘
               │    │                  │
               │    ▼                  ▼
               │ ┌──────┐         ┌────────┐
               │ │已退款│         │ 超时   │
               │ │REFUND│         │EXPIRED │
               │ └──────┘         └───┬────┘
               │                       │
               └───────────────────────┘ (自动关闭)
```

**状态定义：**

| 状态 | 值 | 说明 |
|------|---|------|
| 待支付 | PENDING | 订单创建，等待支付 |
| 支付中 | PAYING | 用户已调起支付（Apple/Google专用） |
| 已支付 | PAID | 支付成功，权益已生效 |
| 已取消 | CANCELLED | 用户取消支付 |
| 已退款 | REFUNDED | 退款成功 |
| 已过期 | EXPIRED | 超时未支付（15分钟） |

---

## 4.7 订阅状态机

```
              ┌──────────┐
              │  未订阅   │
              │   NONE   │
              └────┬─────┘
                   │ 首次购买/试用
                   ▼
              ┌──────────┐
              │   试用中  │──── 试用结束 ──→ 过期(回退免费)
              │  TRIAL   │
              └────┬─────┘
                   │ 试用中购买/直接购买
                   ▼
              ┌──────────┐
              │   活跃   │──── 到期未续费 ──→ 过期
              │  ACTIVE  │──── 用户取消续费 ──→ 取消续费(CANCELLED)
              └────┬─────┘
                   │ 续费/升降级
                   ▼
              ┌──────────┐
              │   活跃   │
              │  ACTIVE  │
              └──────────┘
                   │
                   ▼
              ┌──────────┐
              │   过期   │──── 重新购买 ──→ 活跃
              │ EXPIRED  │──── 7天宽限期支付 ──→ 活跃(不中断)
              └──────────┘
                   │
                   ▼ (7天宽限期后)
              ┌──────────┐
              │   回退   │
              │ FALLEN   │ (回退到free或下一级)
              └──────────┘
```

**宽限期策略：**

| 层级 | 宽限期 | 宽限期内权益 |
|------|--------|------------|
| 养心 | 7天 | 保留养心权益 |
| 颐养 | 7天 | 回退养心权益 |
| 家和 | 7天 | 回退颐养权益 |

---

## 4.8 支付集成

### 4.8.1 支付宝

```
创建订单 → 调用支付宝统一下单API → 获取支付参数
→ 客户端调起支付宝SDK → 用户支付
→ 支付宝异步回调 /api/v1/membership/callback/alipay
→ 验签 → 更新订单
```

**关键配置：**

- 签名算法：RSA2
- 回调地址：需在支付宝商户后台配置
- 超时时间：15分钟
- 幂等处理：以商户订单号为幂等键

### 4.8.2 Apple IAP

```
客户端从App Store获取Product → 用户选择 → 调起支付
→ 支付成功 → 客户端上传receipt到后端
→ 后端调用Apple Server API验证receipt
→ 验证成功 → 更新订单 → 管理订阅状态
```

**关键配置：**

- 使用 Server-to-Server Notification V2
- 原始交易ID（originalTransactionId）作为订阅标识
- 处理退款、价格调整、试用期等事件
- 沙盒环境用于测试

### 4.8.3 Google Billing

```
客户端查询Google Play商品 → 用户选择 → 调起BillingClient
→ 支付成功 → 获取purchaseToken
→ 上传purchaseToken到后端 → 调用Google Play Developer API验证
→ 验证成功 → 更新订单
```

**关键配置：**

- Real-time Developer Notifications (RTDN) 接收
- purchaseToken 作为订阅标识
- 处理退款、订阅恢复等事件

---

## 4.9 恢复购买

**场景：** 用户换设备、重装App后恢复已有订阅。

**流程：**

```
用户点击"恢复购买"
    │
    ▼
客户端：
  iOS → 调用 StoreKit.restoreCompletedTransactions()
  Android → 调用 BillingClient.queryPurchasesAsync()
    │
    ▼
获取活跃订阅凭证
    │
    ▼
POST /api/v1/membership/restore
  Body: { platform: "ios", receipt: "..." } 或 { platform: "android", purchase_token: "..." }
    │
    ▼
后端验证凭证 → 查找关联订单 → 恢复订阅状态
    │
    ▼
返回当前订阅信息
```

---

## 4.10 续费/取消续费

### 自动续费

- 支付宝：签约代扣（周期扣款）
- Apple IAP：StoreKit自动续费订阅
- Google Billing：自动续费订阅

### 取消续费

```
用户取消续费
    │
    ├── 支付宝 → 调用支付宝取消签约API
    │
    ├── Apple → 提供系统设置路径引导用户取消
    │
    └── Google → 调用Google Play API取消
    │
    ▼
更新 subscription.auto_renew = false
更新 subscription.current_period_end（当前周期结束仍可用）
发送确认通知
```

**到期提醒策略：**

| 时间节点 | 动作 |
|---------|------|
| 到期前7天 | 推送提醒"您的会员即将到期" |
| 到期前3天 | 推送提醒 + App内弹窗 |
| 到期前1天 | 推送提醒 + 优惠续费提示 |
| 到期当天 | 通知到期 + 引导续费 |

---

## 4.11 过期回退

```
订阅到期 + 宽限期结束
    │
    ▼
Celery定时任务检测（每小时）
    │
    ▼
查找所有 expired_at < NOW() - 7天 的订阅
    │
    ▼
执行回退：
  1. 更新 subscription.status = FALLEN
  2. 回退用户权益到下一级或free
  3. 更新Redis权益缓存
  4. 发送到期通知
  5. AI记忆按新层级的保留周期裁剪
  6. 家庭成员超额时按活跃度排序保留
```

---

## 4.12 权益缓存与刷新

### Redis 缓存结构

```
# 用户权益缓存
Key: membership:benefits:{user_uuid}
Value: JSON {
  "level": "yangxin",
  "status": "active",
  "expire_at": "2026-06-17T00:00:00+08:00",
  "features": {
    "ai_daily_limit": -1,
    "ai_memory_days": 7,
    "ai_model": "qwen-plus",
    "content_access": "all",
    "family_seats": 0,
    "daily_plan_count": 3
  }
}
TTL: 24小时
```

### 缓存失效策略

| 触发条件 | 动作 |
|---------|------|
| 订阅购买/续费/升级 | 立即刷新缓存 |
| 退款 | 立即清除缓存（下次请求重建） |
| 取消续费 | 不清除（当前周期权益保留） |
| 过期回退 | 定时任务刷新 |
| 手动刷新 | 管理后台操作 |

---

## 4.13 权限控制

### 权益中间件设计

```python
# FastAPI Dependency
async def require_membership(
    feature: str,           # 功能标识：ai_chat, content_premium, family_manage...
    min_level: str = None,  # 最低层级：free, yangxin, yiyang, jiahe
    current_user = Depends(get_current_user)
) -> User:
    """权益检查中间件"""
    benefits = await get_user_benefits(current_user.uuid)
    
    # 检查层级
    if min_level and LEVEL_ORDER[benefits.level] < LEVEL_ORDER[min_level]:
        raise MembershipRequiredError(min_level)
    
    # 检查功能
    if not benefits.features.get(feature, False):
        raise FeatureLockedError(feature)
    
    # 检查用量
    if feature == "ai_chat":
        daily_usage = await get_daily_ai_usage(current_user.id)
        limit = benefits.features["ai_daily_limit"]
        if limit > 0 and daily_usage >= limit:
            raise DailyLimitExceededError(limit)
    
    return current_user
```

### 权限控制维度

| 维度 | 控制方式 | 示例 |
|------|---------|------|
| 功能开关 | `benefits.features[feature]` | AI对话、情绪日记 |
| 接口限制 | 中间件 `require_membership` | `/ai/chat` 需要会员 |
| 内容解锁 | 内容表 `required_level` 字段 | 高级文章需养心+ |
| AI能力 | AI Router 层级判断 | 模型选择、响应深度 |
| 记忆周期 | 缓存定期裁剪 | 免费用户仅当次 |
| 家庭席位 | family模块校验 | 超席位的成员降级 |
| API限流 | 基于会员等级的限流 | 免费用户更严格的频率限制 |

---

## 4.14 数据表设计

### subscriptions 表

```sql
CREATE TABLE subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    level VARCHAR(20) NOT NULL COMMENT 'free/yangxin/yiyang/jiahe',
    status VARCHAR(20) NOT NULL DEFAULT 'none' COMMENT 'none/trial/active/expired/fallen/cancelled',
    platform VARCHAR(20) DEFAULT NULL COMMENT 'alipay/ios/android',
    provider_subscription_id VARCHAR(255) DEFAULT NULL COMMENT '第三方订阅ID',
    current_period_start DATETIME DEFAULT NULL,
    current_period_end DATETIME DEFAULT NULL,
    trial_start DATETIME DEFAULT NULL,
    trial_end DATETIME DEFAULT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    cancel_reason VARCHAR(255) DEFAULT NULL,
    cancelled_at DATETIME DEFAULT NULL,
    upgraded_from VARCHAR(20) DEFAULT NULL COMMENT '升级前的层级',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_platform (platform),
    INDEX idx_current_period_end (current_period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### subscription_orders 表

```sql
CREATE TABLE subscription_orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL COMMENT '商户订单号',
    user_id BIGINT NOT NULL,
    product_id VARCHAR(64) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    level VARCHAR(20) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    amount_cents INT NOT NULL COMMENT '金额（分）',
    currency VARCHAR(3) NOT NULL DEFAULT 'CNY',
    duration_days INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_no VARCHAR(128) DEFAULT NULL COMMENT '第三方支付单号',
    paid_at DATETIME DEFAULT NULL,
    refund_no VARCHAR(128) DEFAULT NULL,
    refunded_at DATETIME DEFAULT NULL,
    refund_reason VARCHAR(255) DEFAULT NULL,
    expires_at DATETIME DEFAULT NULL COMMENT '订单超时时间',
    metadata JSON DEFAULT NULL COMMENT '扩展信息',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_no (order_no),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_payment_no (payment_no),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### products 表

```sql
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(64) NOT NULL COMMENT '产品标识',
    name VARCHAR(100) NOT NULL,
    level VARCHAR(20) NOT NULL,
    platform VARCHAR(20) NOT NULL COMMENT 'alipay/ios/android',
    price_cents INT NOT NULL COMMENT '售价（分）',
    original_price_cents INT NOT NULL COMMENT '原价（分）',
    currency VARCHAR(3) NOT NULL DEFAULT 'CNY',
    duration_days INT NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    tag VARCHAR(50) DEFAULT NULL COMMENT '标签（如"省50%"）',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    trial_days INT DEFAULT 0 COMMENT '附赠试用天数',
    metadata JSON DEFAULT NULL COMMENT '第三方商品信息(product_id等)',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_product_id (product_id),
    INDEX idx_level_platform (level, platform),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 4.15 API 设计

### GET /api/v1/membership/products

获取商品列表。

**Query:** `?platform=alipay`（必需，指定平台）

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "products": [
      {
        "product_id": "yangxin_month_alipay",
        "name": "养心月卡",
        "level": "yangxin",
        "price": "¥18.00",
        "original_price": "¥28.00",
        "price_cents": 1800,
        "original_price_cents": 2800,
        "duration_days": 30,
        "tag": null,
        "is_popular": false
      },
      {
        "product_id": "yangxin_quarter_alipay",
        "name": "养心季卡",
        "level": "yangxin",
        "price": "¥48.00",
        "original_price": "¥84.00",
        "price_cents": 4800,
        "original_price_cents": 8400,
        "duration_days": 90,
        "tag": "省30%",
        "is_popular": true
      }
    ],
    "current_subscription": {
      "level": "free",
      "status": "none",
      "expire_at": null
    }
  }
}
```

### POST /api/v1/membership/create-order

创建订单。

**Request:**

```json
{
  "product_id": "yangxin_quarter_alipay",
  "platform": "alipay"
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "order_no": "SS20260317193600001",
    "amount": "¥48.00",
    "payment_params": {
      "order_string": "alipay_sdk=..."
    }
  }
}
```

### POST /api/v1/membership/callback/alipay

支付宝回调（服务端→服务端，非客户端调用）。

### POST /api/v1/membership/callback/apple

Apple IAP 回调。

### POST /api/v1/membership/callback/google

Google Billing 回调。

### POST /api/v1/membership/restore

恢复购买。

**Request:**

```json
{
  "platform": "ios",
  "receipt": "base64-receipt-data"
}
```

### POST /api/v1/membership/cancel-auto-renew

取消自动续费。

### GET /api/v1/membership/status

获取当前订阅状态。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "level": "yangxin",
    "status": "active",
    "platform": "alipay",
    "current_period_start": "2026-03-17T00:00:00+08:00",
    "current_period_end": "2026-06-15T23:59:59+08:00",
    "auto_renew": true,
    "benefits": {
      "ai_daily_limit": -1,
      "ai_memory_days": 7,
      "ai_model": "qwen-plus",
      "content_access": "all",
      "family_seats": 0,
      "daily_plan_count": 3,
      "emotion_diary": true,
      "ad_free": true
    }
  }
}
```

### GET /api/v1/membership/orders

获取订单列表。

**Query:** `?page=1&size=20&status=PAID`

### POST /api/v1/membership/verify-receipt

验证收据（客户端支付成功后调用）。

**Request:**

```json
{
  "platform": "ios",
  "order_no": "SS20260317193600001",
  "receipt": "base64-receipt",
  "transaction_id": "apple-transaction-id"
}
```

---

## 4.16 异常处理

| 场景 | 处理 |
|------|------|
| 支付回调重复 | 幂等处理：以order_no查重 |
| 回调验签失败 | 记录日志，返回403，通知运维 |
| 支付成功但回调未到达 | 客户端轮询 + 补单任务（每15分钟） |
| Apple/Google服务不可用 | 返回503，客户端重试 |
| 退款后权益未回退 | RTDN回调处理 + 定时对账 |
| 订单超时未支付 | 定时任务关闭（15分钟） |
| 降级购买（高→低） | 当前周期结束后生效 |

---

## 4.17 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| user | 强依赖 | 订阅以user_id为外键 |
| payment | 强依赖 | 支付流程由payment模块处理 |
| ai-chat | 权益控制 | AI对话次数限制、模型选择 |
| ai-router | 权益控制 | 不同层级不同Prompt深度 |
| content | 权益控制 | 内容访问权限 |
| family | 权益控制 | 席位数量 |
| dashboard | 读取 | 首页展示会员状态 |
| notification | 依赖 | 到期提醒、续费提醒 |

---

# 第五章 首页节律系统

## 5.1 概述

首页节律系统是顺时 ShunShi 的核心聚合页面，根据用户的生命阶段、体质、情绪状态和当前节气，动态生成个性化的养生首页。系统聚合多个模块数据，为用户提供"打开即有用"的体验。

---

## 5.2 页面模块结构

### 5.2.1 模块组成

| 模块 | 代码 | 说明 | 优先级 |
|------|------|------|--------|
| 问候卡片 | `greeting` | 个性化问候+日期+天气+节气 | P0 |
| 每日洞察 | `daily_insight` | 一句话养生要点 | P0 |
| 每日计划 | `daily_plan` | 3-5条个性化养生建议 | P0 |
| AI入口 | `ai_entry` | 对话入口（问题建议气泡） | P0 |
| 跟进卡片 | `follow_up` | 待完成的测试/提醒/计划 | P1 |
| 节气专区 | `solar_spotlight` | 当前节气+调养方案入口 | P1 |
| 家庭动态 | `family_activity` | 家庭成员健康动态（家和会员） | P2 |
| 推荐内容 | `recommended_content` | 个性化内容推荐卡片 | P1 |
| 情绪签到 | `mood_check` | 每日情绪快速记录（养心+） | P2 |

### 5.2.2 页面布局（从上到下）

```
┌─────────────────────────────────┐
│  🌅 早上好，feifei              │  ← Greeting
│  2026年3月17日 · 春分后第2天    │
│  杭州 · 18°C 多云               │
├─────────────────────────────────┤
│  💡 春分时节重在养肝，           │  ← Daily Insight
│  早睡早起助阳气生发             │
├─────────────────────────────────┤
│  📋 今日养生计划                 │  ← Daily Plan
│  ├─ 🍵 饮一杯玫瑰花茶疏肝理气   │
│  ├─ 🚶 饭后散步20分钟健脾和胃   │
│  └─ 🧘 晚间8点做拉伸助入眠      │
├─────────────────────────────────┤
│  🤖 有什么养生问题想问？         │  ← AI Entry
│     ┌──────┐ ┌──────────────┐  │
│     │春分吃│ │最近总是失眠怎│  │
│     │什么好│ │么调理？      │  │
│     └──────┘ └──────────────┘  │
├─────────────────────────────────┤
│  🔄 待完成                      │  ← Follow-up
│  ├─ 📊 体质测试已有30天未重测    │
│  └─ 💊 春分调养方案查看         │
├─────────────────────────────────┤
│  🌿 春分 · 节气调养             │  ← Solar Spotlight
│  3月20日-4月4日 · 饮食运动全方案│
├─────────────────────────────────┤
│  📚 为你推荐                    │  ← Recommended Content
│  ┌──────┐ ┌──────┐ ┌──────┐  │
│  │ 文章 │ │ 视频 │ │ 文章 │  │
│  └──────┘ └──────┘ └──────┘  │
└─────────────────────────────────┘
```

---

## 5.3 根据 life_stage 动态调整优先级

| life_stage | 显示调整 | 推荐侧重点 |
|-----------|---------|-----------|
| youth (青年) | 强调运动/饮食/情志 | 运动方案、社交养生 |
| student (学生) | 简化问候，强调用眼/作息 | 穴位护眼、学习养生 |
| career (职场) | 强调节奏、减压、通勤 | 办公养生、午休方案 |
| marriage (新婚) | 强调双方调养 | 夫妻养生、备养方案 |
| parenting (育儿) | 强调母婴/亲子养生 | 儿童体质、妈妈恢复 |
| middle (中年) | 强调体检、慢病预防 | 体质调养、穴位保健 |
| elder (老年) | 大字体，简化操作 | 经络养生、慢病饮食 |

**实现方式：**

```python
LAYOUT_PRIORITY = {
    "youth": ["greeting", "daily_plan", "ai_entry", "recommended_content", "solar_spotlight"],
    "student": ["greeting", "daily_plan", "ai_entry", "solar_spotlight", "recommended_content"],
    "career": ["greeting", "daily_insight", "daily_plan", "ai_entry", "follow_up", "recommended_content"],
    "parenting": ["greeting", "daily_plan", "family_activity", "ai_entry", "recommended_content"],
    "elder": ["greeting", "daily_plan", "solar_spotlight", "ai_entry", "mood_check"]
}
```

---

## 5.4 Daily Plan 生成逻辑

### 5.4.1 输入因子

| 因子 | 来源 | 权重 | 说明 |
|------|------|------|------|
| 体质 | user_profiles.constitution_type | 30% | 主要体质决定养生方向 |
| 节气 | solar-term-service | 25% | 当前节气养生重点 |
| 情绪 | user_profiles.mood_status | 20% | 情绪低落时增加舒缓建议 |
| 睡眠 | user_profiles.sleep_quality | 15% | 睡眠差时增加助眠建议 |
| 生命阶段 | users.life_stage | 10% | 调整建议形式和复杂度 |

### 5.4.2 生成流程

```
每日 00:00 (UTC+8) 或用户首次打开时
    │
    ▼
读取用户状态：
  constitution_type, mood_status, sleep_quality, life_stage
    │
    ▼
获取当前节气：
  solar-term-service.current_term()
    │
    ▼
构建推荐因子向量：
  factors = {
    constitution: "qi_xu",
    solar_term: "chunfen",
    mood: "calm",
    sleep: 3,
    life_stage: "career"
  }
    │
    ▼
调用推荐引擎（规则+AI混合）：
  1. 规则层：根据体质+节气匹配预设建议模板库
  2. 筛选层：根据mood/sleep过滤不适合的建议
  3. 排序层：根据权重计算综合得分
  4. AI层（可选）：调用AI对Top-5建议进行个性化微调
    │
    ▼
输出 Top 3-5 条建议：
  [
    {
      "category": "diet",
      "title": "饮一杯玫瑰花茶疏肝理气",
      "detail": "春分时节肝气旺盛，玫瑰花茶可疏肝解郁...",
      "icon": "🍵",
      "action": {"type": "content", "id": "xxx"}
    },
    ...
  ]
    │
    ▼
缓存到 Redis (TTL: 24h)
```

### 5.4.3 建议模板库

| 分类 | 代码 | 示例数量 |
|------|------|---------|
| 饮食 | diet | 200+ |
| 茶饮 | tea | 100+ |
| 运动 | exercise | 100+ |
| 穴位 | acupoint | 80+ |
| 情志 | emotion | 80+ |
| 作息 | sleep | 60+ |
| 行动 | action | 100+ |

每个模板包含：
```json
{
  "id": "diet_chunfen_qixu_001",
  "category": "diet",
  "title_template": "今日宜食{food}，{effect}",
  "detail_template": "{reason}。推荐{recipe}。",
  "tags": ["chunfen", "qi_xu", "liver"],
  "params": {
    "food": "菠菜",
    "effect": "滋阴养肝",
    "reason": "春分肝气旺盛，气虚体质需滋阴",
    "recipe": "凉拌菠菜配芝麻"
  },
  "priority": 0.8,
  "required_level": "free"
}
```

---

## 5.5 数据聚合逻辑

```
Dashboard API 内部调用链：

GET /api/v1/dashboard
    │
    ├── 并行查询 ──────────────────────────────┐
    │                                            │
    ├── user-service.get_profile()              │ 用户信息
    │                                            │
    ├── constitution-service.get_type()         │ 体质信息
    │                                            │
    ├── solar-term-service.current_term()       │ 当前节气
    │                                            │
    ├── membership-service.get_benefits()       │ 会员权益
    │                                            │
    ├── cache.get(daily_plan:{user_uuid})       │ 每日计划缓存
    │   ├── hit → 直接返回                        │
    │   └── miss → 生成新计划 → 写入缓存          │
    │                                            │
    ├── content-service.recommend()             │ 推荐内容
    │                                            │
    ├── family-service.activity_feed()          │ 家庭动态(家和)
    │                                            │
    ├── ai-chat-service.get_suggestions()       │ AI问题建议
    │                                            │
    └── follow-up-service.get_pending()         │ 待跟进事项
                                                 │
    ◀────────────────────────────────────────────┘
    │
    ▼
聚合组装 → 返回 DashboardResponse
```

---

## 5.6 API 设计

### GET /api/v1/dashboard

获取首页数据（聚合）。

**Headers:** `Authorization: Bearer {access_token}`

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "greeting": {
      "text": "早上好，feifei",
      "period": "morning",
      "date": "2026年3月17日",
      "weekday": "星期二",
      "solar_term": {
        "name": "春分",
        "day_offset": 2,
        "next_term": "清明",
        "next_term_date": "2026-04-04"
      },
      "weather": {
        "temp": "18°C",
        "condition": "多云",
        "city": "杭州"
      }
    },
    "daily_insight": {
      "text": "春分时节重在养肝，早睡早起助阳气生发",
      "source": "solar_term"
    },
    "daily_plan": {
      "generated_at": "2026-03-17T00:00:00+08:00",
      "items": [
        {
          "id": "dp_001",
          "category": "tea",
          "title": "饮一杯玫瑰花茶疏肝理气",
          "detail": "春分时节肝气旺盛，玫瑰花茶可疏肝解郁",
          "icon": "🍵",
          "completed": false,
          "action": {
            "type": "content",
            "id": "content_tea_001"
          }
        },
        {
          "id": "dp_002",
          "category": "exercise",
          "title": "饭后散步20分钟健脾和胃",
          "detail": "春分宜舒缓运动，散步可促进消化",
          "icon": "🚶",
          "completed": false,
          "action": {
            "type": "content",
            "id": "content_exercise_001"
          }
        },
        {
          "id": "dp_003",
          "category": "sleep",
          "title": "晚间8点做拉伸助入眠",
          "detail": "入睡困难可尝试睡前拉伸放松",
          "icon": "🧘",
          "completed": false,
          "action": {
            "type": "ai_chat",
            "suggestion": "我最近睡眠不好，怎么调理？"
          }
        }
      ]
    },
    "ai_entry": {
      "suggestions": [
        { "text": "春分吃什么好？", "intent": "diet_advice" },
        { "text": "最近总是失眠怎么调理？", "intent": "sleep_advice" }
      ]
    },
    "follow_up": {
      "items": [
        {
          "type": "constitution_retest",
          "title": "体质测试已有30天未重测",
          "action": { "type": "constitution_test" }
        },
        {
          "type": "solar_plan",
          "title": "查看春分调养方案",
          "action": { "type": "content", "id": "solar_chunfen_plan" }
        }
      ]
    },
    "solar_spotlight": {
      "term_name": "春分",
      "term_date": "2026-03-20",
      "summary": "春分昼夜平分，养生重在调和阴阳",
      "cover_image": "https://oss.../chunfen.jpg",
      "action": { "type": "content", "id": "solar_chunfen_detail" }
    },
    "recommended_content": {
      "items": [
        {
          "id": "rec_001",
          "title": "春分养肝食疗方",
          "category": "diet",
          "cover_image": "https://oss.../diet1.jpg",
          "read_time": 3
        },
        {
          "id": "rec_002",
          "title": "春季运动指南",
          "category": "exercise",
          "cover_image": "https://oss.../exercise1.jpg",
          "read_time": 5
        }
      ]
    },
    "layout": {
      "sections": ["greeting", "daily_insight", "daily_plan", "ai_entry", "follow_up", "solar_spotlight", "recommended_content"],
      "version": "career_default"
    },
    "mood_check": {
      "enabled": true,
      "today_checked": false
    }
  }
}
```

### PUT /api/v1/dashboard/daily-plan/{item_id}/complete

标记计划项完成。

### GET /api/v1/dashboard/daily-plan/history

查看历史每日计划。

**Query:** `?page=1&size=7`

---

## 5.7 缓存策略

| 数据 | 缓存Key | TTL | 策略 |
|------|---------|-----|------|
| 每日计划 | `dashboard:plan:{user_uuid}:{date}` | 24h | 每日零点过期自动重建 |
| 问候信息 | `dashboard:greeting:{user_uuid}` | 1h | 手动刷新 |
| 节气数据 | `dashboard:solar:{date}` | 24h | 全局缓存 |
| 推荐内容 | `dashboard:content:{user_uuid}` | 4h | 滚动刷新 |
| 跟进事项 | `dashboard:followup:{user_uuid}` | 30min | 事件驱动刷新 |
| 家庭动态 | `dashboard:family:{family_id}` | 10min | 频繁更新 |

---

## 5.8 埋点策略

| 事件名 | 触发时机 | 参数 |
|--------|---------|------|
| `dashboard_view` | 首页曝光 | sections_count, load_time_ms |
| `daily_plan_view` | 每日计划曝光 | plan_items_count |
| `daily_plan_item_click` | 点击计划项 | item_id, category |
| `daily_plan_item_complete` | 完成计划项 | item_id, category, time_from_view |
| `ai_entry_click` | 点击AI入口 | suggestion_text |
| `follow_up_click` | 点击跟进事项 | follow_up_type |
| `solar_spotlight_click` | 点击节气专区 | term_name |
| `content_recommend_click` | 点击推荐内容 | content_id, position |
| `mood_check_submit` | 提交情绪签到 | mood_value |

---

## 5.9 异常处理

| 场景 | 处理 |
|------|------|
| 体质未测试 | daily_plan使用通用模板，follow_up提示完成测试 |
| 节气切换边界 | 缓存预热，提前1天准备下个节气方案 |
| 多模块查询超时 | 并行查询设置超时（500ms/模块），部分失败降级 |
| AI建议生成失败 | 降级到规则模板 |
| 推荐内容为空 | 使用热门内容兜底 |

---

## 5.10 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| user | 依赖 | 获取用户信息、life_stage |
| constitution | 依赖 | 获取体质类型用于个性化 |
| solar-term | 依赖 | 获取当前节气 |
| membership | 依赖 | 获取权益（每日计划数量等） |
| ai-chat | 依赖 | AI入口建议 |
| content | 依赖 | 推荐内容 |
| family | 依赖 | 家庭动态 |
| notification | 弱依赖 | 跟进提醒 |
| analytics | 依赖 | 埋点事件上报 |

---

# 第六章 AI对话系统

## 6.1 概述

AI对话系统是顺时 ShunShi 的核心交互模块，用户通过自然语言与AI养生助手对话，获取个性化的养生建议、体质解读、情绪关怀等服务。系统采用多轮对话管理、上下文窗口和记忆机制，实现持续精进的对话体验。

---

## 6.2 对话能力范围（8类）

| 类别 | 代码 | 说明 | 示例 |
|------|------|------|------|
| 养生问答 | `health_qa` | 通用中医养生知识问答 | "春分吃什么好？" |
| 体质解读 | `constitution_analysis` | 体质特征解读与养生建议 | "气虚体质怎么调理？" |
| 饮食建议 | `diet_advice` | 个性化食疗/食谱推荐 | "气虚体质适合喝什么茶？" |
| 运动指导 | `exercise_guide` | 运动方案与注意事项 | "适合办公室做的养生操" |
| 情绪关怀 | `emotion_care` | 情绪疏导与心理养生 | "最近工作压力大，心情不好" |
| 节气调养 | `solar_term_care` | 节气养生方案详解 | "小暑要注意什么？" |
| 穴位保健 | `acupoint_guide` | 穴位按摩指导（颐养+） | "失眠可以按什么穴位？" |
| 家庭养生 | `family_care` | 家庭成员差异化养生建议 | "我妈妈更年期怎么调养？" |

---

## 6.3 AI风格定义

| 风格 | 代码 | 语气特点 | 适用场景 |
|------|------|---------|---------|
| 温暖关怀 | `warm` | 如知心好友，善解人意，柔和体贴 | 情绪关怀、日常养生 |
| 专业严谨 | `professional` | 如中医师，用词准确，引经据典 | 体质解读、穴位指导 |
| 轻松活泼 | `friendly` | 如健康达人，简洁有趣，鼓励行动 | 运动指导、饮食建议 |

**风格切换规则：**

- 默认使用用户偏好设置中的 `ai_style`
- 情绪关怀类对话强制使用 `warm`
- 体质解读类对话默认使用 `professional`
- 用户可在对话中切换风格

---

## 6.4 消息类型（6种）

| 类型 | 代码 | 方向 | 说明 |
|------|------|------|------|
| 文本消息 | `text` | 双向 | 纯文本消息 |
| 图片消息 | `image` | 用户→AI | 用户发送图片（如舌苔、餐食） |
| 语音消息 | `voice` | 双向 | 语音转文字后处理 |
| 结构化卡片 | `card` | AI→用户 | 结构化内容（食谱、运动方案等） |
| 建议气泡 | `suggestion` | AI→用户 | 可点击的快速建议 |
| 系统消息 | `system` | 系统→用户 | 会话状态变更通知 |

### 消息数据结构

```json
{
  "id": "msg_xxx",
  "conversation_id": "conv_xxx",
  "role": "user|assistant|system",
  "type": "text|image|voice|card|suggestion|system",
  "content": {
    "text": "春分吃什么好？"
  },
  "metadata": {
    "model": "qwen-plus",
    "intent": "diet_advice",
    "tokens_used": 256,
    "response_time_ms": 1200,
    "sources": ["rag_chunfen_diet_001"]
  },
  "created_at": "2026-03-17T19:36:00+08:00"
}
```

### 结构化卡片格式

```json
{
  "type": "card",
  "content": {
    "card_type": "recipe",
    "title": "春季养肝食疗方",
    "subtitle": "适合气虚体质",
    "items": [
      { "icon": "🥬", "name": "菠菜猪肝汤", "desc": "补肝养血" },
      { "icon": "🥜", "name": "核桃黑芝麻糊", "desc": "补肾益气" }
    ],
    "action": {
      "type": "content",
      "url": "/content/recipe_spring_001"
    }
  }
}
```

---

## 6.5 会话结构设计

### 会话类型

| 类型 | 代码 | 保留时间 | 说明 |
|------|------|---------|------|
| 临时会话 | `casual` | 24h | 一次性对话，不计入长期记忆 |
| 主题会话 | `topic` | 会员记忆周期 | 围绕特定主题的持续对话 |
| 阶段会话 | `phase` | 永久 | 跨周期的阶段追踪（如孕期调养） |

### 会话元数据

```json
{
  "id": "conv_xxx",
  "user_id": 12345,
  "type": "topic",
  "title": "春分饮食调养",
  "intent": "diet_advice",
  "status": "active|archived|deleted",
  "message_count": 12,
  "last_message_at": "2026-03-17T19:36:00+08:00",
  "life_phase": {
    "id": "phase_spring_2026",
    "name": "2026春季调养",
    "start_date": "2026-02-04",
    "end_date": "2026-05-05"
  },
  "created_at": "2026-03-10T10:00:00+08:00"
}
```

---

## 6.6 多轮上下文管理

### 6.6.1 滑动窗口策略

```
┌─────────────────────────────────────────┐
│ 会话历史消息（按时间排列）               │
│                                         │
│ [msg1] [msg2] [msg3] ... [msgN] [msgN+1]│
│                                         │
│ ─────── 滑动窗口（最近K轮）──────────── │
│              [msgN-5] [msgN-4] [msgN-3] │
│              [msgN-2] [msgN-1] [msgN]   │
│              [msgN+1] ← 当前用户消息    │
└─────────────────────────────────────────┘
```

**窗口配置：**

| 会员层级 | 窗口轮数 | 最大Token数 |
|---------|---------|------------|
| 免费 | 5轮 | 2000 |
| 养心 | 10轮 | 4000 |
| 颐养 | 20轮 | 8000 |
| 家和 | 30轮 | 12000 |

### 6.6.2 摘要策略

当窗口外有大量历史消息时，AI Router 自动生成摘要：

```
条件：会话总消息数 > 窗口容量 * 2

触发：在请求AI之前
流程：
  1. 取窗口外的所有消息
  2. 调用 qwen-turbo 生成100-200字摘要
  3. 将摘要作为 System Message 注入上下文
  4. 窗口内消息保持原始内容
```

### 6.6.3 裁剪策略

```
Token预算分配：
  Total Budget = 会员最大Token
  ├─ System Prompt: 500 tokens (固定)
  ├─ 用户记忆: 200 tokens (注入)
  ├─ RAG检索结果: 500 tokens (动态)
  ├─ 摘要: 200 tokens (条件性)
  └─ 对话窗口: 剩余tokens (动态)
      └─ 从最新消息往前填充，超出部分裁剪
```

---

## 6.7 长期偏好记忆

### 记忆内容

| 类别 | 说明 | 示例 |
|------|------|------|
| 饮食偏好 | 用户提到的饮食习惯/过敏/喜好 | "不喜欢姜", "对花生过敏" |
| 生活方式 | 作息、运动习惯 | "经常加班到晚上11点" |
| 健康关注 | 反复提到的健康问题 | "长期胃不好", "容易疲劳" |
| 养生偏好 | 对某些建议的反馈 | "喜欢简单易做的食谱" |
| 家庭情况 | 提到的家庭成员信息 | "妈妈有高血压" |

### 记忆存储

```sql
-- 在 user_profiles 表中新增字段或独立表
CREATE TABLE user_ai_memories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    category VARCHAR(30) NOT NULL COMMENT 'diet/lifestyle/health/preference/family',
    content TEXT NOT NULL COMMENT '记忆内容',
    source_conversation_id VARCHAR(36) DEFAULT NULL COMMENT '来源会话',
    source_message_id VARCHAR(36) DEFAULT NULL COMMENT '来源消息',
    confidence FLOAT NOT NULL DEFAULT 0.8 COMMENT '置信度',
    mention_count INT NOT NULL DEFAULT 1 COMMENT '被提及次数',
    last_mentioned_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 记忆提取流程

```
AI对话回复后
    │
    ▼
AI Router 并行执行记忆提取：
  调用 qwen-turbo 分析对话内容
  Prompt: "从以下对话中提取用户偏好记忆，返回JSON数组"
    │
    ▼
返回格式：
  [
    {"category": "diet", "content": "不喜欢姜", "confidence": 0.9},
    {"category": "lifestyle", "content": "经常加班到晚上11点", "confidence": 0.85}
  ]
    │
    ▼
与已有记忆合并（去重 + 更新 mention_count）
    │
    ▼
写入 user_ai_memories 表
```

### 记忆注入

```
每次AI请求前：
  1. 从 user_ai_memories 读取用户所有记忆
  2. 格式化为 System Message：
     "[用户偏好记忆]
     - 饮食：不喜欢姜，对花生过敏
     - 作息：经常加班到晚上11点
     - 健康：长期胃不好
     - 家庭：妈妈有高血压"
  3. 注入到 Prompt 上下文中
```

---

## 6.8 阶段摘要记忆（LifePhase）

### 概念

LifePhase 是跨周期的长期记忆单元，记录用户在某一段时间的养生历程。

```
示例：
  LifePhase: "2026春季调养"
  时间范围：立春(2/4) → 立夏(5/5)
  摘要：
    "用户为气虚体质，春季重点调理脾胃。3月尝试了陈皮山药粥，
     反馈胃口有改善。4月因加班导致作息紊乱，建议增加午休。
     春分期间情绪波动较大，推荐了玫瑰花茶和冥想练习。"
  关键事件：
    - 3/15: 体质测试复测，结果稳定为气虚倾向阳虚
    - 3/20: 开始每日陈皮山药粥
    - 4/10: 反馈睡眠改善
```

### 数据结构

```sql
CREATE TABLE user_life_phases (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    phase_id VARCHAR(36) NOT NULL COMMENT '阶段唯一ID',
    name VARCHAR(100) NOT NULL COMMENT '阶段名称',
    start_date DATE NOT NULL,
    end_date DATE DEFAULT NULL,
    summary TEXT DEFAULT NULL COMMENT '阶段摘要',
    key_events JSON DEFAULT NULL COMMENT '关键事件列表',
    constitution_snapshot JSON DEFAULT NULL COMMENT '阶段开始时的体质快照',
    goals JSON DEFAULT NULL COMMENT '阶段目标',
    status VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active/completed/archived',
    auto_generated BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否AI自动生成',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    UNIQUE KEY uk_phase_id (phase_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 生成时机

- 每个节气结束时自动生成摘要
- 用户手动创建自定义阶段
- 阶段内每2周增量更新摘要

---

## 6.9 记忆清空

```
用户请求清空记忆
    │
    ├── 清空当前会话上下文 → 清除对话历史
    │
    ├── 清空偏好记忆 → 软删除 user_ai_memories
    │
    └── 清空所有记忆 → 会话 + 偏好 + 阶段摘要 全部清除

二次确认："清空后AI将不再记得您的偏好和养生历程，确定吗？"
```

---

## 6.10 数据表设计

### conversations 表

```sql
CREATE TABLE conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'casual' COMMENT 'casual/topic/phase',
    title VARCHAR(200) DEFAULT NULL,
    intent VARCHAR(30) DEFAULT NULL COMMENT '最后一次意图',
    status VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'active/archived/deleted',
    message_count INT NOT NULL DEFAULT 0,
    total_tokens INT NOT NULL DEFAULT 0,
    last_message_at DATETIME DEFAULT NULL,
    life_phase_id VARCHAR(36) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
    UNIQUE KEY uk_uuid (uuid),
    INDEX idx_user_id (user_id),
    INDEX idx_user_status (user_id, status),
    INDEX idx_last_message_at (last_message_at),
    INDEX idx_life_phase_id (life_phase_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### conversation_messages 表

```sql
CREATE TABLE conversation_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL COMMENT 'user/assistant/system',
    type VARCHAR(20) NOT NULL DEFAULT 'text' COMMENT 'text/image/voice/card/suggestion/system',
    content JSON NOT NULL COMMENT '消息内容(不同type结构不同)',
    metadata JSON DEFAULT NULL COMMENT '模型、意图、token等元数据',
    token_count INT DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
    UNIQUE KEY uk_uuid (uuid),
    INDEX idx_conversation_id (conversation_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6.11 API 设计

### POST /api/v1/chat/send

发送消息。

**Request:**

```json
{
  "conversation_id": "conv_uuid_xxx",  // 可选，不传则创建新会话
  "content": {
    "type": "text",
    "text": "春分吃什么好？"
  },
  "attachments": [],  // 可选，图片base64等
  "context": {
    "latitude": 30.27,
    "longitude": 120.15
  }
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "conversation_id": "conv_uuid_xxx",
    "message": {
      "uuid": "msg_uuid_xxx",
      "role": "assistant",
      "type": "card",
      "content": {
        "card_type": "recipe",
        "title": "春分时节养肝食疗",
        "text": "春分昼夜平分，重在养肝疏肝...",
        "items": [...]
      },
      "metadata": {
        "model": "qwen-plus",
        "intent": "diet_advice",
        "tokens_used": 456,
        "response_time_ms": 1800,
        "sources": ["rag_chunfen_diet_001", "rag_constitution_qixu"]
      }
    },
    "suggestions": [
      "适合气虚体质的春季食谱有哪些？",
      "春分期间什么运动最好？"
    ]
  }
}
```

### GET /api/v1/chat/conversations

获取会话列表。

**Query:** `?page=1&size=20&status=active&type=topic`

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "uuid": "conv_uuid_xxx",
        "title": "春分饮食调养",
        "type": "topic",
        "intent": "diet_advice",
        "last_message": {
          "role": "assistant",
          "content": "春分时节重在养肝...",
          "created_at": "2026-03-17T19:36:00+08:00"
        },
        "message_count": 12,
        "unread_count": 0,
        "updated_at": "2026-03-17T19:36:00+08:00"
      }
    ],
    "total": 5,
    "page": 1,
    "size": 20
  }
}
```

### GET /api/v1/chat/conversations/{conversation_id}

获取会话详情（含消息列表）。

**Query:** `?before=msg_uuid&limit=20`

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "conversation": {
      "uuid": "conv_uuid_xxx",
      "title": "春分饮食调养",
      "type": "topic",
      "status": "active",
      "message_count": 12,
      "life_phase": {
        "id": "phase_spring_2026",
        "name": "2026春季调养"
      }
    },
    "messages": [
      {
        "uuid": "msg_001",
        "role": "user",
        "type": "text",
        "content": { "text": "春分吃什么好？" },
        "created_at": "2026-03-17T19:35:00+08:00"
      },
      {
        "uuid": "msg_002",
        "role": "assistant",
        "type": "card",
        "content": { ... },
        "created_at": "2026-03-17T19:35:02+08:00"
      }
    ],
    "has_more": true,
    "next_before": "msg_002"
  }
}
```

### DELETE /api/v1/chat/conversations/{conversation_id}

删除会话。

### PUT /api/v1/chat/conversations/{conversation_id}/archive

归档会话。

### POST /api/v1/chat/conversations/{conversation_id}/title

生成/更新会话标题。

### GET /api/v1/chat/memories

获取用户AI记忆。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "memories": [
      {
        "category": "diet",
        "content": "不喜欢姜",
        "confidence": 0.9,
        "mention_count": 3,
        "last_mentioned_at": "2026-03-15T10:00:00+08:00"
      },
      {
        "category": "lifestyle",
        "content": "经常加班到晚上11点",
        "confidence": 0.85,
        "mention_count": 5
      }
    ]
  }
}
```

### DELETE /api/v1/chat/memories

清空AI记忆。

**Request:**

```json
{
  "scope": "all",  // all | preferences | context
  "confirmation": "确认清空我的AI记忆"
}
```

### GET /api/v1/chat/life-phases

获取阶段记忆列表。

### POST /api/v1/chat/stream

SSE 流式对话（用于打字机效果）。

**Request:** 同 `send`

**Response:** `text/event-stream`

```
data: {"type": "token", "text": "春"}

data: {"type": "token", "text": "分"}

data: {"type": "token", "text": "时节"}

...

data: {"type": "done", "message": {...完整消息...}}
```

---

## 6.12 隐私设计

| 措施 | 说明 |
|------|------|
| 对话加密存储 | 消息内容 AES-256 加密 |
| 记忆用户可控 | 用户可查看/删除所有记忆 |
| 数据不共享 | 对话数据不用于训练模型 |
| 会话隔离 | 不同会话间上下文隔离 |
| 记忆保留策略 | 按会员层级保留，过期自动清理 |
| 导出权 | 用户可导出所有对话记录 |
| 最小化原则 | 只存储必要的元数据 |

---

## 6.13 异常处理

| 场景 | 处理 |
|------|------|
| AI模型超时 | 返回友好提示"思考中，请稍候"，自动重试1次 |
| AI模型不可用 | 降级到备用模型(qwen-turbo)或返回预设回复 |
| Token超限 | 自动裁剪上下文后重试 |
| 安全拦截 | 返回安全提示，不返回原始请求内容 |
| 图片识别失败 | 返回"图片解析失败，请换一张试试" |
| 对话次数超限 | 返回升级会员引导 |

---

## 6.14 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| ai-router | 强依赖 | 对话请求经Router路由 |
| user | 依赖 | 用户认证+记忆关联 |
| membership | 依赖 | 对话次数限制、模型选择、记忆周期 |
| constitution | 依赖 | 体质信息注入上下文 |
| solar-term | 依赖 | 节气信息注入上下文 |
| rag | 弱依赖 | RAG检索结果注入 |
| dashboard | 被依赖 | 首页AI入口 |
| analytics | 依赖 | 对话事件上报 |

---

# 第七章 AI Router系统

## 7.1 概述

AI Router 是顺时 ShunShi AI能力的核心调度引擎，负责意图分类、安全拦截、模型选择、Prompt管理、RAG集成和响应校验。系统采用模块化设计，每个环节独立可配置，支持灰度发布和A/B测试。

---

## 7.2 Prompt Registry

### 7.2.1 Prompt 分类

| 类别 | 代码 | 说明 | 数量 |
|------|------|------|------|
| Core Prompt | `core` | 系统角色、基础行为准则 | 5 |
| Policy Prompt | `policy` | 安全策略、边界规则 | 8 |
| Task Prompt | `task` | 具体任务模板（按意图） | 20+ |

### 7.2.2 Core Prompt 示例

```yaml
id: core_system_v1
name: 顺时AI系统角色
category: core
version: 1.0.0
content: |
  你是"顺时"AI养生助手，一位精通中医养生知识的智慧伙伴。
  
  ## 角色定位
  - 你不是医生，不提供医疗诊断和处方
  - 你是一位养生顾问，提供生活方式引导
  - 你温和专业，如朋友般关怀用户
  
  ## 行为准则
  - 回答基于中医理论和节气养生智慧
  - 结合用户体质提供个性化建议
  - 引用知识来源时标注出处
  - 遇到医疗问题主动引导就医
  - 使用通俗易懂的语言解释专业概念
  
  ## 禁止行为
  - 不推荐具体药物和剂量
  - 不替代医生诊断
  - 不处理紧急医疗情况
  - 不提供心理治疗（仅情志养生指导）
```

### 7.2.3 Policy Prompt 示例

```yaml
id: policy_safety_v1
name: 安全策略
category: policy
version: 1.0.0
content: |
  ## 医疗安全
  - 当用户描述以下症状时，立即停止养生建议，引导就医：
    - 剧烈疼痛（胸痛、腹痛等）
    - 持续高烧不退
    - 突发性功能障碍
    - 意识模糊或丧失
    - 大量出血
    - 严重过敏反应
  
  ## 用药安全
  - 不回答关于具体药物剂量的问题
  - 不评价西药疗效
  - 中药问题建议咨询中医师
  
  ## 情绪安全
  - 检测极端情绪时启动SafeMode
  - 不提供心理治疗
  - 推荐专业心理咨询渠道
```

### 7.2.4 Task Prompt 示例

```yaml
id: task_diet_advice_v1
name: 饮食建议
category: task
version: 1.0.0
intent: diet_advice
content: |
  根据用户的体质类型和当前节气，提供个性化的饮食建议。
  
  ## 输入
  - 用户体质：{constitution_type}
  - 当前节气：{solar_term}
  - 用户饮食偏好：{diet_preferences}
  - 用户健康关注：{health_concerns}
  
  ## 输出格式
  使用结构化卡片格式，包含：
  1. 养生原理（1-2句话）
  2. 推荐食材（3-5种，标注功效）
  3. 推荐食谱（1-2个，简单易做）
  4. 避忌食物（如有）
  
  ## 知识来源
  {rag_results}
```

---

## 7.3 Prompt 版本管理

### 版本规则

- 格式：`{name}_v{major}.{minor}.{patch}`
- Major：不兼容变更
- Minor：功能增加
- Patch：文案微调

### 灰度发布

```json
{
  "prompt_id": "core_system",
  "versions": [
    {
      "version": "2.0.0",
      "status": "active",
      "traffic_percent": 10,
      "description": "新增情志养生模块",
      "created_at": "2026-03-15"
    },
    {
      "version": "1.2.0",
      "status": "active",
      "traffic_percent": 90,
      "description": "当前稳定版"
    }
  ]
}
```

### 回滚机制

```
1. 监控指标异常（满意度下降/安全拦截率升高）
    │
    ▼
2. 自动告警（阈值：5分钟内连续异常）
    │
    ▼
3. 一键回滚到上一版本
    │
    ▼
4. 验证回滚效果（指标恢复）
```

---

## 7.4 Model Router

### 7.4.1 模型配置

| 模型 | 代码 | 提供方 | 用途 | 延迟目标 | Token单价 |
|------|------|--------|------|---------|-----------|
| qwen-plus | `qwen-plus` | 通义千问 | 主力对话模型 | <3s | ¥0.008/千token |
| qwen-turbo | `qwen-turbo` | 通义千问 | 轻量/摘要/记忆提取 | <1.5s | ¥0.003/千token |
| ernie-bot | `ernie-bot` | 文心一言 | 情绪识别/情绪关怀 | <2s | ¥0.012/千token |

### 7.4.2 路由策略

```
用户消息 → Intent Classifier
    │
    ├── health_qa → qwen-plus (主力)
    ├── constitution_analysis → qwen-plus (主力)
    ├── diet_advice → qwen-plus (主力) + RAG
    ├── exercise_guide → qwen-plus (主力)
    ├── emotion_care → ernie-bot (情绪模型)  ← 情绪意图路由到文心
    ├── solar_term_care → qwen-plus + RAG
    ├── acupoint_guide → qwen-plus (颐养+)
    ├── family_care → qwen-plus (家和)
    └── unknown/fallback → qwen-turbo (降级)

会员层级路由：
  - 免费 → qwen-turbo
  - 养心+ → qwen-plus（情绪关怀仍走 ernie-bot）
  
降级路由：
  qwen-plus 不可用 → qwen-turbo
  ernie-bot 不可用 → qwen-plus
  全部不可用 → 返回预设回复
```

---

## 7.5 Intent Classifier（意图分类）

### 7.5.1 意图定义（9类）

| 意图 | 代码 | 关键词/模式 | 优先级 |
|------|------|------------|--------|
| 养生问答 | `health_qa` | 怎么/什么/为什么+养生相关 | 1 |
| 体质解读 | `constitution_analysis` | 体质+特征/调理/表现 | 2 |
| 饮食建议 | `diet_advice` | 吃什么/食谱/茶饮/食疗 | 3 |
| 运动指导 | `exercise_guide` | 运动/锻炼/操/瑜伽/太极 | 4 |
| 情绪关怀 | `emotion_care` | 压力/焦虑/失眠/心情/情绪 | 5 |
| 节气调养 | `solar_term_care` | 节气名+调养/注意/方案 | 6 |
| 穴位保健 | `acupoint_guide` | 穴位/按摩/推拿/经络 | 7 |
| 家庭养生 | `family_care` | 妈妈/爸爸/孩子/家人+养生 | 8 |
| 闲聊/未知 | `chatter` | 其他无法分类的对话 | 9 |

### 7.5.2 分类策略

```
输入：用户消息文本
    │
    ▼
规则层（快速分类，<10ms）：
  - 关键词匹配（正则）
  - 节气名检测（24节气词表）
  - 穴位名检测（361个标准穴位）
    │
    ├── 命中 → 直接返回意图
    │
    └── 未命中 ▼
    
模型层（精确分类，<200ms）：
  - 调用 qwen-turbo 做零样本分类
  - 输入：消息 + 意图定义列表
  - 输出：意图 + 置信度
    │
    ▼
置信度 > 0.7 → 使用模型分类结果
置信度 ≤ 0.7 → 降级为 health_qa
```

---

## 7.6 Safety Guard（安全拦截）

### 7.6.1 拦截层级（5层）

```
Layer 1: 医疗紧急拦截（最高优先级）
  规则：关键词匹配 + AI检测
  触发词：剧烈疼痛/呼吸困难/意识丧失/大出血/自杀倾向
  动作：立即拦截，返回就医/急救引导
  日志：标记为紧急安全事件

Layer 2: 用药拦截
  规则：药物名检测（含常见中药名/西药名）
  触发：用户询问药物剂量、药物评价、替代药物
  动作：拦截具体用药建议，引导咨询医师
  日志：标记为用药安全事件

Layer 3: 体检/诊断拦截
  规则：检测诊断类表述
  触发：用户要求诊断/判断是否患病
  动作：明确告知不做诊断，建议就医
  日志：标记为诊断拦截

Layer 4: 极端情绪检测
  规则：AI情绪分析（调用 ernie-bot 情绪API）
  触发：检测到严重负面情绪（抑郁/焦虑/绝望）
  动作：切换到 SafeMode（温暖关怀模式）
  SafeMode 行为：
    - 切换到 warm 风格
    - 限制在情志养生范围
    - 推荐心理咨询渠道
    - 连续3次触发则强制推荐心理热线
  日志：标记为情绪安全事件

Layer 5: 通用安全
  规则：敏感词过滤 + 有害内容检测
  触发：色情/暴力/政治/违法
  动作：返回"这个问题我无法回答"
  日志：标记为通用安全事件
```

### 7.6.2 SafeMode 状态机

```
Normal Mode
    │ 检测到极端情绪
    ▼
SafeMode Level 1（当次对话启用温暖模式）
    │ 连续2次触发
    ▼
SafeMode Level 2（该会话持续温暖模式 + 添加心理咨询提示）
    │ 连续3次触发
    ▼
SafeMode Level 3（强制推荐心理热线 + 限制非养生对话）
    │ 24小时无触发 + 用户情绪好转
    ▼
恢复 Normal Mode
```

---

## 7.7 Schema Validator（JSON Schema 校验）

### 7.7.1 Schema 定义

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AIResponse",
  "type": "object",
  "required": ["type", "content"],
  "properties": {
    "type": {
      "type": "string",
      "enum": ["text", "card", "recipe", "exercise_plan", "acupoint_guide"]
    },
    "content": {
      "type": "object",
      "properties": {
        "text": { "type": "string", "maxLength": 2000 },
        "items": {
          "type": "array",
          "maxItems": 10,
          "items": {
            "type": "object",
            "required": ["name", "description"],
            "properties": {
              "name": { "type": "string", "maxLength": 50 },
              "description": { "type": "string", "maxLength": 200 }
            }
          }
        }
      }
    },
    "suggestions": {
      "type": "array",
      "maxItems": 5,
      "items": { "type": "string", "maxLength": 100 }
    }
  }
}
```

### 7.7.2 校验+修复+降级流程

```
AI模型返回响应
    │
    ▼
Schema Validator 校验
    │
    ├── 通过 → 正常返回
    │
    ├── 格式异常（可修复）→
    │   1. 尝试AI自动修复（qwen-turbo + 修复Prompt）
    │   2. 修复成功 → 返回修复后结果
    │   3. 修复失败 → 降级处理
    │
    └── 格式异常（不可修复）→
        降级处理：
        1. 提取 text 字段作为纯文本返回
        2. 丢失结构化信息但保证可读性
        3. 记录校验失败日志
```

---

## 7.8 RAG检索集成

```
AI Router 内部 RAG 调用流程：

1. 意图分类完成后
    │
    ├── diet_advice, solar_term_care, health_qa → 需要 RAG
    │   其他意图 → 可选 RAG
    │
    ▼
2. 构建 RAG Query
   - 用户原始消息
   - 意图类型
   - 用户体质
   - 当前节气
    │
    ▼
3. 调用 RAG Service
   POST /internal/rag/search
   Body: {
     "query": "春分气虚吃什么好",
     "intent": "diet_advice",
     "filters": {
       "constitution": "qi_xu",
       "solar_term": "chunfen",
       "content_type": "diet"
     },
     "top_k": 5
   }
    │
    ▼
4. 获取 RAG 结果
   [
     {
       "content": "气虚体质春季宜食山药、大枣...",
       "source": "constitution_qi_xu_diet",
       "relevance_score": 0.92
     },
     ...
   ]
    │
    ▼
5. 注入 Prompt
   在 Task Prompt 的 {rag_results} 占位符处插入检索结果
```

---

## 7.9 Token统计与成本控制

### Token 统计维度

| 维度 | 说明 |
|------|------|
| per_request | 每次请求的 input/output token |
| per_conversation | 会话累计 token |
| per_user_daily | 用户每日累计 token |
| per_user_monthly | 用户每月累计 token |
| per_intent | 按意图分类的 token 消耗 |
| per_model | 按模型的 token 消耗和成本 |

### 成本控制策略

| 策略 | 说明 |
|------|------|
| 免费用户限额 | 每日 3 次对话，每次 2000 token 上限 |
| 滑动窗口裁剪 | 按会员层级控制上下文长度 |
| 缓存命中 | 相似问题命中缓存直接返回 |
| 小模型降级 | 摘要/分类使用 qwen-turbo |
| 预算告警 | 每日/月累计超过阈值告警 |

### Redis Token 统计

```
Key: token:usage:{user_id}:{date}
Value: JSON {
  "total_input": 15000,
  "total_output": 5000,
  "request_count": 12,
  "by_model": {
    "qwen-plus": {"input": 12000, "output": 4000},
    "qwen-turbo": {"input": 3000, "output": 1000}
  },
  "cost_cents": 160
}
TTL: 48h
```

---

## 7.10 灰度发布

### 灰度策略

| 策略 | 维度 | 说明 |
|------|------|------|
| 按用户百分比 | user_id % 100 | 如前10%使用新版本 |
| 按会员层级 | membership_level | 如颐养用户先灰度 |
| 按意图 | intent_type | 如只对饮食建议灰度 |
| 按白名单 | user_uuid | 指定用户测试 |

### 发布流程

```
1. 创建新版本 Prompt/Model 配置
    │
    ▼
2. 设置灰度规则（如 5% 流量）
    │
    ▼
3. 观察指标（15-30分钟）
   - 满意度/点赞率
   - 安全拦截率
   - 平均响应时间
   - Token消耗变化
    │
    ├── 指标正常 → 逐步扩大灰度（10% → 30% → 50% → 100%）
    │
    └── 指标异常 → 一键回滚
```

---

## 7.11 路由流程图（完整）

```
用户发送消息
    │
    ▼
[1] 接收 & 预处理
    - 消息清洗（去除多余空格/特殊字符）
    - 提取上下文（用户体质/节气/历史摘要）
    │
    ▼
[2] Intent Classifier
    - 规则层（关键词匹配）
    - 模型层（qwen-turbo 分类）
    - 输出：intent + confidence
    │
    ▼
[3] Safety Guard
    - Layer 1: 医疗紧急拦截
    - Layer 2: 用药拦截
    - Layer 3: 诊断拦截
    - Layer 4: 情绪检测 → 可能进入 SafeMode
    - Layer 5: 通用安全
    │
    ├── 拦截 → 返回安全响应 → 结束
    │
    └── 通过 ▼
    
[4] Model Router
    - 根据意图选择模型
    - 根据会员层级降级/升级
    - 检查模型可用性
    │
    ▼
[5] RAG 检索（按意图条件触发）
    - 构建 query
    - 调用 RAG Service
    - 获取 top-k 结果
    │
    ▼
[6] Prompt 组装
    - Core Prompt (System)
    - Policy Prompt (System)
    - Task Prompt (System)
    - RAG 结果 (System)
    - 用户记忆 (System)
    - 历史摘要 (System)
    - 对话历史 (User/Assistant)
    - 当前用户消息 (User)
    │
    ▼
[7] 调用 AI 模型
    - 发送到选定模型API
    - 等待响应（超时 30s）
    │
    ▼
[8] Schema Validator
    - 校验响应格式
    - 可修复 → AI修复
    - 不可修复 → 降级为纯文本
    │
    ▼
[9] 记忆提取（异步并行）
    - 分析对话提取偏好
    - 更新 user_ai_memories
    │
    ▼
[10] 响应返回
    - 格式化为 API Response
    - 生成建议气泡
    - 更新 Token 统计
    - 记录日志
    │
    ▼
客户端接收并渲染
```

---

## 7.12 日志字段设计

### AI Request Log

```json
{
  "request_id": "req_uuid",
  "timestamp": "2026-03-17T19:36:00.000Z",
  "user_id": 12345,
  "user_uuid": "user-uuid",
  "conversation_id": "conv-uuid",
  "membership_level": "yangxin",
  "message": "春分气虚体质吃什么好？",
  "context": {
    "constitution_type": "qi_xu",
    "solar_term": "chunfen",
    "life_stage": "career",
    "message_count": 5
  },
  "routing": {
    "intent": "diet_advice",
    "intent_confidence": 0.92,
    "model": "qwen-plus",
    "model_reason": "intent_routing"
  },
  "safety": {
    "checks": [
      {"layer": 1, "passed": true},
      {"layer": 2, "passed": true},
      {"layer": 3, "passed": true},
      {"layer": 4, "passed": true, "emotion_score": 0.3},
      {"layer": 5, "passed": true}
    ],
    "safe_mode": false
  },
  "rag": {
    "triggered": true,
    "query": "春分气虚体质饮食建议",
    "top_k": 5,
    "results_count": 5,
    "top_score": 0.92
  },
  "prompt": {
    "core_version": "1.2.0",
    "task_version": "task_diet_advice_v1",
    "total_tokens_input": 3200
  },
  "response": {
    "model": "qwen-plus",
    "tokens_input": 3200,
    "tokens_output": 800,
    "total_tokens": 4000,
    "response_time_ms": 1800,
    "schema_valid": true,
    "schema_repaired": false
  },
  "cost": {
    "model_cost_cents": 32,
    "rag_cost_cents": 2,
    "total_cost_cents": 34
  }
}
```

---

## 7.13 API 设计（内部/管理）

### GET /internal/ai-router/config

获取Router当前配置（管理用）。

### PUT /internal/ai-router/config

更新Router配置（灰度/模型/阈值等）。

### POST /internal/ai-router/rollback

回滚到上一版本。

### GET /internal/ai-router/metrics

获取Router运行指标。

**Response:**

```json
{
  "period": "2026-03-17",
  "total_requests": 15000,
  "avg_response_time_ms": 1500,
  "p99_response_time_ms": 3500,
  "intent_distribution": {
    "health_qa": 3000,
    "diet_advice": 2500,
    "emotion_care": 2000,
    "constitution_analysis": 1500,
    "solar_term_care": 1800,
    "exercise_guide": 1200,
    "chatter": 2500,
    "acupoint_guide": 300,
    "family_care": 200
  },
  "safety_interceptions": {
    "medical": 5,
    "medication": 12,
    "diagnosis": 8,
    "emotion": 25,
    "general": 3
  },
  "model_usage": {
    "qwen-plus": {"requests": 12000, "total_tokens": 48000000},
    "qwen-turbo": {"requests": 2500, "total_tokens": 5000000},
    "ernie-bot": {"requests": 500, "total_tokens": 2000000}
  },
  "total_cost_cents": 5800,
  "schema_validation": {
    "pass_rate": 0.98,
    "repair_rate": 0.015,
    "fallback_rate": 0.005
  }
}
```

### POST /internal/ai-router/test

测试路由（不记录日志，用于调试）。

**Request:**

```json
{
  "message": "春分吃什么好？",
  "context": {
    "constitution_type": "qi_xu",
    "solar_term": "chunfen",
    "membership_level": "yangxin"
  },
  "options": {
    "model_override": "qwen-plus",
    "skip_rag": false,
    "debug": true
  }
}
```

---

## 7.14 异常处理

| 场景 | 处理 |
|------|------|
| 意图分类模型不可用 | 降级为 `health_qa`，记录日志 |
| 主力模型超时 | 重试1次，仍超时则降级到 qwen-turbo |
| 全部模型不可用 | 返回预设回复："我暂时无法思考，请稍后再试" |
| RAG服务不可用 | 跳过RAG，使用纯Prompt |
| Schema校验持续失败 | 触发告警，自动降级为纯文本模式 |
| SafeMode误触发 | 用户可点击"反馈"纠正，系统学习 |

---

## 7.15 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| ai-chat | 被依赖 | 对话请求经过Router处理 |
| user | 依赖 | 获取用户信息、会员层级 |
| rag | 依赖 | RAG检索注入Prompt |
| constitution | 依赖 | 体质信息注入Prompt |
| solar-term | 依赖 | 节气信息注入Prompt |
| membership | 依赖 | 权益控制模型选择 |
| analytics | 依赖 | Router日志上报 |
| config | 依赖 | 灰度/AB配置 |

---

# 第八章 内容库系统

## 8.1 概述

内容库系统是顺时 ShunShi 的养生知识内容管理平台，承载8大类养生内容的存储、检索、推荐和分发。系统支持富媒体内容（图文/视频/音频），通过CMS后台运营管理，配合OSS媒体存储和CDN分发，为用户提供高质量的内容体验。

---

## 8.2 内容分类体系（8大类）

| 分类 | 代码 | icon | 说明 | 子分类 |
|------|------|------|------|--------|
| 饮食养生 | `diet` | 🍵 | 食疗、药膳、茶饮 | 食疗方、药膳、茶饮、饮食禁忌、节气食俗 |
| 运动养生 | `exercise` | 🧘 | 运动、功法、导引 | 传统功法、日常运动、办公室养生操、儿童运动 |
| 情志养生 | `emotion` | 🌸 | 情绪管理、心理养生 | 情志调养、冥想、减压、睡眠改善 |
| 穴位保健 | `acupoint` | 👆 | 穴位按摩、经络养生 | 常用穴位、经络保健、足疗、耳穴 |
| 节气养生 | `solar_term` | 🌿 | 二十四节气调养 | 按节气分类 |
| 体质养生 | `constitution` | ⚖️ | 九种体质调养方案 | 按体质分类 |
| 居家养生 | `home` | 🏠 | 居家环境、作息调养 | 作息规律、居室环境、四时调养 |
| 亲子养生 | `parenting` | 👶 | 儿童/母婴养生 | 儿童体质、母婴调养、青少年发育 |

---

## 8.3 内容字段模型

### content_items 表

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| uuid | VARCHAR(36) | Y | UNIQUE | 内容UUID |
| title | VARCHAR(200) | Y | INDEX | 标题 |
| subtitle | VARCHAR(300) | N | - | 副标题 |
| summary | TEXT | N | - | 摘要（200字以内） |
| content_body | LONGTEXT | Y | - | 正文（Markdown格式） |
| category | VARCHAR(30) | Y | INDEX | 一级分类 |
| sub_category | VARCHAR(30) | N | INDEX | 二级分类 |
| tags | JSON | N | - | 标签列表 ["春季","养肝","气虚"] |
| cover_image | VARCHAR(512) | N | - | 封面图OSS URL |
| required_level | VARCHAR(20) | Y | INDEX | 最低会员层级：free/yangxin/yiyang |
| related_constitution | JSON | N | - | 关联体质 ["qi_xu","yang_xu"] |
| related_solar_term | JSON | N | - | 关联节气 ["chunfen","qingming"] |
| related_life_stage | JSON | N | - | 关联生命阶段 ["career","parenting"] |
| author | VARCHAR(50) | N | - | 作者/来源 |
| source | VARCHAR(200) | N | - | 来源链接 |
| read_time_min | INT | N | - | 预计阅读时间（分钟） |
| view_count | INT | Y | - | 浏览量，默认0 |
| like_count | INT | Y | - | 点赞数，默认0 |
| collect_count | INT | Y | - | 收藏数，默认0 |
| share_count | INT | Y | - | 分享数，默认0 |
| comment_count | INT | Y | - | 评论数，默认0 |
| sort_weight | INT | Y | - | 排序权重，默认0，越大越靠前 |
| status | VARCHAR(20) | Y | INDEX | draft/published/archived/hidden |
| published_at | DATETIME | N | INDEX | 发布时间 |
| created_at | DATETIME | Y | - | 创建时间 |
| updated_at | DATETIME | Y | - | 更新时间 |

### content_tags 表

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| tag_name | VARCHAR(50) | Y | UNIQUE | 标签名 |
| tag_name_en | VARCHAR(50) | N | - | 英文名 |
| category | VARCHAR(30) | N | INDEX | 所属分类 |
| usage_count | INT | Y | - | 使用次数，默认0 |
| created_at | DATETIME | Y | - | 创建时间 |

### content_media 表

| 字段名 | 类型 | 必填 | 索引 | 说明 |
|--------|------|------|------|------|
| id | BIGINT | Y | PK | 自增主键 |
| content_id | BIGINT | Y | INDEX | 关联content_items.id |
| media_type | VARCHAR(20) | Y | INDEX | image/video/audio |
| url | VARCHAR(512) | Y | - | OSS URL |
| thumbnail_url | VARCHAR(512) | N | - | 缩略图OSS URL |
| width | INT | N | - | 宽度（图片/视频） |
| height | INT | N | - | 高度（图片/视频） |
| duration_sec | INT | N | - | 时长（视频/音频） |
| file_size_bytes | BIGINT | N | - | 文件大小 |
| mime_type | VARCHAR(50) | N | - | MIME类型 |
| sort_order | INT | Y | - | 排序，默认0 |
| created_at | DATETIME | Y | - | 上传时间 |

### DDL

```sql
CREATE TABLE content_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,
    title VARCHAR(200) NOT NULL,
    subtitle VARCHAR(300) DEFAULT NULL,
    summary TEXT DEFAULT NULL,
    content_body LONGTEXT NOT NULL,
    category VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) DEFAULT NULL,
    tags JSON DEFAULT NULL,
    cover_image VARCHAR(512) DEFAULT NULL,
    required_level VARCHAR(20) NOT NULL DEFAULT 'free',
    related_constitution JSON DEFAULT NULL,
    related_solar_term JSON DEFAULT NULL,
    related_life_stage JSON DEFAULT NULL,
    author VARCHAR(50) DEFAULT NULL,
    source VARCHAR(200) DEFAULT NULL,
    read_time_min INT DEFAULT NULL,
    view_count INT NOT NULL DEFAULT 0,
    like_count INT NOT NULL DEFAULT 0,
    collect_count INT NOT NULL DEFAULT 0,
    share_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    sort_weight INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    published_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_uuid (uuid),
    INDEX idx_category (category),
    INDEX idx_sub_category (sub_category),
    INDEX idx_required_level (required_level),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at),
    INDEX idx_sort_weight (sort_weight),
    FULLTEXT INDEX ft_title_summary (title, summary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE content_tags (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL,
    tag_name_en VARCHAR(50) DEFAULT NULL,
    category VARCHAR(30) DEFAULT NULL,
    usage_count INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_tag_name (tag_name),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE content_media (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    content_id BIGINT NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    url VARCHAR(512) NOT NULL,
    thumbnail_url VARCHAR(512) DEFAULT NULL,
    width INT DEFAULT NULL,
    height INT DEFAULT NULL,
    duration_sec INT DEFAULT NULL,
    file_size_bytes BIGINT DEFAULT NULL,
    mime_type VARCHAR(50) DEFAULT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_content_id (content_id),
    INDEX idx_media_type (media_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 8.4 内容列表API

### GET /api/v1/content/list

**Query参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | N | 一级分类筛选 |
| sub_category | string | N | 二级分类筛选 |
| tags | string | N | 标签筛选（逗号分隔） |
| constitution | string | N | 体质筛选 |
| solar_term | string | N | 节气筛选 |
| page | int | N | 页码，默认1 |
| size | int | N | 每页数量，默认20，最大50 |
| sort | string | N | 排序：latest/popular/recommended |
| search | string | N | 搜索关键词 |

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "items": [
      {
        "uuid": "content_uuid_001",
        "title": "春分养肝食疗方",
        "subtitle": "适合气虚体质的春季食谱",
        "summary": "春分时节肝气旺盛，气虚体质宜食...",
        "cover_image": "https://cdn.../diet_chunfen_001.jpg",
        "category": "diet",
        "sub_category": "食疗方",
        "tags": ["春分", "养肝", "气虚", "食疗"],
        "read_time_min": 5,
        "view_count": 1250,
        "like_count": 89,
        "required_level": "free",
        "published_at": "2026-03-10T08:00:00+08:00"
      }
    ],
    "total": 156,
    "page": 1,
    "size": 20,
    "has_more": true
  }
}
```

---

## 8.5 内容详情API

### GET /api/v1/content/{content_uuid}

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "uuid": "content_uuid_001",
    "title": "春分养肝食疗方",
    "subtitle": "适合气虚体质的春季食谱",
    "summary": "春分时节肝气旺盛，气虚体质宜食...",
    "content_body": "# 春分养肝食疗方\n\n春分时节...",
    "category": "diet",
    "sub_category": "食疗方",
    "tags": ["春分", "养肝", "气虚", "食疗"],
    "cover_image": "https://cdn.../diet_chunfen_001.jpg",
    "media": [
      {
        "type": "image",
        "url": "https://cdn.../diet_chunfen_001_01.jpg",
        "width": 800,
        "height": 600
      }
    ],
    "author": "顺时养生编辑部",
    "source": "《黄帝内经》春季养生篇",
    "read_time_min": 5,
    "view_count": 1251,
    "like_count": 89,
    "collect_count": 34,
    "share_count": 12,
    "required_level": "free",
    "related_constitution": ["qi_xu", "yang_xu"],
    "related_solar_term": ["chunfen"],
    "published_at": "2026-03-10T08:00:00+08:00",
    "user_interaction": {
      "liked": false,
      "collected": false,
      "shared": false
    },
    "related_content": [
      {
        "uuid": "content_uuid_002",
        "title": "春季养肝茶饮推荐",
        "cover_image": "..."
      },
      {
        "uuid": "content_uuid_003",
        "title": "气虚体质全面调理指南",
        "cover_image": "..."
      }
    ]
  }
}
```

---

## 8.6 搜索API

### GET /api/v1/content/search

**Query参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| q | string | 搜索关键词 |
| category | string | 分类过滤 |
| tags | string | 标签过滤（逗号分隔） |
| page | int | 页码 |
| size | int | 每页数量 |

**搜索策略：**

1. **全文搜索：** 使用 MySQL FULLTEXT INDEX 搜索 title + summary
2. **标签匹配：** 精确匹配 tags JSON 字段
3. **分类过滤：** category + sub_category
4. **排序：** 相关度优先（全文搜索匹配度）+ 热度加权

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "items": [...],
    "total": 23,
    "page": 1,
    "size": 20,
    "suggestions": ["春季养肝", "养肝茶", "气虚调理"]
  }
}
```

---

## 8.7 推荐位设计

| 推荐位 | 代码 | 位置 | 更新频率 | 数量 |
|--------|------|------|---------|------|
| 首页推荐 | `home_featured` | 首页推荐内容区 | 每日 | 3-5 |
| 节气精选 | `solar_featured` | 节气专区 | 每节气 | 5-10 |
| 体质推荐 | `constitution_rec` | 体质详情页 | 每周 | 5 |
| 热门内容 | `trending` | 发现页 | 实时 | 10 |
| 新上线 | `new_content` | 发现页 | 实时 | 10 |

**推荐逻辑：**

```
1. 基于规则的推荐（主要）：
   - 节气匹配：当前节气相关内容加权
   - 体质匹配：用户体质相关内容加权
   - 生命周期匹配：用户life_stage相关内容加权
   - 热度加权：view_count * 0.3 + like_count * 0.5 + share_count * 0.2

2. 新颖度加权：
   - 7天内发布的内容 +20%
   - 30天内发布的内容 +10%

3. 去重：
   - 用户已浏览内容降权
   - 同一分类不连续出现
```

---

## 8.8 CMS后台预留

### 功能规划

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 内容编辑器 | Markdown编辑器 + 预览 | P0 |
| 媒体管理 | 上传/裁剪/压缩/管理 | P0 |
| 分类管理 | 分类CRUD | P0 |
| 标签管理 | 标签CRUD | P0 |
| 内容审核 | 发布/退回/归档流程 | P1 |
| 推荐位管理 | 配置推荐位内容 | P1 |
| 数据看板 | 浏览量/点赞/收藏统计 | P1 |
| 用户反馈 | 内容反馈查看 | P2 |
| 定时发布 | 预约发布时间 | P2 |
| 内容导入 | Excel/CSV批量导入 | P2 |

### CMS API

```
POST   /api/v1/admin/content          # 创建内容
PUT    /api/v1/admin/content/{id}      # 更新内容
DELETE /api/v1/admin/content/{id}      # 删除内容
POST   /api/v1/admin/content/{id}/publish   # 发布
POST   /api/v1/admin/content/{id}/archive   # 归档
POST   /api/v1/admin/media/upload      # 上传媒体
```

---

## 8.9 OSS媒体存储

### 存储结构

```
shunshi-media/
├── content/
│   ├── images/
│   │   └── {uuid}/{filename}.jpg
│   ├── videos/
│   │   └── {uuid}/{filename}.mp4
│   └── audio/
│       └── {uuid}/{filename}.mp3
├── avatar/
│   └── {user_uuid}/avatar.jpg
├── constitution/
│   └── {type}/{filename}.png
├── solar-term/
│   └── {term_name}/{filename}.jpg
└── system/
    └── icons/defaults/
```

### 图片处理

| 操作 | 规格 | 说明 |
|------|------|------|
| 原图上传 | 不限制 | 保留原图 |
| 封面图 | 800x600 | 自动裁剪/缩放 |
| 缩略图 | 200x150 | 列表页展示 |
| WebP格式 | 自适应 | 支持 WebP 的客户端返回 WebP |
| 质量压缩 | 85% | 平衡质量与大小 |

### 视频处理

| 规格 | 说明 |
|------|------|
| 封面帧 | 自动提取第1秒作为封面 |
| 分辨率 | 1080p / 720p / 480p 多清晰度 |
| 格式 | MP4 (H.264) |
| 时长限制 | 单视频最长5分钟 |

---

## 8.10 CDN分发

### CDN配置

- 域名：`cdn.shunshi.app`
- 源站：OSS Bucket
- 回源协议：HTTPS
- 缓存策略：
  - 图片：30天
  - 视频：7天
  - 音频：30天
  - 其他：1天

### CDN预热

- 新发布内容 → 自动触发CDN预热
- 节气切换 → 提前预热下节气内容
- 热门内容 → 命中阈值自动预热

---

## 8.11 媒体降级策略

```
用户请求内容 → 检查网络状况
    │
    ├── WiFi/5G → 加载视频 + 高清图
    │
    ├── 4G → 加载封面图 + 文字（视频显示播放按钮，点击后加载）
    │
    └── 3G/弱网 → 仅加载文字 + 缩略图
        视频替换为封面图
        多图替换为首图
```

**实现：**

```dart
// Flutter 端示例
MediaQuality getMediaQuality(ConnectivityResult connectivity) {
  switch (connectivity) {
    case ConnectivityResult.wifi:
      return MediaQuality.high;  // 视频+高清图
    case ConnectivityResult.mobile:
      return MediaQuality.medium;  // 封面图+文字
    case ConnectivityResult.none:
      return MediaQuality.low;  // 仅文字
    default:
      return MediaQuality.medium;
  }
}
```

---

## 8.12 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| dashboard | 被依赖 | 首页推荐内容 |
| ai-chat | 弱依赖 | AI对话可能引用内容 |
| constitution | 关联 | 体质相关内容推荐 |
| solar-term | 关联 | 节气相关内容推荐 |
| membership | 依赖 | 内容访问权限控制 |
| rag | 弱依赖 | 内容是RAG知识源之一 |
| analytics | 依赖 | 内容浏览事件上报 |

---

# 第九章 知识库/RAG系统

## 9.1 概述

RAG（Retrieval-Augmented Generation）知识库系统为AI对话提供专业知识支撑，通过将中医养生知识向量化存储，实现语义检索和知识增强生成。系统涵盖6类知识源，支持按主题、节气、体质三个维度进行知识切片和检索。

---

## 9.2 RAG架构图

```
┌─────────────────────────────────────────────────────────┐
│                     知识写入流程                          │
│                                                         │
│  知识源                                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌─────┐│
│  │中医典│ │体质学│ │节气养│ │内容库│ │专业医│ │用户 ││
│  │籍文献│ │说文献│ │生方案│ │精选文│ │学文献│ │反馈 ││
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬──┘│
│     └────────┴────────┴────────┴────────┴────────┘     │
│                        │                                │
│                        ▼                                │
│              ┌──────────────────┐                       │
│              │   知识切片引擎    │                       │
│              │  (Chunking)      │                       │
│              │  - 主题维度       │                       │
│              │  - 节气维度       │                       │
│              │  - 体质维度       │                       │
│              └────────┬─────────┘                       │
│                       │                                 │
│                       ▼                                 │
│              ┌──────────────────┐                       │
│              │   Embedding 引擎  │                       │
│              │  (qwen-embedding)│                       │
│              │  768维向量        │                       │
│              └────────┬─────────┘                       │
│                       │                                 │
│                       ▼                                 │
│              ┌──────────────────┐                       │
│              │  Milvus 向量存储  │                       │
│              │  Collection:     │                       │
│              │  shunshi_knowledge│                      │
│              └──────────────────┘                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     知识检索流程                          │
│                                                         │
│  用户问题                                               │
│       │                                                 │
│       ▼                                                 │
│  ┌──────────────────┐                                  │
│  │  Query 预处理     │                                  │
│  │  - 关键词提取      │                                  │
│  │  - 意图关联        │                                  │
│  │  - 用户上下文注入   │                                  │
│  └────────┬─────────┘                                  │
│           │                                             │
│           ▼                                             │
│  ┌──────────────────┐                                  │
│  │  Query Embedding  │                                  │
│  │  (qwen-embedding) │                                  │
│  └────────┬─────────┘                                  │
│           │                                             │
│           ▼                                             │
│  ┌──────────────────┐     ┌──────────────────┐        │
│  │  Milvus 向量检索  │────→│  元数据过滤       │        │
│  │  HNSW Index      │     │  - 节气过滤       │        │
│  │  Top-K=10        │     │  - 体质过滤       │        │
│  │  Cosine Similarity│    │  - 分类过滤       │        │
│  └────────┬─────────┘     └────────┬─────────┘        │
│           └────────────────┬────────┘                   │
│                            │                            │
│                            ▼                            │
│              ┌──────────────────┐                       │
│              │   重排序 (Rerank)  │                       │
│              │  Score > 0.7      │                       │
│              │  Top-5 输出       │                       │
│              └────────┬─────────┘                       │
│                       │                                 │
│                       ▼                                 │
│              ┌──────────────────┐                       │
│              │  Prompt 注入       │                       │
│              │  {rag_results}    │                       │
│              └──────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

---

## 9.3 知识来源（6类内容）

| 来源 | 代码 | 说明 | 知识量级 | 更新频率 |
|------|------|------|---------|---------|
| 中医典籍 | `tcm_classics` | 黄帝内经、伤寒论、本草纲目等经典文献 | 5000+ chunks | 静态 |
| 体质学说 | `constitution_theory` | 王琦九种体质理论文献 | 2000+ chunks | 季度 |
| 节气养生 | `solar_term_knowledge` | 24节气调养方案详细知识 | 3000+ chunks | 年度 |
| 内容库精选 | `content_curated` | CMS中标记为知识源的内容 | 10000+ chunks | 持续 |
| 专业医学文献 | `medical_literature` | 经同行评审的中医养生相关论文 | 2000+ chunks | 季度 |
| 用户反馈沉淀 | `user_feedback` | 用户好评的回答沉淀为知识 | 1000+ chunks | 每周 |

---

## 9.4 知识切片策略

### 9.4.1 按主题切片

```
策略：以语义完整性为边界的智能切片

规则：
  - 最小长度：100字
  - 最大长度：500字
  - 优先在段落/小标题处切分
  - 保留上下文重叠（前后各50字）

示例：
原文：
  "## 气虚体质饮食调理
   气虚体质者宜食补气健脾的食物。推荐山药、大枣、小米、
   鸡肉等。避免生冷、油腻食物。四季调理各有侧重：
   春季宜食韭菜、菠菜以升发阳气；夏季宜食绿豆、扁豆
   以清热益气；秋季宜食银耳、百合以润肺益气；
   冬季宜食羊肉、核桃以温补肾气。"

切片结果：
  Chunk 1: "气虚体质者宜食补气健脾的食物。推荐山药、大枣、小米、鸡肉等。避免生冷、油腻食物。"
  Chunk 2: "四季调理各有侧重：春季宜食韭菜、菠菜以升发阳气；夏季宜食绿豆、扁豆以清热益气；"
  Chunk 3: "秋季宜食银耳、百合以润肺益气；冬季宜食羊肉、核桃以温补肾气。"
```

### 9.4.2 按节气切片

```
策略：每个节气作为一个独立知识单元

结构：
  {
    "solar_term": "chunfen",
    "dimensions": {
      "diet": "春分饮食调养完整内容...",
      "tea": "春分茶饮推荐完整内容...",
      "exercise": "春分运动方案完整内容...",
      "acupoint": "春分穴位保健完整内容...",
      "emotion": "春分情志调养完整内容...",
      "action_plan": "春分7天行动计划完整内容...",
      "introduction": "春分简介完整内容..."
    }
  }
  
切片：每个维度独立为1个chunk，标注节气+维度标签
```

### 9.4.3 按体质切片

```
策略：每个体质类型作为一个知识单元

结构：
  {
    "constitution": "qi_xu",
    "sections": {
      "definition": "气虚体质的定义与特征...",
      "diet": "气虚体质饮食调养...",
      "exercise": "气虚体质运动建议...",
      "lifestyle": "气虚体质生活方式...",
      "seasonal": "气虚体质四季调养...",
      "herbal": "气虚体质药膳参考..."
    }
  }
  
切片：每个section独立为1个chunk
```

---

## 9.5 Embedding流程

### 模型选择

| 维度 | 选择 | 说明 |
|------|------|------|
| 模型 | `text-embedding-v2` (通义千问) | 768维，中文优化 |
| 向量维度 | 768 | 平衡精度与存储 |
| 距离度量 | Cosine Similarity | 语义相似度 |

### 批处理流程

```
1. 从知识源读取原始内容
    │
    ▼
2. 切片引擎处理
    │
    ▼
3. 生成Embedding
   - 批量调用（每批50条）
   - 限流：20 QPS
   - 重试策略：3次指数退避
    │
    ▼
4. 写入Milvus
   - 批量插入（每批100条）
   - 自动创建索引（HNSW, M=16, efConstruction=200）
    │
    ▼
5. 记录写入日志
   - chunk_id, source, embedding_id, timestamp
```

---

## 9.6 检索流程

```
输入：用户问题 + 上下文（体质/节气/意图）
    │
    ▼
[1] Query预处理
    - 提取关键词
    - 关联用户体质和当前节气
    - 确定意图分类
    │
    ▼
[2] Query Embedding
    - 调用 text-embedding-v2
    - 生成 768 维向量
    │
    ▼
[3] Milvus 检索
    - Collection: shunshi_knowledge
    - Index: HNSW
    - 搜索参数：top_k=10, ef=64
    - 过滤表达式：
      expr = 'constitution == "qi_xu" or constitution == "" or solar_term == "chunfen" or solar_term == ""'
    │
    ▼
[4] 结果过滤 & 重排序
    - 过滤 score < 0.7 的结果
    - 按相关度 + 来源权重重排序
    - 去重（同一来源取最高分）
    - 取 Top-5
    │
    ▼
[5] 返回检索结果
    [
      {
        "chunk_id": "chunk_xxx",
        "content": "气虚体质者宜食补气健脾的食物...",
        "source": "constitution_theory",
        "solar_term": "",
        "constitution": "qi_xu",
        "relevance_score": 0.92
      },
      ...
    ]
```

---

## 9.7 向量表结构

### Milvus Collection 定义

```python
collection_name = "shunshi_knowledge"

schema = {
    "fields": [
        {
            "name": "chunk_id",
            "type": "VARCHAR",
            "max_length": 64,
            "is_primary": True
        },
        {
            "name": "embedding",
            "type": "FLOAT_VECTOR",
            "dim": 768
        },
        {
            "name": "content",
            "type": "VARCHAR",
            "max_length": 2048
        },
        {
            "name": "source",
            "type": "VARCHAR",
            "max_length": 30
        },
        {
            "name": "category",
            "type": "VARCHAR",
            "max_length": 30
        },
        {
            "name": "solar_term",
            "type": "VARCHAR",
            "max_length": 20
        },
        {
            "name": "constitution",
            "type": "VARCHAR",
            "max_length": 20
        },
        {
            "name": "created_at",
            "type": "INT64"
        }
    ],
    "index": {
        "field_name": "embedding",
        "index_type": "HNSW",
        "metric_type": "COSINE",
        "params": {
            "M": 16,
            "efConstruction": 200
        }
    }
}
```

---

## 9.8 RAG API设计

### POST /internal/rag/search

RAG检索（内部API，供AI Router调用）。

**Request:**

```json
{
  "query": "春分气虚体质吃什么好",
  "intent": "diet_advice",
  "filters": {
    "constitution": "qi_xu",
    "solar_term": "chunfen",
    "category": "diet",
    "source": ["constitution_theory", "solar_term_knowledge", "content_curated"]
  },
  "top_k": 5,
  "min_score": 0.7
}
```

**Response (200):**

```json
{
  "results": [
    {
      "chunk_id": "chunk_constitution_qixu_diet_001",
      "content": "气虚体质者春季宜食山药、大枣、小米等补气健脾食物。春分时节重在养肝，可配合枸杞、菊花疏肝。",
      "source": "constitution_theory",
      "category": "diet",
      "solar_term": "",
      "constitution": "qi_xu",
      "relevance_score": 0.92
    },
    {
      "chunk_id": "chunk_solar_chunfen_diet_001",
      "content": "春分饮食以平补为原则，宜食温和食物。气虚体质宜加山药粥、大枣茶。",
      "source": "solar_term_knowledge",
      "category": "diet",
      "solar_term": "chunfen",
      "constitution": "",
      "relevance_score": 0.88
    }
  ],
  "total_searched": 10,
  "total_returned": 5,
  "search_time_ms": 45
}
```

### POST /internal/rag/index

批量索引知识块（管理API）。

### DELETE /internal/rag/index/{chunk_id}

删除知识块。

### GET /internal/rag/stats

知识库统计信息。

---

## 9.9 缓存策略

| 数据 | 缓存Key | TTL | 说明 |
|------|---------|-----|------|
| 检索结果 | `rag:cache:{query_hash}:{filters_hash}` | 1h | 相同查询+相同过滤条件复用 |
| 热门查询 | `rag:popular:{intent}:{solar_term}` | 6h | 预计算的高频查询结果 |
| Embedding结果 | `rag:embedding:{text_hash}` | 30天 | 相同文本的embedding复用 |

---

## 9.10 召回日志分析

### 日志字段

```json
{
  "request_id": "req_uuid",
  "timestamp": "2026-03-17T19:36:00Z",
  "user_id": 12345,
  "query": "春分气虚体质吃什么好",
  "intent": "diet_advice",
  "filters": {
    "constitution": "qi_xu",
    "solar_term": "chunfen"
  },
  "results": [
    {"chunk_id": "chunk_001", "source": "constitution_theory", "score": 0.92, "used": true},
    {"chunk_id": "chunk_002", "source": "solar_term_knowledge", "score": 0.88, "used": true},
    {"chunk_id": "chunk_003", "source": "content_curated", "score": 0.75, "used": false}
  ],
  "search_time_ms": 45,
  "final_response_satisfaction": null  // 后续用户反馈填充
}
```

### 分析指标

| 指标 | 说明 | 目标 |
|------|------|------|
| 召回率 | Top-10中相关内容的占比 | > 80% |
| 命中率 | 有返回结果的比例 | > 95% |
| 使用率 | 被注入Prompt的结果占比 | > 70% |
| 平均得分 | Top-5结果的平均相似度 | > 0.8 |
| 检索延迟 | P99 | < 100ms |
| 无结果率 | 返回空结果的比例 | < 5% |

---

## 9.11 异常处理

| 场景 | 处理 |
|------|------|
| Milvus不可用 | 跳过RAG，使用纯Prompt |
| Embedding API不可用 | 使用缓存中的embedding（如有） |
| 检索超时 | 超过200ms返回空结果，不阻塞对话 |
| 检索结果质量差 | 降低min_score阈值重试，或跳过RAG |
| 知识库为空 | 返回空结果，AI使用通用知识回答 |

---

## 9.12 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| ai-router | 被依赖 | Router调用RAG检索 |
| content | 弱依赖 | 内容库精选是知识源之一 |
| constitution | 关联 | 体质知识是知识源之一 |
| solar-term | 关联 | 节气知识是知识源之一 |
| analytics | 依赖 | RAG召回日志上报 |

---

# 第十章 体质系统

## 10.1 概述

体质系统基于王琦教授九种体质理论，通过标准化问卷测试为用户判定体质类型，并关联个性化养生方案。体质结果是整个顺时 ShunShi 个性化服务的核心数据基础。

---

## 10.2 九种体质定义

| 体质 | 代码 | 核心特征 | 简要描述 |
|------|------|---------|---------|
| 平和质 | `pinghe` | 阴阳平衡 | 身体健康，精力充沛，是理想体质状态 |
| 气虚质 | `qi_xu` | 元气不足 | 易疲劳，气短懒言，易出汗，面色偏白 |
| 阳虚质 | `yang_xu` | 阳气不足 | 畏寒怕冷，手脚冰凉，精神不振，面色苍白 |
| 阴虚质 | `yin_xu` | 阴液亏少 | 口燥咽干，手足心热，盗汗，喜冷饮 |
| 痰湿质 | `tan_shi` | 痰湿凝聚 | 体形肥胖，腹部松软，面部油脂多，嗜睡 |
| 湿热质 | `shi_re` | 湿热内蕴 | 面垢油光，口苦口干，身重困倦，大便黏滞 |
| 血瘀质 | `xue_yu` | 血行不畅 | 面色偏暗，唇色紫暗，易有瘀斑，痛经 |
| 气郁质 | `qi_yu` | 气机郁滞 | 情志抑郁，多愁善感，胸闷叹气，咽喉异物感 |
| 特禀质 | `te_bing` | 先天特殊 | 过敏体质，易打喷嚏、起疹，对药物/食物敏感 |

---

## 10.3 测试问卷设计（25题）

### 问卷结构

- 总计25题，每题4个选项
- 题目涵盖9种体质维度
- 每个选项对应分值：1分（从不）/ 2分（偶尔）/ 3分（经常）/ 4分（总是）
- 选项采用行为描述式，避免引导性

### 完整问卷

```
┌─ 第一部分：身体状态（题1-10）────────────────────────────┐
│                                                         │
│ 1. 您容易感到疲劳吗？                                    │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：气虚质                                        │
│                                                         │
│ 2. 您容易手脚冰凉吗？                                    │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：阳虚质                                        │
│                                                         │
│ 3. 您感到口干咽燥吗？                                    │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：阴虚质                                        │
│                                                         │
│ 4. 您的体型偏胖或腹部松软吗？                            │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：痰湿质                                        │
│                                                         │
│ 5. 您面部或头部容易出油吗？                              │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：湿热质                                        │
│                                                         │
│ 6. 您的皮肤容易出现暗沉或瘀斑吗？                        │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：血瘀质                                        │
│                                                         │
│ 7. 您容易感到情绪低落或郁闷吗？                          │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：气郁质                                        │
│                                                         │
│ 8. 您容易打喷嚏或起皮疹吗？                              │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：特禀质                                        │
│                                                         │
│ 9. 您说话声音低弱或容易气短吗？                          │
│    A. 从不 (1分)  B. 偶尔 (2分)                          │
│    C. 经常 (3分)  D. 总是 (4分)                          │
│    → 对应：气虚质                                        │
│                                                         │
│ 10. 您容易感冒吗？                                       │
│     A. 从不 (1分)  B. 偶尔 (2分)                         │
│     C. 经常 (3分)  D. 总是 (4分)                         │
│     → 对应：气虚质                                       │
└─────────────────────────────────────────────────────────┘

┌─ 第二部分：生活习惯（题11-18）───────────────────────────┐
│                                                         │
│ 11. 您的食欲如何？                                       │
│     A. 很好 (1分)  B. 较好 (2分)                         │
│     C. 一般 (3分)  D. 较差 (4分)                         │
│     → 对应：气虚质 + 痰湿质                              │
│                                                         │
│ 12. 您的睡眠质量如何？                                   │
│     A. 很好 (1分)  B. 较好 (2分)                         │
│     C. 入睡困难 (3分)  D. 经常失眠 (4分)                  │
│     → 对应：阴虚质 + 气郁质                              │
│                                                         │
│ 13. 您的大便情况如何？                                   │
│     A. 正常 (1分)  B. 偶有不畅 (2分)                     │
│     C. 经常便秘 (3分)  D. 大便黏滞 (4分)                 │
│     → 对应：阴虚质 / 湿热质                              │
│                                                         │
│ 14. 您的耐寒能力如何？                                   │
│     A. 耐寒 (1分)  B. 一般 (2分)                         │
│     C. 较怕冷 (3分)  D. 很怕冷 (4分)                     │
│     → 对应：阳虚质                                       │
│                                                         │
│ 15. 您耐热能力如何？                                     │
│     A. 耐热 (1分)  B. 一般 (2分)                         │
│     C. 较怕热 (3分)  D. 很怕热 (4分)                     │
│     → 对应：阴虚质 + 湿热质                              │
│                                                         │
│ 16. 您是否容易出汗？                                     │
│     A. 不易出汗 (1分)  B. 偶尔 (2分)                     │
│     C. 稍动即汗 (3分)  D. 自汗盗汗 (4分)                 │
│     → 对应：气虚质 + 阴虚质                              │
│                                                         │
│ 17. 您的口渴情况如何？                                   │
│     A. 不口渴 (1分)  B. 偶尔口渴 (2分)                   │
│     C. 经常口渴 (3分)  D. 喜冷饮 (4分)                   │
│     → 对应：阴虚质 + 湿热质                              │
│                                                         │
│ 18. 您的运动习惯如何？                                   │
│     A. 经常运动 (1分)  B. 偶尔运动 (2分)                 │
│     C. 较少运动 (3分)  D. 不爱运动 (4分)                 │
│     → 对应：气虚质 + 痰湿质                              │
└─────────────────────────────────────────────────────────┘

┌─ 第三部分：情志精神（题19-25）───────────────────────────┐
│                                                         │
│ 19. 您的性格倾向？                                       │
│     A. 开朗乐观 (1分)  B. 较为平和 (2分)                 │
│     C. 容易焦虑 (3分)  D. 多愁善感 (4分)                 │
│     → 对应：气郁质 + 阴虚质                              │
│                                                         │
│ 20. 您面对压力的反应？                                   │
│     A. 从容应对 (1分)  B. 基本能应对 (2分)                │
│     C. 感到紧张 (3分)  D. 很难应对 (4分)                  │
│     → 对应：气虚质 + 气郁质                              │
│                                                         │
│ 21. 您是否容易健忘？                                     │
│     A. 从不 (1分)  B. 偶尔 (2分)                         │
│     C. 经常 (3分)  D. 总是 (4分)                         │
│     → 对应：血瘀质 + 气虚质                              │
│                                                         │
│ 22. 您是否容易感到胸闷？                                 │
│     A. 从不 (1分)  B. 偶尔 (2分)                         │
│     C. 经常 (3分)  D. 总是 (4分)                         │
│     → 对应：气郁质 + 血瘀质                              │
│                                                         │
│ 23. 您的精力水平如何？                                   │
│     A. 精力充沛 (1分)  B. 较好 (2分)                     │
│     C. 一般 (3分)  D. 容易疲惫 (4分)                     │
│     → 对应：气虚质 + 阳虚质                              │
│                                                         │
│ 24. 您是否容易叹气？                                     │
│     A. 从不 (1分)  B. 偶尔 (2分)                         │
│     C. 经常 (3分)  D. 总是 (4分)                         │
│     → 对应：气郁质                                       │
│                                                         │
│ 25. 您对季节变化的适应能力？                             │
│     A. 适应很好 (1分)  B. 基本适应 (2分)                 │
│     C. 春秋敏感 (3分)  D. 明显不适 (4分)                 │
│     → 对应：特禀质 + 气虚质                              │
└─────────────────────────────────────────────────────────┘
```

### 体质-题目映射矩阵

```
体质\题目  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25
平和质     ×                    ○
气虚质     ●        ○  ×     ●  ●  ×        ○  ×  ×  ×     ×     ○     ×     ○
阳虚质        ●                 ×        ●                    ×
阴虚质           ●           ×     ×  ×     ○  ×     ×  ×  ○
痰湿质              ●     ×                          ×
湿热质                 ●  ×              ×  ×     ○
血瘀质                    ●                 ×  ×           ●     ○
气郁质                       ●  ×                 ○  ○     ○        ×  ●
特禀质                          ●                              ○

● = 主要对应题  × = 次要对应题  ○ = 反向题（高分反而减分）
```

---

## 10.4 评分算法

### 10.4.1 加权计分

```python
# 每种体质的原始得分 = 主要题得分之和 × 1.0 + 次要题得分之和 × 0.5 - 反向题得分之和 × 0.3

def calculate_constitution_score(answers: dict, question_mapping: dict) -> dict:
    """
    answers: {question_id: score}  # 1-4分
    question_mapping: {
        "qi_xu": {
            "primary": [1, 9, 10],        # 主要题，权重1.0
            "secondary": [11, 20, 23],    # 次要题，权重0.5
            "inverse": [25]               # 反向题，权重-0.3
        },
        ...
    }
    """
    scores = {}
    for constitution, mapping in question_mapping.items():
        primary_sum = sum(answers.get(q, 1) for q in mapping["primary"])
        secondary_sum = sum(answers.get(q, 1) for q in mapping["secondary"])
        inverse_sum = sum(answers.get(q, 1) for q in mapping["inverse"])
        
        raw_score = (primary_sum * 1.0 + secondary_sum * 0.5 - inverse_sum * 0.3)
        max_score = (len(mapping["primary"]) * 4 * 1.0 + 
                     len(mapping["secondary"]) * 4 * 0.5 +
                     len(mapping["inverse"]) * 4 * 0.3)
        
        normalized_score = (raw_score / max_score) * 100 if max_score > 0 else 0
        scores[constitution] = round(normalized_score, 1)
    
    return scores
```

### 10.4.2 结果判定

```
1. 计算每种体质的标准化得分（0-100分）
    │
    ▼
2. 排序得分
    │
    ▼
3. 判定规则：
   - 最高分体质 = 主要体质
   - 最高分 ≥ 40 且与次高分差距 ≥ 10 → 单一体质
   - 次高分 ≥ 30 且与最高分差距 < 10 → 倾向体质
   - 所有分数 < 30 → 平和质（或测试无效，建议重测）
   
示例：
  气虚: 52, 阳虚: 35, 阴虚: 18, 痰湿: 12, ...
  → 主要体质：气虚质 (52分)
  → 倾向体质：阳虚质 (35分, 差距17>10，无倾向)
  
  气虚: 45, 阴虚: 38, 气郁: 22, ...
  → 主要体质：气虚质 (45分)
  → 倾向体质：阴虚质 (38分, 差距7<10)
```

---

## 10.5 体质解读生成

### 生成流程

```
体质测试完成 → 获得主要体质+倾向体质
    │
    ▼
构建解读 Prompt：
  - 体质定义知识（来自RAG）
  - 用户具体得分分布
  - 用户基本信息（年龄/性别/life_stage）
    │
    ▼
调用 AI (qwen-plus) 生成个性化解读：
  输出结构：
  1. 体质概述（你的体质特点）
  2. 具体表现（你在日常生活中可能的表现）
  3. 养生建议（饮食/运动/情志/作息）
  4. 季节调养要点
  5. 需要注意的事项
```

### 解读示例

```
【你的体质：气虚质，倾向阳虚】

📊 体质得分：
  气虚质：52分 ★ 主要体质
  阳虚质：35分
  
📖 体质概述：
  你属于气虚质，以元气不足、疲乏气短为主要特征。
  气虚则机体推动无力，可能导致面色偏白、容易出汗、
  说话声音低弱等表现。

🌱 你的可能表现：
  - 容易感到疲劳，活动后加重
  - 说话声音偏小，容易气短
  - 稍微运动就容易出汗
  - 抵抗力相对较弱，容易感冒

💊 养生建议：
  【饮食】宜食补气健脾食物：山药、大枣、小米、鸡肉
  【运动】适合柔和运动：太极、八段锦、散步
  【情志】保持乐观开朗，避免过度思虑
  【作息】早睡早起，午间小憩20-30分钟
  【季节】春季宜升补阳气，冬季宜温补肾气

⚠️ 注意事项：
  避免过度劳累和熬夜，感冒时及时就医。
  如有严重疲劳或气短症状，建议到正规医院检查。
```

---

## 10.6 内容推荐关联

```sql
-- 体质与内容关联查询
SELECT ci.* FROM content_items ci
WHERE ci.status = 'published'
  AND ci.required_level <= '{user_level}'
  AND (
    JSON_CONTAINS(ci.related_constitution, '"{constitution_type}"')
    OR JSON_CONTAINS(ci.related_constitution, '"{sub_constitution_type}"')
  )
ORDER BY ci.sort_weight DESC, ci.published_at DESC
LIMIT 10;
```

---

## 10.7 节气调养方案关联

```
当前节气 × 用户体质 → 匹配调养方案

逻辑：
  1. 获取当前节气：chunfen
  2. 获取用户体质：qi_xu
  3. 查询：
     solar_term_knowledge WHERE solar_term = 'chunfen' AND constitution = 'qi_xu'
  4. 如无精确匹配，降级：
     solar_term_knowledge WHERE solar_term = 'chunfen' AND constitution = 'general'
  5. 返回调养方案（饮食/茶饮/运动/穴位/情志/行动/简介）
```

---

## 10.8 数据表设计

### constitutions 表（体质定义）

```sql
CREATE TABLE constitutions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL COMMENT '体质代码',
    name VARCHAR(20) NOT NULL COMMENT '体质名称',
    description TEXT NOT NULL COMMENT '体质概述',
    characteristics JSON NOT NULL COMMENT '体质特征列表',
    dietary_advice JSON NOT NULL COMMENT '饮食建议',
    exercise_advice JSON NOT NULL COMMENT '运动建议',
    lifestyle_advice JSON NOT NULL COMMENT '生活方式建议',
    seasonal_advice JSON NOT NULL COMMENT '四季调养建议',
    precautions JSON NOT NULL COMMENT '注意事项',
    icon_url VARCHAR(512) DEFAULT NULL COMMENT '体质图标',
    color_theme VARCHAR(20) DEFAULT NULL COMMENT '主题色',
    display_order INT NOT NULL DEFAULT 0,
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### constitution_tests 表（测试记录）

```sql
CREATE TABLE constitution_tests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    primary_type VARCHAR(30) NOT NULL COMMENT '主要体质代码',
    primary_score DECIMAL(5,1) NOT NULL,
    sub_type VARCHAR(30) DEFAULT NULL COMMENT '倾向体质代码',
    sub_score DECIMAL(5,1) DEFAULT NULL,
    all_scores JSON NOT NULL COMMENT '所有体质得分',
    interpretation TEXT DEFAULT NULL COMMENT 'AI生成的解读',
    test_duration_sec INT DEFAULT NULL COMMENT '测试用时',
    device_info JSON DEFAULT NULL COMMENT '设备信息',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_uuid (uuid),
    INDEX idx_user_id (user_id),
    INDEX idx_primary_type (primary_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### constitution_answers 表（答题记录）

```sql
CREATE TABLE constitution_answers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    test_id BIGINT NOT NULL COMMENT '关联constitution_tests.id',
    user_id BIGINT NOT NULL,
    question_id INT NOT NULL COMMENT '题目编号 1-25',
    score TINYINT NOT NULL COMMENT '选项分值 1-4',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_test_id (test_id),
    INDEX idx_user_id (user_id),
    UNIQUE KEY uk_test_question (test_id, question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 10.9 API 设计

### GET /api/v1/constitution/questions

获取测试问卷。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "questions": [
      {
        "id": 1,
        "text": "您容易感到疲劳吗？",
        "options": [
          {"label": "A", "text": "从不", "score": 1},
          {"label": "B", "text": "偶尔", "score": 2},
          {"label": "C", "text": "经常", "score": 3},
          {"label": "D", "text": "总是", "score": 4}
        ],
        "related_constitution": ["qi_xu"],
        "category": "body"
      },
      ...
    ],
    "total_questions": 25,
    "estimated_time_min": 5
  }
}
```

### POST /api/v1/constitution/submit

提交测试结果。

**Request:**

```json
{
  "answers": [
    {"question_id": 1, "score": 3},
    {"question_id": 2, "score": 2},
    ...
  ],
  "device_info": {
    "platform": "ios",
    "app_version": "1.0.0"
  }
}
```

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "test_uuid": "test_uuid_xxx",
    "result": {
      "primary_type": "qi_xu",
      "primary_name": "气虚质",
      "primary_score": 52.0,
      "sub_type": "yang_xu",
      "sub_name": "阳虚质",
      "sub_score": 35.0,
      "all_scores": {
        "pinghe": 15.0,
        "qi_xu": 52.0,
        "yang_xu": 35.0,
        "yin_xu": 18.0,
        "tan_shi": 12.0,
        "shi_re": 10.0,
        "xue_yu": 8.0,
        "qi_yu": 22.0,
        "te_bing": 6.0
      }
    },
    "interpretation": {
      "summary": "你属于气虚质...",
      "characteristics": ["容易感到疲劳", "说话声音低弱", "容易出汗"],
      "diet_advice": "宜食补气健脾食物...",
      "exercise_advice": "适合柔和运动...",
      "lifestyle_advice": "早睡早起...",
      "seasonal_advice": "春季宜升补阳气..."
    }
  }
}
```

### GET /api/v1/constitution/me

获取用户当前体质。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "primary_type": "qi_xu",
    "primary_name": "气虚质",
    "sub_type": "yang_xu",
    "sub_name": "阳虚质",
    "tested_at": "2026-03-15T10:00:00+08:00",
    "test_count": 2,
    "interpretation_summary": "你属于气虚质，以元气不足为主要特征..."
  }
}
```

### GET /api/v1/constitution/{code}

获取体质详细信息。

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "code": "qi_xu",
    "name": "气虚质",
    "description": "气虚质以元气不足、疲乏气短为主要特征...",
    "characteristics": [
      "容易疲劳",
      "气短懒言",
      "容易出汗",
      "面色偏白",
      "抵抗力较弱"
    ],
    "dietary_advice": {
      "recommended": ["山药", "大枣", "小米", "鸡肉", "黄芪"],
      "avoid": ["生冷食物", "油腻食物", "萝卜（破气）"]
    },
    "exercise_advice": {
      "recommended": ["太极拳", "八段锦", "散步"],
      "avoid": ["剧烈运动", "大汗淋漓的运动"],
      "notes": "运动强度宜轻柔，以微微出汗为度"
    },
    "icon_url": "https://cdn.../constitution_qi_xu.png",
    "color_theme": "#F5DEB3"
  }
}
```

### GET /api/v1/constitution/list

获取九种体质列表。

### GET /api/v1/constitution/history

获取用户测试历史。

**Query:** `?page=1&size=10`

---

## 10.10 异常处理

| 场景 | 处理 |
|------|------|
| 答案不完整（<25题） | 提示"请完成所有题目" |
| 所有得分均<30 | 返回平和质 + 提示"建议咨询专业人士" |
| AI解读生成失败 | 使用预设模板解读 |
| 频繁重测 | 免费用户每月限1次，养心+不限 |
| 答案异常（全选同一选项） | 标记为可疑结果，不影响判定 |

---

## 10.11 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| user | 依赖 | 体质关联用户档案 |
| ai-chat | 依赖 | 体质信息注入AI上下文 |
| ai-router | 依赖 | 体质影响RAG检索过滤 |
| dashboard | 依赖 | 首页根据体质生成建议 |
| content | 关联 | 体质相关内容推荐 |
| solar-term | 关联 | 体质×节气的交叉调养 |
| rag | 依赖 | 体质知识是RAG知识源 |
| analytics | 依赖 | 测试事件上报 |

---

# 第十一章 节气系统

## 11.1 概述

节气系统是顺时 ShunShi 的核心差异化模块，管理二十四节气的精确计算、调养方案和提醒服务。系统为每个节气提供7个维度的调养方案，结合用户体质提供个性化的节气养生指导。

---

## 11.2 二十四节气完整定义

### 11.2.1 春季

| 节气 | 代码 | 太阳黄经 | 日期范围 | 特点 |
|------|------|---------|---------|------|
| 立春 | `lichun` | 315° | 2月3-5日 | 春季开始，万物复苏 |
| 雨水 | `yushui` | 330° | 2月18-20日 | 降雨开始，雨量渐增 |
| 惊蛰 | `jingzhe` | 345° | 3月5-7日 | 春雷始鸣，蛰虫惊醒 |
| 春分 | `chunfen` | 0° | 3月20-22日 | 昼夜平分，阴阳各半 |
| 清明 | `qingming` | 15° | 4月4-6日 | 天清地明，万物显明 |
| 谷雨 | `guyu` | 30° | 4月19-21日 | 雨生百谷，播种时节 |

### 11.2.2 夏季

| 节气 | 代码 | 太阳黄经 | 日期范围 | 特点 |
|------|------|---------|---------|------|
| 立夏 | `lixia` | 45° | 5月5-7日 | 夏季开始，万物繁茂 |
| 小满 | `xiaoman` | 60° | 5月20-22日 | 麦粒渐满，尚未成熟 |
| 芒种 | `mangzhong` | 75° | 6月5-7日 | 有芒之谷，可种忙种 |
| 夏至 | `xiazhi` | 90° | 6月21-22日 | 日长之至，阳气极盛 |
| 小暑 | `xiaoshu` | 105° | 7月6-8日 | 暑气始生，天气炎热 |
| 大暑 | `dashu` | 120° | 7月22-24日 | 暑气至极，酷热难耐 |

### 11.2.3 秋季

| 节气 | 代码 | 太阳黄经 | 日期范围 | 特点 |
|------|------|---------|---------|------|
| 立秋 | `liqiu` | 135° | 8月7-9日 | 秋季开始，暑去凉来 |
| 处暑 | `chushu` | 150° | 8月22-24日 | 暑气终止，秋凉始至 |
| 白露 | `bailu` | 165° | 9月7-9日 | 露水凝白，秋意渐浓 |
| 秋分 | `qiufen` | 180° | 9月22-24日 | 昼夜平分，秋色平分 |
| 寒露 | `hanlu` | 195° | 10月8-9日 | 露水已寒，将要结冰 |
| 霜降 | `shuangjiang` | 210° | 10月23-24日 | 霜气肃杀，万物凋零 |

### 11.2.4 冬季

| 节气 | 代码 | 太阳黄经 | 日期范围 | 特点 |
|------|------|---------|---------|------|
| 立冬 | `lidong` | 225° | 11月7-8日 | 冬季开始，万物收藏 |
| 小雪 | `xiaoxue` | 240° | 11月22-23日 | 小雪初降，天地闭塞 |
| 大雪 | `daxue` | 255° | 12月6-8日 | 大雪纷飞，银装素裹 |
| 冬至 | `dongzhi` | 270° | 12月21-23日 | 日短之至，阴极阳生 |
| 小寒 | `xiaohan` | 285° | 1月5-7日 | 冷气积久，寒气尚小 |
| 大寒 | `dahan` | 300° | 1月20-21日 | 寒气之极，寒冷至甚 |

---

## 11.3 每节气7个维度

### 11.3.1 维度定义

| 维度 | 代码 | 说明 | 内容格式 |
|------|------|------|---------|
| 饮食调养 | `diet` | 节气饮食原则与推荐食物 | 3-5个推荐 + 2-3个避忌 |
| 茶饮推荐 | `tea` | 适合节气的茶饮 | 2-3个茶方 |
| 运动养生 | `exercise` | 适合节气的运动方案 | 2-3个运动 + 注意事项 |
| 穴位保健 | `acupoint` | 节气重点穴位按摩 | 2-3个穴位 + 按摩方法 |
| 情志调养 | `emotion` | 节气情绪管理建议 | 情志特点 + 调养方法 |
| 七天行动 | `action_plan` | 节气7天行动计划 | 每天一条具体行动 |
| 节气简介 | `introduction` | 节气概述与养生要点 | 200-300字 |

### 11.3.2 示例：春分调养方案

```json
{
  "solar_term": "chunfen",
  "name": "春分",
  "date_range": "3月20日-4月4日",
  "solar_longitude": 0,
  "introduction": {
    "text": "春分是二十四节气之一，春季第四个节气。此时太阳到达黄经0°，昼夜平分。春分时节阴阳各半，养生重在调和阴阳，疏肝理气。春分也是养生的关键时期，适宜顺应天时，调整饮食起居。",
    "key_points": ["调和阴阳", "疏肝理气", "早睡早起", "少酸多甘"]
  },
  "diet": {
    "principle": "春分饮食以平补为原则，忌偏热偏寒。宜食温和食物，少酸多甘。",
    "recommended": [
      {
        "name": "春笋",
        "effect": "清热化痰，益气和胃",
        "recipe": "油焖春笋"
      },
      {
        "name": "菠菜",
        "effect": "滋阴平肝，助消化",
        "recipe": "凉拌菠菜"
      },
      {
        "name": "山药",
        "effect": "健脾益气，补肺固肾",
        "recipe": "山药小米粥"
      }
    ],
    "avoid": ["辛辣刺激", "油腻煎炸", "寒凉食物"]
  },
  "tea": {
    "principle": "春分宜饮花茶，疏肝解郁，理气和中。",
    "recommendations": [
      {
        "name": "玫瑰花茶",
        "ingredients": "玫瑰花3-5朵",
        "method": "沸水冲泡5分钟",
        "effect": "疏肝解郁，活血化瘀"
      },
      {
        "name": "菊花枸杞茶",
        "ingredients": "菊花3朵、枸杞10粒",
        "method": "沸水冲泡5分钟",
        "effect": "清肝明目，滋阴润燥"
      },
      {
        "name": "陈皮大枣茶",
        "ingredients": "陈皮3g、大枣3枚",
        "method": "煮沸10分钟",
        "effect": "理气健脾，补中益气"
      }
    ]
  },
  "exercise": {
    "principle": "春分宜舒缓运动，以形体的伸展带动气血运行。",
    "recommendations": [
      {
        "name": "八段锦",
        "duration": "20-30分钟",
        "frequency": "每日1-2次",
        "notes": "重点练习'调理脾胃须单举'"
      },
      {
        "name": "踏青散步",
        "duration": "30-45分钟",
        "frequency": "每周3-5次",
        "notes": "在公园或绿地步行，呼吸新鲜空气"
      }
    ],
    "precautions": ["运动量不宜过大", "避免大汗淋漓", "注意保暖防风"]
  },
  "acupoint": {
    "principle": "春分按摩肝经和胆经穴位，有助疏肝理气。",
    "recommendations": [
      {
        "name": "太冲穴",
        "location": "足背第一、二趾间缝上约2寸凹陷处",
        "method": "拇指按压，每侧3-5分钟",
        "effect": "疏肝理气，清肝泻火"
      },
      {
        "name": "期门穴",
        "location": "乳头直下第六肋间",
        "method": "掌根揉按，每侧2-3分钟",
        "effect": "疏肝理气，调理气血"
      },
      {
        "name": "足三里",
        "location": "外膝眼下四横指",
        "method": "拇指按压，每侧3-5分钟",
        "effect": "健脾和胃，扶正培元"
      }
    ]
  },
  "emotion": {
    "characteristics": "春分时节肝气旺盛，易出现情绪波动、急躁易怒。",
    "advice": [
      "保持心态平和，避免情绪大起大落",
      "多参加户外活动，接触自然",
      "与亲友交流，疏解压力",
      "适当进行冥想或深呼吸练习"
    ],
    "warnings": ["避免过度思虑", "少生气", "保持充足睡眠"]
  },
  "action_plan": {
    "title": "春分7天养生行动计划",
    "days": [
      {"day": 1, "action": "了解春分养生要点，泡一杯玫瑰花茶", "icon": "📖"},
      {"day": 2, "action": "午餐加一份菠菜，饭后散步20分钟", "icon": "🥬"},
      {"day": 3, "action": "学习八段锦'调理脾胃须单举'式", "icon": "🧘"},
      {"day": 4, "action": "睡前按摩太冲穴3分钟，泡脚15分钟", "icon": "👆"},
      {"day": 5, "action": "制作山药小米粥，邀家人共享", "icon": "🍲"},
      {"day": 6, "action": "户外踏青30分钟，做深呼吸练习", "icon": "🌳"},
      {"day": 7, "action": "回顾一周养生收获，记录身体变化", "icon": "📝"}
    ]
  }
}
```

---

## 11.4 Calendar API

### GET /api/v1/solar-term/calendar

获取年度节气日历。

**Query:** `?year=2026`

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "year": 2026,
    "terms": [
      {
        "code": "lichun",
        "name": "立春",
        "date": "2026-02-04",
        "time": "2026-02-04T02:38:00+08:00",
        "solar_longitude": 315,
        "season": "spring"
      },
      {
        "code": "yushui",
        "name": "雨水",
        "date": "2026-02-18",
        "time": "2026-02-18T22:28:00+08:00",
        "solar_longitude": 330,
        "season": "spring"
      },
      ...
    ],
    "current_term": {
      "code": "chunfen",
      "name": "春分",
      "date": "2026-03-20",
      "progress": 75,
      "days_remaining": 8,
      "next_term": {
        "code": "qingming",
        "name": "清明",
        "date": "2026-04-04"
      }
    }
  }
}
```

---

## 11.5 当前节气API

### GET /api/v1/solar-term/current

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "term": {
      "code": "chunfen",
      "name": "春分",
      "date": "2026-03-20",
      "date_range_start": "2026-03-20",
      "date_range_end": "2026-04-04",
      "solar_longitude": 0,
      "season": "spring",
      "progress": 0.75,
      "days_remaining": 8
    },
    "personalized": {
      "diet_highlight": "春分饮食以平补为原则，气虚体质宜食山药、大枣",
      "tea_highlight": "推荐玫瑰花茶疏肝解郁",
      "exercise_highlight": "推荐八段锦，重点练习'调理脾胃须单举'",
      "acupoint_highlight": "推荐按摩太冲穴疏肝理气",
      "emotion_highlight": "保持心态平和，避免情绪波动"
    },
    "next_term": {
      "code": "qingming",
      "name": "清明",
      "date": "2026-04-04",
      "days_until": 8
    },
    "prev_term": {
      "code": "jingzhe",
      "name": "惊蛰",
      "date": "2026-03-05"
    }
  }
}
```

---

## 11.6 节气详情API

### GET /api/v1/solar-term/{term_code}

**Response (200):**

```json
{
  "code": 0,
  "data": {
    "code": "chunfen",
    "name": "春分",
    "date": "2026-03-20",
    "date_range": "3月20日-4月4日",
    "solar_longitude": 0,
    "season": "spring",
    "cover_image": "https://cdn.../solar_chunfen.jpg",
    "introduction": {
      "text": "春分是二十四节气之一...",
      "key_points": ["调和阴阳", "疏肝理气"]
    },
    "diet": { ... },
    "tea": { ... },
    "exercise": { ... },
    "acupoint": { ... },
    "emotion": { ... },
    "action_plan": { ... },
    "related_content": [
      {
        "uuid": "content_uuid_xxx",
        "title": "春分养肝食疗方",
        "cover_image": "..."
      }
    ]
  }
}
```

---

## 11.7 推荐逻辑

```
1. 节气首页推荐：
   - 当前节气 → 显示"节气专区"卡片
   - 节气前3天 → 显示"即将到来的{节气}"预告
   - 节气后2天 → 推送"新节气调养方案"

2. 个性化推荐：
   当前节气 × 用户体质 → 匹配调养方案
   - 精确匹配：solar_term_code + constitution_type
   - 降级匹配：solar_term_code + "general"
   - 兜底匹配：solar_term_code 通用方案

3. 内容推荐：
   - 节气相关内容：content_items WHERE related_solar_term CONTAINS current_term
   - 按热度排序：view_count × 0.3 + like_count × 0.5 + sort_weight × 0.2
   - 新内容加权：7天内 +20%
```

---

## 11.8 提醒逻辑

### 提醒类型

| 类型 | 触发时间 | 内容 |
|------|---------|------|
| 节气预告 | 节气前1天 | "明天是{节气}，养生重点：{要点}" |
| 节气到来 | 节气当天 08:00 | "今天是{节气}，点击查看调养方案" |
| 行动计划 | 节气7天期间 每天 08:00 | "节气养生第{N}天：{今日行动}" |
| 节气过半 | 节气期间中点 | "本节气已过半，这些方案你试了吗？" |

### 提醒配置

```
用户设置：
  - solar_term_reminder: true/false
  - daily_reminder_time: "08:00"
  - push_mute_start/end: 免打扰时段

默认：
  - 所有用户默认开启节气提醒
  - 行动计划提醒仅养心+会员
  - 免打扰时段内不推送
```

---

## 11.9 缓存策略

| 数据 | 缓存Key | TTL | 说明 |
|------|---------|-----|------|
| 当前节气 | `solar:current` | 1h | 节气不变时命中 |
| 节气详情 | `solar:detail:{code}` | 24h | 静态数据 |
| 个性化方案 | `solar:personal:{user_uuid}:{term_code}` | 24h | 体质×节气方案 |
| 年度日历 | `solar:calendar:{year}` | 30天 | 整年不变 |
| 行动计划 | `solar:action:{user_uuid}:{term_code}` | 24h | 用户已完成的行动 |

---

## 11.10 数据表设计

### solar_terms 表（节气定义）

```sql
CREATE TABLE solar_terms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL COMMENT '节气代码',
    name VARCHAR(10) NOT NULL COMMENT '节气名称',
    solar_longitude INT NOT NULL COMMENT '太阳黄经',
    season VARCHAR(10) NOT NULL COMMENT 'spring/summer/autumn/winter',
    order_in_year INT NOT NULL COMMENT '年度序号 1-24',
    general_description TEXT NOT NULL COMMENT '通用简介',
   养生要点 TEXT DEFAULT NULL COMMENT '养生要点',
    cover_image VARCHAR(512) DEFAULT NULL COMMENT '封面图OSS URL',
    UNIQUE KEY uk_code (code),
    INDEX idx_season (season),
    INDEX idx_order (order_in_year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### solar_term_dates 表（具体年份日期）

```sql
CREATE TABLE solar_term_dates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    term_code VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    date DATE NOT NULL COMMENT '节气日期',
    exact_time DATETIME NOT NULL COMMENT '精确时间（北京时间）',
    UNIQUE KEY uk_term_year (term_code, year),
    INDEX idx_date (date),
    INDEX idx_year (year)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### solar_term_plans 表（调养方案）

```sql
CREATE TABLE solar_term_plans (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    term_code VARCHAR(20) NOT NULL,
    constitution_type VARCHAR(30) NOT NULL DEFAULT 'general' COMMENT '体质类型，general为通用',
    diet JSON DEFAULT NULL COMMENT '饮食调养方案',
    tea JSON DEFAULT NULL COMMENT '茶饮推荐方案',
    exercise JSON DEFAULT NULL COMMENT '运动养生方案',
    acupoint JSON DEFAULT NULL COMMENT '穴位保健方案',
    emotion JSON DEFAULT NULL COMMENT '情志调养方案',
    action_plan JSON DEFAULT NULL COMMENT '七天行动计划',
    introduction TEXT DEFAULT NULL COMMENT '个性化简介',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_term_constitution (term_code, constitution_type),
    INDEX idx_term_code (term_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### solar_term_user_progress 表（用户节气行动进度）

```sql
CREATE TABLE solar_term_user_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    term_code VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    completed_days JSON DEFAULT NULL COMMENT '已完成的行动天数 [1,3,5]',
    action_plan_viewed BOOLEAN NOT NULL DEFAULT FALSE,
    diet_tips_viewed BOOLEAN NOT NULL DEFAULT FALSE,
    tea_tips_viewed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_term_year (user_id, term_code, year),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 11.11 异常处理

| 场景 | 处理 |
|------|------|
| 节气日期数据缺失 | 使用算法计算作为兜底 |
| 节气方案未配置 | 返回通用方案 + 提示"详细方案即将上线" |
| 体质×节气方案未匹配 | 降级到通用方案 |
| 行动计划天数超出节气范围 | 按实际剩余天数截断 |
| 跨年边界 | 年度切换时预热新年份数据 |

### 节气日期计算兜底算法

```python
def calculate_solar_term(year: int, term_index: int) -> datetime:
    """
    简化版节气日期计算（寿星公式）
    term_index: 0-23 (小寒到大寒)
    精度：±1天
    """
    # 寿星节气公式
    Y = year % 100
    C = 20 + term_index  # 世纪常数
    D = {0: 6.11, 1: 20.84, 2: 4.15, 3: 19.04, 4: 5.59, 5: 20.88,
         6: 6.318, 7: 21.86, 8: 8.35, 9: 23.44, 10: 7.628, 11: 22.2,
         12: 8.218, 13: 23.78, 14: 7.9, 15: 23.22, 16: 8.218, 17: 23.45,
         18: 7.928, 19: 23.22, 20: 8.318, 21: 22.84, 22: 7.9, 23: 22.6}
    L = int(Y / 4)  # 闰年数
    
    day = int(D[term_index] + 0.2422 * Y - L) - int((D[term_index] + 0.2422 * Y - L) / 7) * 7
    
    month = (term_index // 2) + 1
    if term_index % 2 == 1:
        month = (term_index + 1) // 2
    
    return datetime(year, month, day)
```

---

## 11.12 与其他模块的关系

| 模块 | 关系 | 说明 |
|------|------|------|
| dashboard | 被依赖 | 首页节气专区/每日计划 |
| ai-chat | 被依赖 | 节气知识注入AI上下文 |
| ai-router | 被依赖 | 节气影响RAG过滤 |
| constitution | 关联 | 体质×节气的交叉调养 |
| content | 关联 | 节气相关内容推荐 |
| notification | 依赖 | 节气提醒推送 |
| rag | 依赖 | 节气知识是RAG知识源 |
| membership | 依赖 | 节气详情深度控制 |
| analytics | 依赖 | 节气浏览/行动完成事件上报 |

---

# 文档附录

## 附录A：错误码总表

| 范围 | 模块 | 说明 |
|------|------|------|
| 10000-10099 | Auth | 用户认证相关 |
| 10100-10199 | Membership | 会员订阅相关 |
| 10200-10299 | Content | 内容服务相关 |
| 10300-10399 | AI Chat | AI对话相关 |
| 10400-10499 | Constitution | 体质测试相关 |
| 10500-10599 | Solar Term | 节气服务相关 |
| 10600-10699 | Family | 家庭服务相关 |
| 10700-10799 | Payment | 支付相关 |
| 10900-10999 | System | 系统级错误 |

## 附录B：通用API响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

| code | 说明 |
|------|------|
| 0 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |
| 503 | 服务不可用 |

## 附录C：API版本策略

- 当前版本：v1
- URL前缀：`/api/v1/`
- 版本升级策略：新版本在新URL上发布，旧版本保留6个月
- 破坏性变更需要提前30天通知

---

> **文档结束**  
> 本文档涵盖顺时 ShunShi 第一部分（第1-11章）的完整设计。  
> 后续章节将覆盖：通知服务、家庭服务、埋点分析、CMS后台、部署方案、测试方案等。
