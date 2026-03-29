# 《顺时》自动开发提示词（最终版）

> 版本: 1.0  
> 日期: 2026-03-13

---

## 一、代理角色定义

你是一个全栈 AI 软件工程代理（Full-Stack Autonomous Agent）。

**你的任务**：从零构建并上线一个生产级 AI 产品系统 —— 「顺时 ShunShi」。

**产品目标**：打造一个 AI 养生陪伴系统，通过节律管理、养生建议与情绪陪伴帮助用户顺应四季，改善生活方式。

**产品边界**：
- ❌ 不是医疗工具
- ❌ 不做诊断
- ❌ 不推荐药物
- ❌ 不解读体检报告

---

## 二、最终交付物

1. ✅ Flutter iOS + Android 客户端
2. ✅ AI Router 后端服务
3. ✅ 内容与媒体服务
4. ✅ 数据库结构
5. ⏳ 自动化测试
6. ⏳ Docker 与阿里云部署配置
7. ⏳ CI/CD
8. ✅ 开发文档与运行说明

---

## 三、开发原则

- 使用模块化架构
- 所有 AI 调用必须通过 AI Router
- AI 输出必须符合 JSON Schema
- 所有接口必须有自动化测试
- 每完成一个模块必须运行测试
- 出现错误自动修复
- 至少执行 10 轮迭代优化

---

## 四、客户端开发（Flutter）

### 技术栈

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.8.1
  dio: ^5.8.0+1
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.4
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  intl: ^0.20.2
  uuid: ^4.5.1
  connectivity_plus: ^6.1.4
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
  sign_in_with_apple: ^6.0.0
  google_sign_in: ^6.2.2
```

### 项目结构

```
lib/
├── presentation/
│   ├── pages/
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   ├── chat_page.dart
│   │   ├── solar_term_page.dart
│   │   ├── wellness_page.dart
│   │   ├── wellness/
│   │   │   ├── acupressure_page.dart
│   │   │   ├── constitution_page.dart
│   │   │   ├── exercise_page.dart
│   │   │   ├── food_page.dart
│   │   │   ├── mood_page.dart
│   │   │   ├── sleep_page.dart
│   │   │   └── tea_page.dart
│   │   ├── family_page.dart
│   │   └── profile_page.dart
│   └── widgets/
├── providers/
├── domain/
│   ├── entities/
│   └── usecases/
├── repositories/
├── data/
│   ├── models/
│   │   ├── user_profile.dart
│   │   ├── follow_up.dart
│   │   └── family.dart
│   ├── datasources/
│   ├── repositories_impl/
│   └── services/
│       ├── today_plan_service.dart
│       └── notification_service.dart
├── design_system/
│   ├── components.dart
│   └── theme.dart
├── core/
│   ├── router/
│   ├── network/
│   ├── utils/
│   ├── prompt/
│   └── security/
└── main.dart
```

---

## 五、核心页面实现清单

### ✅ 已实现

| 页面 | 文件 | 状态 |
|------|------|------|
| 首页 | home_page.dart | ✅ |
| AI聊天页 | chat_page.dart | ✅ |
| 节气页 | solar_term_page.dart | ✅ |
| 养生页 | wellness_page.dart | ✅ |
| 穴位页 | wellness/acupressure_page.dart | ✅ |
| 体质页 | wellness/constitution_page.dart | ✅ |
| 运动页 | wellness/exercise_page.dart | ✅ |
| 饮食页 | wellness/food_page.dart | ✅ |
| 情绪页 | wellness/mood_page.dart | ✅ |
| 睡眠页 | wellness/sleep_page.dart | ✅ |
| 茶饮页 | wellness/tea_page.dart | ✅ |
| 家庭页 | family_page.dart | ✅ |
| 我的页 | profile_page.dart | ✅ |

### 页面组件

| 组件 | 状态 |
|------|------|
| 今日洞察 | ✅ |
| 三件小事 | ✅ |
| AI聊天入口 | ✅ |
| Follow-up卡片 | ✅ |
| 节气卡片 | ✅ |
| 家庭状态卡片 | ✅ |
| 消息流 | ✅ |
| 快捷问题 | ✅ |
| 输入框 | ✅ |
| 内容卡片 | ✅ |

---

## 六、AI Router 服务

### 后端技术栈

```yaml
python: ^3.10
fastapi: ^0.115.0
uvicorn: ^0.32.0
pydantic: ^2.10.0
httpx: ^0.27.0
loguru: ^0.7.0
```

### 项目结构

```
shunshi-backend/
├── app/
│   ├── main.py
│   ├── router/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── chat.py
│   │   ├── today_plan.py
│   │   └── ...
│   ├── models/
│   ├── services/
│   └── utils/
├── requirements.txt
└── .env.example
```

### ✅ 已实现 API

| API | 端点 | 状态 |
|-----|------|------|
| 健康检查 | GET /health | ✅ |
| 用户注册 | POST /api/v1/auth/register | ✅ |
| 用户登录 | POST /api/v1/auth/login | ✅ |
| AI聊天 | POST /api/v1/chat | ✅ |
| 今日计划 | GET /api/v1/today-plan | ✅ |

---

## 七、Prompt系统

### Prompt 分层

```
Core Prompt (核心指令)
    ↓
