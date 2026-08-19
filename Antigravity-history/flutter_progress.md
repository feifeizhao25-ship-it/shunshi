# 顺时 Flutter 双端迁移 — 进度总览

> 🕐 更新时间：2026-03-05 10:00 CST

---

## ✅ 项目状态

| 指标 | 状态 |
|------|------|
| `flutter analyze` | ✅ **0 errors** (仅 info/warning) |
| 单元测试 | ✅ **13/13 passed** |
| 依赖安装 | ✅ 151 packages resolved |
| 目标平台 | ✅ iOS + Android |

---

## 📁 项目结构（44 个文件）

```
shunshi_flutter/
├── lib/
│   ├── main.dart                              ← 入口 + ProviderScope
│   ├── core/
│   │   ├── config/
│   │   │   ├── env.dart                       ← dev/staging/prod 环境
│   │   │   └── feature_flags.dart             ← 灰度/回滚 Feature Flags
│   │   ├── constants/
│   │   │   ├── api_constants.dart             ← API 路径 + 超时
│   │   │   └── app_constants.dart             ← 业务常量
│   │   ├── di/
│   │   │   └── injection.dart                 ← Riverpod DI 全连线
│   │   ├── error/
│   │   │   ├── exceptions.dart                ← 数据层异常
│   │   │   └── failures.dart                  ← 业务层失败
│   │   ├── network/
│   │   │   ├── api_client.dart                ← Dio + 日志 + 重试拦截器
│   │   │   └── network_info.dart              ← 网络连接检测
│   │   ├── storage/
│   │   │   ├── local_storage.dart             ← SharedPreferences 封装
│   │   │   └── secure_storage.dart            ← FlutterSecureStorage 封装
│   │   ├── theme/
│   │   │   └── app_theme.dart                 ← 主题 + 品牌色 + 季节色
│   │   └── utils/
│   │       └── logger.dart                    ← 日志 + AI 审计日志
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── ai_response.dart               ← AIResponse (JSON Schema 严格)
│   │   │   ├── care_status.dart               ← CareStatus / PresenceLevel / SafetyFlag
│   │   │   ├── content_item.dart              ← 穴位/食谱/运动内容实体
│   │   │   ├── follow_up_plan.dart            ← 跟进计划 + 阶段记忆 + 退让记录
│   │   │   ├── message.dart                   ← Message / Conversation / ContentCard
│   │   │   ├── solar_term.dart                ← 节气 + 三候 + 诗词 + DailyPlan
│   │   │   ├── subscription_state.dart        ← 统一订阅状态
│   │   │   └── user.dart                      ← User + UserContext 完整映射
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   ├── content_repository.dart
│   │   │   ├── solar_term_repository.dart
│   │   │   └── subscription_repository.dart
│   │   └── usecases/
│   │       ├── apply_presence_policy.dart      ← 退让机制 ✅ 已测试
│   │       ├── generate_daily_plan.dart        ← 每日计划 + fallback
│   │       ├── schedule_follow_up.dart         ← 跟进计划提取
│   │       └── send_message.dart              ← 消息发送 + 审计日志
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── chat_local_datasource.dart ← 消息/计划/退让 本地缓存
│   │   │   └── remote/
│   │   │       └── ai_router_datasource.dart  ← ❌ 绝不直连模型 API
│   │   └── repositories/
│   │       └── chat_repository_impl.dart      ← 远端+本地混合
│   └── presentation/
│       ├── providers/
│       │   ├── chat_providers.dart             ← 消息状态/安全标记/SafeMode
│       │   ├── home_providers.dart             ← 每日计划/节气/导航
│       │   └── subscription_providers.dart     ← 订阅状态/isPremium
│       ├── pages/
│       │   ├── chat/chat_page.dart             ← 聊天页（消息+卡片+SafeMode）
│       │   ├── home/home_page.dart             ← 首页（计划+节气+快捷入口）
│       │   ├── profile/profile_page.dart       ← 个人中心
│       │   ├── profile/settings_page.dart      ← 设置（关怀/记忆/静默/责任边界）
│       │   └── subscription/subscription_page.dart ← 订阅页（连续照护措辞）
│       ├── router/
│       │   └── main_shell.dart                 ← 底部导航 Shell
│       └── widgets/
│           └── shared_widgets.dart             ← SafeModeBanner / SystemNoticeCard / 骨架屏
└── test/
    ├── data/models/
    │   └── ai_response_schema_test.dart        ← ✅ Schema 回归测试 (5 tests)
    ├── domain/usecases/
    │   └── apply_presence_policy_test.dart      ← ✅ 退让机制测试 (8 tests)
    └── fixtures/ai_response/
        ├── free/chat_normal.json
        ├── premium/chat_deep_context.json
        ├── abnormal/safety_red.json
        └── malformed/missing_fields.json
```

