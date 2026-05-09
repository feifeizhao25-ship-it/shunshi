# 顺时 ShunShi 专用版开发文档索引

## 已完成清单

| 版本 | 文件 | 内容 |
|------|------|------|
| **1. Flutter 前端** | `frontend/flutter-frontend.md` | Riverpod状态管理、GoRouter路由、组件库、页面实现 |
| **2. AI Router/后端** | `backend/ai-router-backend.md` | FastAPI完整代码、Skills实现、数据库CRUD |
| **3. 测试QA** | `testing/qa-testing.md` | 单元/集成/E2E测试、AI Eval、CI/CD门禁 |
| **4. 商业计划书** | `business/business-plan.md` | 投资人叙事、财务模型、万亿市场分析 |

---

## 文档结构

```
shunshi/
├── README.md                           # 总索引
│
├── round1-*.md                        # 通用版 (17个文档)
├── round2-*.md
├── round3-*.md
├── round4-*.md
│
├── frontend/
│   └── flutter-frontend.md            # Flutter专用 (32KB)
│
├── backend/
│   └── ai-router-backend.md           # 后端专用 (30KB)
│
├── testing/
│   └── qa-testing.md                   # 测试专用 (30KB)
│
└── business/
    └── business-plan.md                # 商业计划专用 (16KB)
```

---

## 内容摘要

### Flutter 前端 (32,066 字符)
- pubspec.yaml 完整依赖
- Clean Architecture 分层
- Riverpod 状态管理
- GoRouter 路由配置
- 通用组件 (AppButton, AppCard, ChatBubble, ContentCard)
- 页面实现 (MainPage, HomePage, ChatDetailPage)
- API 客户端、Docker 配置
- 本地存储、支付集成、通知

### AI Router/后端 (30,141 字符)
- pyproject.toml 完整依赖
- SQLAlchemy 模型 (User, Conversation, Message)
- FastAPI 接口 (Auth, Chat)
- AI Router 主逻辑
- Intent Detector、Safety Guard
- Skills 基类 + 5个实现 (MoodFirstAid, SleepWindDown...)
- Skills 注册表
- User Service、Chat Service
- Database、Cache、API Schemas

### 测试QA (30,315 字符)
- 测试金字塔架构
- Pytest 配置 (conftest.py)
- 单元测试 (Utils, Intent Detector, Safety Guard)
- 集成测试 (Auth API, Chat API)
- AI Eval 自动化评测
- E2E 测试 (用户旅程, 订阅流程)
- 性能测试 (响应时间, 压力测试)
- GitHub Actions CI/CD 门禁

### 商业计划 (15,541 字符)
- 执行摘要
- 市场分析 (TAM/SAM/SOM)
- 竞争格局
- 用户画像 (4类)
- 商业模式 (订阅+礼物+企业)
- Unit Economics
- 增长飞轮
- 财务预测 (5年)
- 融资规划
- 五大护城河
- 团队介绍
- 里程碑路线图
- 投资亮点

---

## 下一步

所有专用版本已完成。合计生成 **21 个文档**，总字数约 **200KB+**。

可以直接将对应文档交给：
- Flutter 工程师 → `frontend/flutter-frontend.md`
- 后端工程师 → `backend/ai-router-backend.md`
- QA 工程师 → `testing/qa-testing.md`
- 投资人/管理层 → `business/business-plan.md`
