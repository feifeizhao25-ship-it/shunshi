# SEASONS International — PRD 差距分析 + 开发计划
生成时间: 2026-03-20
当前版本: Flutter (生产构建可用)  
目标版本: React Native PRD (完整生产)

---

## 一、整体架构对比

| 模块 | 当前状态 | PRD 要求 | 差距 |
|------|---------|---------|------|
| 前端框架 | Flutter 5.5 | React Native 0.73+ | ⚠️ 架构差异(Flutter可用,PRD推荐RN) |
| 后端框架 | FastAPI + Python | FastAPI + Python | ✅ 一致 |
| 数据库 | PostgreSQL 16 (ECS) | PostgreSQL 16 (AWS RDS) | ✅ 已用PG, AWS迁移可选 |
| 缓存 | 无 | Redis 7 | ❌ 缺失 |
| AI | SiliconFlow (本地) | OpenAI GPT-4o + Anthropic Claude | ⚠️ 需切换模型 |
| 支付 | Stripe mock | Stripe + Apple IAP + Google Play | ⚠️ Stripe mock |
| 认证 | 无 | Google/Apple/Facebook OAuth + JWT | ❌ 完全缺失 |
| 存储 | 无 | AWS S3 + CloudFront | ❌ 缺失 |
| 搜索 | 无 | Meilisearch | ❌ 缺失 |
| 部署 | 阿里云 ECS | AWS ECS Fargate | ⚠️ 可迁移 |
| 监控 | 无 | Datadog | ❌ 缺失 |

---

## 二、数据库 Schema 差距

### 当前已有 (PostgreSQL)
- `users` ✅ (部分字段)
- `solar_terms` ✅ (24节气)
- `constitution_types` ✅ (9体质)
- `acupoints` ✅ (8穴位)
- `recipes` ✅ (14条)
- `chat_sessions` ✅
- `chat_messages` ✅
- `wellness_journals` ✅
- `subscription_orders` ✅

### 完全缺失的表 (PRD要求)
- ❌ `user_auth` — OAuth认证表
- ❌ `body_types` — 7种Body Type体质表
- ❌ `body_type_questions` — Body Type测试题
- ❌ `body_type_test_records` — 测试记录
- ❌ `beverages` — 饮品/茶饮表
- ❌ `movement_practices` — 运动/练习表
- ❌ `articles` — 文章表
- ❌ `audio_contents` — 音频内容表 (SEASONS已有简化版)
- ❌ `wellness_reports` — 健康报告表
- ❌ `subscription_orders` — 完整订阅订单
- ❌ `referral_codes` — 推荐码表
- ❌ `user_favorites` — 收藏表
- ❌ `family_members` — 家庭成员表 (简化版有)
- ❌ `seasonal_events` — 季节事件表
- ❌ `user_preferences` — 用户偏好设置

### 字段缺失

**users 表:**
| 字段 | 当前 | PRD要求 |
|------|------|--------|
| body_type | ❌ | ✅ |
| body_type_tested_at | ❌ | ✅ |
| body_type_scores | ❌ | ✅ |
| hemisphere | ⚠️ (在请求参数) | ✅ |
| timezone | ❌ | ✅ |
| locale | ❌ | ✅ |
| country_code | ❌ | ✅ |
| dietary_restrictions | ❌ | ✅ |
| preferred_units | ❌ | ✅ |
| streak_days | ⚠️ (简化) | ✅ |
| deleted_at (GDPR) | ❌ | ✅ |

---

## 三、API 端点对比

### Authentication APIs (全部缺失 ❌)
```
POST /api/v1/auth/signup          ❌
POST /api/v1/auth/login           ❌
POST /api/v1/auth/google          ❌
POST /api/v1/auth/apple           ❌
POST /api/v1/auth/facebook       ❌
POST /api/v1/auth/refresh        ❌
POST /api/v1/auth/logout         ❌
DELETE /api/v1/auth/account       ❌ (GDPR)
GET  /api/v1/auth/account/export ❌ (GDPR)
```

### User APIs (部分实现 ⚠️)
```
GET  /api/v1/user/profile        ✅
PUT  /api/v1/user/profile        ⚠️ (简化)
PUT  /api/v1/user/avatar         ❌
GET  /api/v1/user/preferences    ❌
PUT  /api/v1/user/preferences    ❌
GET  /api/v1/user/family        ✅ (简化)
POST /api/v1/user/family/invite  ✅ (简化)
DELETE /api/v1/user/family/{id}  ✅ (简化)
```

