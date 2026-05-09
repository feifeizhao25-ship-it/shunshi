# 顺时 项目记忆文件（每次对话必须先读取）

## 项目简介
顺时 ShunShi 是一款基于中医二十四节气+九种体质的 AI 养生管家。
SEASONS 是其国际版，基于四季+七种Body Type。

## 技术栈
- 前端：Flutter 3.x + GoRouter + Riverpod（现有4个项目）
- 后端：Python FastAPI + SQLite（ECS 116.62.32.43:4010）
- 设计规范：水墨画风格（CN）/ 深色禅意（Global）

## 代码规范
- Dart: flutter_lints, 命名 camelCase, 文件 snake_case
- Python: 类型注解, async/await, Pydantic
- API响应: {"success": bool, "data": {...}} 或 {"detail": "..."}
- 时间: UTC存储, 前端转本地时区
- ID: UUID

## 项目结构（4个Flutter项目）
```
~/Documents/Shunshi/
├── android-cn/     # 顺时 Android (193 files, 37K lines)
├── ios-cn/         # 顺时 iOS (162 files, 34K lines)
├── android-global/ # SEASONS Android (139 files, 31K lines)
├── ios-global/     # SEASONS iOS (112 files, 24K lines)
├── backend/        # 后端（ECS /opt/shunshi/backend/）
├── docs/           # 文档
├── ui参考-顺时/     # 16个CN UI参考图
└── ui参考-seasons/ # 22个Global UI参考图
```

## 设计规范（CN版 "水墨画"）
- 主色: #144227 (墨绿)
- 背景: #FDF9F4 (宣纸白)
- 辅色: #74593C (暖杏), #4C3605 (淡金/会员)
- 文字: #1C1C19 (不用纯黑)
- 无硬线：用背景色差替代边框
- Serif标题 + Sans正文

## 已完成
- [x] Phase 0: 主题系统更新（水墨画设计规范）
- [x] 首页重写（时辰养生详情页 - 十二时辰完整数据）
- [x] ShunshiColors + ShunShiColors 颜色统一
- [x] 编译通过（android-cn + ios-cn）
- [x] 后端 auth/chat/intl API 工作正常
- [x] 手机安装测试（顺时CN + SEASONS Global）

## 下一步（按Phase顺序）
- [ ] Phase 1: 统一4个项目代码（flavor variant）
- [ ] Phase 2: CN版逐页面UI重构（参考16个UI图）
- [ ] Phase 3: Global版UI重构（参考22个UI图）
- [ ] Phase 4: 后端升级（SQLite→PostgreSQL, Redis, Milvus）
- [ ] Phase 5: AI系统（多模型调度, RAG）
- [ ] Phase 6: 集成测试 + 部署

## 关键决策
1. 4个Flutter项目共享90%代码，用flavor区分CN/Global
2. 两套颜色系统已统一（ShunshiColors作为兼容层）
3. 后端当前用SQLite，后续迁移到PostgreSQL
4. API地址: 116.62.32.43:4010（公网直连）

**Updated:** 2026-04-09 19:17 CST
