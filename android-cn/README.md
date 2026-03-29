# 顺时 ShunShi 开发文档索引

## 完成清单

### 第一轮：产品总览与架构

| 文档 | 文件 | 描述 |
|------|------|------|
| 产品总览 | `round1-product-overview.md` | 产品定位、核心理念、生命周期、技术架构 |
| 前端目录 | `round1-frontend-structure.md` | Flutter 项目结构、60+页面清单 |
| 后端目录 | `round1-backend-structure.md` | FastAPI 项目结构、API接口、部署架构 |

### 第二轮：UI 与 Design System

| 文档 | 文件 | 描述 |
|------|------|------|
| Design System | `round2-design-system.md` | 颜色、字体、间距、组件规范 |
| Widget Tree | `round2-widget-tree.md` | 页面结构、组件树、状态定义 |

### 第三轮：后端核心系统

| 文档 | 文件 | 描述 |
|------|------|------|
| 数据库 SQL | `round3-database-sql.md` | PostgreSQL 完整建表语句 |
| AI Router | `round3-ai-router.md` | 路由架构、意图检测、模型选择 |
| Skills 系统 | `round3-skills-system.md` | 12个内置 Skills 实现 |
| Prompt 系统 | `round3-prompt-system.md` | Prompt 版本管理、灰度发布 |
| 订阅系统 | `round3-subscription-system.md` | 订阅产品、购买流程、礼物订阅 |
| 家庭系统 | `round3-family-system.md` | 家庭组、成员管理、关怀消息 |
| 生命周期 | `round3-lifecycle-system.md` | 四阶段判定、动态更新 |
| 记忆系统 | `round3-memory-system.md` | 记忆类型、隐私控制、存储 |

### 第四轮：测试与部署

| 文档 | 文件 | 描述 |
|------|------|------|
| 测试体系 | `round4-testing-system.md` | 10轮测试、AI Eval、CI/CD |
| 部署架构 | `round4-deployment.md` | K8s部署、灰度回滚、监控告警 |
| 迭代路线 | `round4-roadmap-growth.md` | 10年路线、商业化、护城河 |

---

## 文件列表

```
shunshi/
├── round1-product-overview.md
├── round1-frontend-structure.md
├── round1-backend-structure.md
├── round2-design-system.md
├── round2-widget-tree.md
├── round3-database-sql.md
├── round3-ai-router.md
├── round3-skills-system.md
├── round3-prompt-system.md
├── round3-subscription-system.md
├── round3-family-system.md
├── round3-lifecycle-system.md
├── round3-memory-system.md
├── round4-testing-system.md
├── round4-deployment.md
└── round4-roadmap-growth.md
```

---

## 核心数据摘要

### 页面统计
- Flutter 页面：60+
- 前端组件：40+
- 后端 API：50+

### 数据库表
- 用户系统：5 表
- 对话系统：2 表
- 记忆系统：3 表
- 内容系统：3 表
- 习惯系统：3 表
- 节气系统：1 表
- 家庭系统：5 表
- 订阅系统：3 表
- 审计系统：2 表
- **总计：27+ 表**

### Skills 数量
- 内置 Skills：12 个
- 可扩展：支持自定义

### 产品阶段
- 4 大生命周期阶段
- 4 个订阅级别
- 5 大护城河

---

## 下一步行动

1. **启动开发**：将文档交给工程代理（Antigravity/Cursor/Claude Code）
2. **Flutter 开发**：按照 `round1-frontend-structure.md` 创建项目
3. **后端开发**：按照 `round1-backend-structure.md` 创建项目
4. **数据库初始化**：执行 `round3-database-sql.md` 建表
5. **AI 系统**：实现 `round3-ai-router.md` + `round3-skills-system.md`
6. **测试验证**：按照 `round4-testing-system.md` 建立测试

---

## 文档维护

- 版本：1.0
- 更新日期：2026-03-08
- 维护人：Claw 🦅