### Seasonal Content APIs
```
GET /api/v1/seasons/current      ✅ (简化)
GET /api/v1/seasons/{code}       ❌
GET /api/v1/seasons/calendar     ❌
GET /api/v1/seasons/events       ❌
GET /api/v1/seasons/{code}/recipes    ❌
GET /api/v1/seasons/{code}/beverages ❌
GET /api/v1/seasons/{code}/practices  ❌
```

### Body Type APIs (全部缺失 ❌)
```
GET /api/v1/body-type/questions      ❌
POST /api/v1/body-type/assessment   ❌
GET /api/v1/body-type/result        ❌
GET /api/v1/body-type/history        ❌
GET /api/v1/body-type/types          ❌
GET /api/v1/body-type/types/{code}  ❌
GET /api/v1/body-type/plan          ❌
```

### Content APIs
```
# Recipes
GET /api/v1/recipes               ⚠️ (简化,只有14条)
GET /api/v1/recipes/{id}          ❌
GET /api/v1/recipes/recommended    ❌
POST /api/v1/recipes/{id}/rate    ❌

# Beverages (茶饮) — 完全缺失 ❌
GET /api/v1/beverages             ❌
GET /api/v1/beverages/{id}       ❌
GET /api/v1/beverages/recommended ❌

# Movement Practices — 完全缺失 ❌
GET /api/v1/practices             ❌
GET /api/v1/practices/{id}        ❌
GET /api/v1/practices/recommended  ❌

# Articles — 完全缺失 ❌
GET /api/v1/articles             ❌
GET /api/v1/articles/{slug}       ❌
GET /api/v1/articles/recommended  ❌

# Audio — 简化版存在 ⚠️
GET /api/v1/audio                ⚠️
GET /api/v1/audio/{id}          ❌
GET /api/v1/audio/categories    ❌

# Search — 完全缺失 ❌
GET /api/v1/search              ❌

# Favorites — 完全缺失 ❌
GET /api/v1/favorites           ❌
POST /api/v1/favorites          ❌
DELETE /api/v1/favorites/{id}   ❌
```

### AI Chat APIs
```
POST /api/v1/chat/sessions       ❌ (用/ai/chat替代)
GET  /api/v1/chat/sessions      ❌
GET  /api/v1/chat/sessions/{id}  ❌
POST /api/v1/chat/sessions/{id}/messages ❌ (SSE流式)
DELETE /api/v1/chat/sessions/{id} ❌
```

### Journal APIs (简化版 ⚠️)
```
GET  /api/v1/journal/today        ⚠️ (简化)
POST /api/v1/journal              ⚠️ (简化)
GET  /api/v1/journal/history      ❌
GET  /api/v1/journal/calendar    ❌
GET  /api/v1/journal/stats       ❌
GET  /api/v1/reports/weekly      ❌
GET  /api/v1/reports/monthly     ❌
POST /api/v1/reports/generate     ❌
```

### Subscription APIs
```
GET  /api/v1/subscription/plans           ✅
POST /api/v1/subscription/checkout         ⚠️ (mock)
POST /api/v1/subscription/verify-apple     ❌
POST /api/v1/subscription/verify-google    ❌
GET  /api/v1/subscription/status           ⚠️ (简化)
POST /api/v1/subscription/cancel           ❌
POST /api/v1/subscription/restore          ✅
GET  /api/v1/subscription/portal           ❌
POST /api/v1/webhooks/stripe               ❌
```

### Home Aggregation
```
GET /api/v1/home    ❌ (用/api/v1/seasons/home/dashboard替代,功能类似)
```

---

## 四、AI System Prompt 对比

### 当前 System Prompt (seasons_chat.py)
- 简洁英文版 ✅
- 包含季节context injection ✅
- 安全分级 (Level 1/2/3) ✅
- 危机响应 ✅

### PRD System Prompt 差异
| 项目 | 当前 | PRD要求 |
|------|------|--------|
| 变量注入 | season + hemisphere | season + body_type + timezone + local_time + dietary_restrictions |
| 响应字数 | <100 words | <150 words |
| Body Type context | ❌ | ✅ |
| 时区 context | ❌ | ✅ |
| 饮食限制 context | ❌ | ✅ |
| 引用app内容 | ❌ | ✅ |
| 每回复一条建议 | ⚠️ | ✅ |

---

## 五、App 页面差距 (Flutter vs PRD React Native)

### 当前已实现 ✅
- Home Screen (简化)
- Library (6 tabs: Breathing/Stretch/Tea/Sleep/Reflection/Seasonal)
- Audio Player
- AI Chat (简化)
- Onboarding (5步)
- Privacy Settings
- Help Center
- Family (简化)
- Profile (简化)