Policy Prompt (策略约束)
    ↓
Task Prompt (任务指令)
    ↓
UserMessage (用户输入)
```

### Prompt 版本

| 版本 | 用途 |
|------|------|
| SS_CORE_ALL_v1.0 | 通用核心 |
| SS_POLICY_PREMIUM_v1.0 | 付费用户策略 |
| SS_TASK_CHAT_v1.0 | 聊天任务 |
| SS_TASK_PLAN_v1.0 | 计划任务 |

---

## 八、AI输出 Schema

### 必须符合

```json
{
  "text": "string",
  "tone": "gentle",
  "care_status": "stable",
  "follow_up": {
    "in_days": "number",
    "intent": "string"
  },
  "offline_encouraged": "boolean",
  "presence_level": "normal",
  "safety_flag": "none"
}
```

### 降级策略

1. Schema 解析失败 → 自动修复
2. 修复失败 → 降级为纯文本
3. 纯文本 → 返回 text 字段

---

## 九、数据库设计

### MySQL 表

```sql
-- 用户表
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    life_stage VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 会话表
CREATE TABLE conversations (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    messages TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 内容表
CREATE TABLE contents (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    type VARCHAR(20),
    media_url VARCHAR(500),
    tags JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Follow-up表
CREATE TABLE follow_ups (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    title VARCHAR(255),
    status VARCHAR(20),
    scheduled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 订阅表
CREATE TABLE subscriptions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    plan VARCHAR(20),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 家庭关系表
CREATE TABLE family_relations (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    member_name VARCHAR(100),
    relation VARCHAR(20),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 十、内容数据

### 初始内容

| 类型 | 数量 | 状态 |
|------|------|------|
| 24节气 | 24 | ⏳ |
| 100食疗 | 100 | ⏳ |
| 50穴位 | 50 | ⏳ |
| 30运动 | 30 | ⏳ |
| 20睡眠建议 | 20 | ⏳ |

### 内容字段

```json
{
  "title": "string",
  "description": "string",
  "media_url": "string",
  "tags": ["string"]
}
```

---

## 十一、自动化测试

### 测试类型

| 类型 | 状态 |
|------|------|
| 单元测试 | ⏳ |
| Widget测试 | ⏳ |
| API测试 | ⏳ |
| Schema测试 | ⏳ |
| 订阅测试 | ⏳ |

### 测试覆盖

- AI聊天
- 节气
- 内容
- 家庭
- 订阅
- Follow-up

---

## 十二、部署配置

### Docker

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 阿里云配置

| 服务 | 配置 |
|------|------|
| ECS | 2核4G |
| RDS | MySQL 8.0 |
| Redis | 1G |
| OSS | 标准存储 |
| CDN | 全球加速 |

### CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: flutter test
      - name: Build APK
        run: flutter build apk --release
      - name: Deploy to Docker
        run: docker build -t shunshi-backend .
```

---

## 十三、迭代循环

### 执行流程

```
1. 生成项目结构
2. 实现基础功能
3. 运行测试
4. 修复错误
5. 继续开发
```

### 迭代次数

- 最低：10 轮
- 建议：15-20 轮

---

## 十四、最终输出清单

| 输出物 | 状态 |
|--------|------|
| Flutter 项目代码 | ✅ |
| AI Router 代码 | ✅ |
| 数据库结构 | ✅ |
| Docker 配置 | ⏳ |
| 部署文档 | ⏳ |
| 测试报告 | ⏳ |
| API 文档 | ⏳ |

---

## 十五、启动指令

### 本地开发

```bash
# Flutter
cd ~/Documents/shunshi-all/shunshi
flutter run

# Backend
cd ~/Documents/shunshi-all/shunshi-backend
python -m uvicorn app.main:app --reload --port 4000
```

### 生产部署

```bash
# Docker
docker build -t shunshi-backend .
docker run -d -p 4000:4000 shunshi-backend
```

---

## 十六、相关文档

1. `PRD-SHUNSHI-FINAL.md` - 产品需求文档
2. `EXECUTION_BACKLOG.md` - 开发任务拆解
3. `TECHNICAL_ARCHITECTURE.md` - 技术架构

---

*文档结束 - 可直接用于 AI 代理执行*
