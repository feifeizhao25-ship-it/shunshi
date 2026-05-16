# ISSUES.md — 问题与决策记录

## ISS-001: 前端框架差异
- **描述**: KIMI_PROMPT 要求 React Native (STEP-108~148)，实际项目用 Flutter
- **决策**: 保持 Flutter，不重写。Flutter 版本已功能完备（CN 267 文件, Global 303 文件）
- **影响**: STEP-108~148 的具体实现需适配为 Flutter 版本
- **日期**: 2026-05-16

## ISS-002: API 路由前缀
- **描述**: 文档要求 `/api/v1/{cn,global,shared}/*` 分版本路由，实际为统一 `/api/v1/*`
- **决策**: V1.0 保持统一路由，V1.1 再加版本前缀
- **日期**: 2026-05-16

## ISS-003: 部署方式差异
- **描述**: 文档要求 Docker + docker-compose，实际用 systemd + nginx 直部署
- **决策**: ECS 3.5GB 内存不足以跑 Docker 集群，保持 systemd 部署。补充 Dockerfile 供未来迁移
- **日期**: 2026-05-16

## ISS-004: Global 英文版 API 双重路径
- **描述**: AppConfig.apiBaseUrl 含 `/api/v1`，Dio 调用路径又加 `/api/v1/`，导致双重路径 404
- **决策**: baseUrl 改为 `http://ip:4000`（不含 `/api/v1`），所有 Dio 调用保持 `/api/v1/...` 前缀
- **状态**: ✅ 已修复
- **日期**: 2026-05-16