### 缺失的页面 ❌
- **Discover Screen** — 独立发现页面(tab替代)
- **Body Type Quiz** — 7种体质测试(12题)
- **Body Type Result** — 结果页+动画
- **Recipe Detail** — 完整食谱页(步骤/营养/保存)
- **Beverage Detail** — 饮品详情页
- **Movement Practice** — 运动练习页
- **Article Page** — 文章阅读页
- **Journal Calendar** — 完整日历视图
- **Journal Weekly/Monthly Report** — 报告页
- **Settings/Preferences** — 完整设置页
- **Notification Permission Screen** — 权限请求页
- **Full Audio Player** — 完整播放器
- **Subscription Plans UI** — 订阅页

### 功能差距
| 功能 | 当前 | PRD |
|------|------|-----|
| SSE流式响应 | ❌ | ✅ |
| i18n (多语言) | ❌ | ✅ |
| 离线模式 | ❌ | ✅ |
| Dietary restrictions | ❌ | ✅ |
| 单位制切换(metric/imperial) | ❌ | ✅ |
| Body Type Quiz | ❌ | ✅ |
| Recipe rating | ❌ | ✅ |
| Journal streak tracking | ⚠️ | ✅ |
| Push notifications | ❌ | ✅ |
| In-app purchases | ❌ | ✅ |

---

## 六、开发计划 (按优先级)

### Phase 0: 基础设施完善 (立即可做)
- [ ] HTTPS/SSL 配置 (等域名实名认证)
- [ ] Redis 安装和配置
- [ ] Stripe webhook 处理
- [ ] JWT 认证中间件
- [ ] 数据库迁移脚本 (添加缺失字段和表)

### Phase 1: 核心 API 补全 (1-2天)
- [ ] Body Type 系统 (7种类型 + 12题测试 + API)
- [ ] Beverages 饮品 API (50+ 饮品数据)
- [ ] Movement Practices API (20+ 练习)
- [ ] Articles API (20+ 文章)
- [ ] Recipes 完整 CRUD
- [ ] Favorites API
- [ ] Search API (简单like搜索)

### Phase 2: AI System 升级 (半天)
- [ ] 更新 System Prompt (PRD版本,注入body_type/timezone/dietary)
- [ ] SSE 流式响应 (ChatMessage SSE endpoint)
- [ ] AI 上下文窗口管理 (最近10条消息)
- [ ] RAG 知识库 (可选,pgvector)

### Phase 3: Auth + Payments (1天)
- [ ] Google OAuth (后端 + 前端)
- [ ] Apple Sign-In
- [ ] Stripe 真实 checkout
- [ ] Stripe webhook 处理
- [ ] Apple IAP 验证
- [ ] Google Play Billing 验证
- [ ] Subscription status 完整API

### Phase 4: Flutter 前端补全 (2-3天)
- [ ] Body Type Quiz 页面 + 动画
- [ ] Recipe Detail 完整页面
- [ ] Beverage Detail 页面
- [ ] Article 阅读页面
- [ ] Journal 完整功能 (calendar/stats/report)
- [ ] Settings/Preferences 页面
- [ ] Subscription Plans 页面
- [ ] i18n 框架搭建 (EN/JA/KO/DE/FR)

### Phase 5: DevOps + 合规 (1天)
- [ ] CI/CD (GitHub Actions)
- [ ] GDPR 数据导出/删除API
- [ ] CCPA "Do Not Sell" 端点
- [ ] AWS 部署配置 (可选)
- [ ] CloudWatch/Datadog 监控

---

## 七、关键数据需求

### 需要新增的种子数据
| 类型 | 当前数量 | PRD目标 | 差距 |
|------|---------|---------|------|
| Body Types | 0 | 7 | ❌ -7 |
| Body Type Questions | 0 | 12 | ❌ -12 |
| Recipes | 14 | 100+ | ❌ -86 |
| Beverages | 0 | 50+ | ❌ -50 |
| Movement Practices | 0 | 30+ | ❌ -30 |
| Articles | 0 | 30+ | ❌ -30 |
| Audio Contents | 17 | 50+ | ❌ -33 |

---

## 八、技术债务

1. **Flutter → React Native 迁移** (重大,PRD明确要求)
   - 当前Flutter代码不可复用
   - 需要完全重写前端
   - 预计工作量: 4-6周

2. **阿里云 → AWS 迁移** (可选,当前可用)
   - ECS → RDS PostgreSQL
   - S3 替代本地存储
   - CloudFront CDN

3. **In-memory DB → 真实PostgreSQL** (部分完成)
   - Chat sessions已用in-memory dict
   - User data需要迁移到PG

4. **API 版本不一致**
   - 部分端点用/api/v1, 部分用/api/v1/seasons
   - PRD统一为/api/v1/xxx
