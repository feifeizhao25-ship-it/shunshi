# PROJECT_CONTEXT.md — 项目记忆

## 关键决策

- 2026-04-25: 后端选 Python FastAPI，前端选 Flutter（非文档要求的 React Native）
- 2026-04-26: ECS 单机部署（非 Docker），PostgreSQL 9.6 + Redis
- 2026-05-16: **前端框架差异确认**：KIMI_PROMPT 要求 React Native，实际用 Flutter。不重写，在 Flutter 基础上执行
- 2026-05-16: **API 双重路径 bug 修复**：AppConfig.apiBaseUrl 含 `/api/v1`，Dio 调用又加 `/api/v1/` → 双重路径。修复：baseUrl 改为不含 `/api/v1`

## 架构差异（文档 vs 实际）

| 维度 | KIMI_PROMPT 要求 | 实际 | 决策 |
|------|-----------------|------|------|
| 前端框架 | React Native | Flutter | 保持 Flutter，不重写 |
| 前端目录 | mobile-cn/ mobile-global/ | android-cn/ android-global/ | 保持现有目录 |
| API 路由 | /api/v1/{cn,global,shared}/* | /api/v1/* (统一) | 后续迭代再加 cn/global 前缀 |
| 部署 | Docker + docker-compose | 直接 systemd + nginx | 保持现有方式 |
| Python 版本 | 3.12 | 3.9 (ECS) | 兼容性处理 |

## 踩坑笔记

- AppConfig.apiBaseUrl + Dio 路径 = 双重 /api/v1 — 所有 API 请求 404
- Flutter web base-href 必须匹配 nginx 路径，否则加载错误的 JS
- Safari PWA 缓存极其顽固，用独立端口绕过
- Mac Air 16GB 构建 OOM，需要 purge 内存后重试
- Flutter web service worker 缓存旧版本，需禁用或改名

## 现有后端对标

| Phase | 文档要求 | 实际状态 | 差距 |
|-------|---------|---------|------|
| P0 骨架 | config/database/main/core | ✅ settings.py + main.py | 缺标准 config.py/database.py |
| P1 模型 | 30+ 表 | 65 表 ✅ | 超额完成 |
| P2 Service | 16 services | 22 services ✅ | 超额完成 |
| P3 API | 100+ endpoints | 727 endpoints ✅ | 超额完成 |
| P4 Celery | 8 tasks | ❌ 无 | 需新建 |
| P5 知识库 | 19 JSON + seed + embedding | ❌ 无 | 需新建 |
| P9 部署 | Docker + CI/CD | systemd + nginx | 需补充 |

**Last Updated**: 2026-05-16 20:34 CST