---

## 🏗️ 已完成模块 vs 待完成

| 模块 | 状态 | 说明 |
|------|------|------|
| **项目初始化** | ✅ 完成 | Flutter create + 151 dependencies |
| **A. 项目结构 & Clean Architecture** | ✅ 完成 | Core/Domain/Data/Presentation 四层 |
| **A. 状态管理 (Riverpod 2.x)** | ✅ 完成 | 全部 Provider 连线 |
| **A. DI 注入** | ✅ 完成 | injection.dart 全层级 |
| **A. 环境配置 & Feature Flags** | ✅ 完成 | dev/staging/prod + 灰度开关 |
| **B. 统一数据模型** | ✅ 完成 | 8 个实体文件，完整映射 iOS |
| **C. AI Router Protocol** | ✅ 完成 | Datasource + Schema fallback |
| **D. 订阅统一抽象** | ✅ 完成 | Repository + Provider + isPremium |
| **E. 关键页面** | ✅ 完成 | 首页/聊天/设置/订阅/个人中心 |
| **F. 退让机制** | ✅ 完成 | PresencePolicy + FollowUp |
| **F. SafeMode** | ✅ 完成 | Banner + SystemNoticeCard |
| **G. Schema 回归测试** | ✅ 完成 | 5 个测试用例 + 4 个 fixture |
| **G. Domain 单测** | ✅ 完成 | 退让机制 8 个测试用例 |
| **网络层** | ✅ 完成 | Dio + 重试 + 日志拦截器 |
| **安全存储** | ✅ 完成 | FlutterSecureStorage |
| **主题系统** | ✅ 完成 | Material 3 + 品牌色 + 季节色 |
| **H. CI/CD** | 📋 待实施 | fastlane + GitHub Actions |
| **H. 监控** | 📋 待实施 | Crashlytics + Sentry |
| **Supabase 集成** | 📋 待实施 | 用户数据持久化 |
| **StoreKit2/Google Billing 实现** | 📋 待实施 | in_app_purchase 接入 |
| **UI 集成测试** | 📋 待实施 | Widget tests |

---

## 🎯 万亿级结构落地清单

| 原则 | 实现 | 代码位置 |
|------|------|----------|
| CareStatus 三态 | ✅ `stable / needs_attention / escalate` | `care_status.dart` |
| 不做打分、不强外显 | ✅ CareStatus 仅内部使用 | Provider 层 |
| LifePhase 摘要记忆 | ✅ `LifePhaseSummary` 可清空可关闭 | `follow_up_plan.dart` |
| Presence 退让 | ✅ 3次忽略→降频，7天稳定→隐身 | `apply_presence_policy.dart` |
| 静默模式 | ✅ 用户主动开启立即生效 | 设置页 + PresenceRecord |
| SafeMode 异常优先 | ✅ 红区→不推促销→心理热线 | `SystemNoticeCard` |
| 责任边界 | ✅ 人文表述、不医疗不诊断 | 设置页责任声明 |
| 订阅措辞 | ✅ "连续照护"非"解锁功能" | `SubscriptionPage` |
| App 不直连模型 | ✅ 全部走 AI Router | `ai_router_datasource.dart` |
| Prompt 版本管理 | ✅ core/policy/task 三层 | `FeatureFlags` + 请求体 |
| Schema fallback | ✅ 解析失败→降级 | `AIResponse.fallback()` |
| 每日计划一屏 | ✅ 默认4步+折叠 | `TodayPlanSection` |

---

## ▶️ 下一步

```bash
# 启动开发
cd /Users/feifei00/Documents/shunshi/shunshi/shunshi_flutter
flutter run
```
