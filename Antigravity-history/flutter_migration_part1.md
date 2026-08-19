# 顺时 Flutter 双端迁移架构文档（Part 1: 总览 + A~D）

---

## 总览架构图（文本版）

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Flutter App (iOS + Android)                   │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ Presentation│  │   Domain    │  │    Data      │  │   Core     │ │
│  │  (UI/VM)    │  │ (UseCases)  │  │ (Repo Impl) │  │ (DI/Config)│ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                │                │                │        │
│         └────────────────┴────────────────┴────────────────┘        │
│                              │                                       │
│  ┌───────────────────────────┴────────────────────────────────────┐  │
│  │              Unified Subscription Layer                        │  │
│  │    (in_app_purchase + 服务端收据验证 → UserContext.isPremium)   │  │
│  └───────────────────────────┬────────────────────────────────────┘  │
│                              │                                       │
│  ┌───────────────────────────┴────────────────────────────────────┐  │
│  │              AI Client SDK (HTTP → AI Router)                  │  │
│  │  ❌ 绝不直连模型 API  ✅ 只走 AI Router Endpoint               │  │
│  └───────────────────────────┬────────────────────────────────────┘  │
└──────────────────────────────┼───────────────────────────────────────┘
                               │ HTTPS
┌──────────────────────────────┼───────────────────────────────────────┐
│                     AI Router (服务端/Serverless)                     │
│                                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Prompt  │ │  Model   │ │  Safety  │ │  Schema  │ │   Log    │  │
│  │ Assembler│ │  Router  │ │  Filter  │ │ Validator│ │  Auditor │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                                      │
│  Prompt 三层: core_v1.2 / policy_v1.0 / task_v2.1                   │
│  模型路由: premium→qwen2.5-72B | free→qwen2.5-7B                    │
│  灰度: feature_flags + prompt_version 热切换                         │
└──────────────────────────────────────────────────────────────────────┘
```

---

## A. Flutter 项目结构与架构

### A1. 项目目录结构（Clean Architecture）

```
shunshi_flutter/
├── android/
├── ios/
├── lib/
│   ├── main.dart                          # 入口
│   ├── app.dart                           # MaterialApp 配置
│   │
│   ├── core/                              # 基础设施层
│   │   ├── config/
│   │   │   ├── app_config.dart            # 环境配置（dev/staging/prod）
│   │   │   ├── env.dart                   # 环境枚举 + baseUrl
│   │   │   └── feature_flags.dart         # 灰度开关（RemoteConfig + 本地覆写）
│   │   ├── constants/
│   │   │   ├── api_constants.dart         # API 路径常量
│   │   │   └── app_constants.dart         # 业务常量
│   │   ├── di/
│   │   │   └── injection.dart             # Riverpod ProviderScope 注册
│   │   ├── error/
│   │   │   ├── failures.dart              # Failure 基类
│   │   │   └── exceptions.dart            # Exception 定义
│   │   ├── network/
│   │   │   ├── api_client.dart            # Dio 封装（拦截器/重试/日志）
│   │   │   └── network_info.dart          # 网络状态检测
│   │   ├── storage/
│   │   │   ├── local_storage.dart         # SharedPreferences 封装
│   │   │   └── secure_storage.dart        # flutter_secure_storage
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # 主题定义（含节气动态主题）
│   │   │   ├── colors.dart                # 色彩系统
│   │   │   └── text_styles.dart           # 文字排版
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── json_utils.dart            # Schema 解析 + 降级
│   │       └── logger.dart                # 统一日志
│   │
│   ├── domain/                            # 领域层（纯 Dart，零依赖）
│   │   ├── entities/
│   │   │   ├── user.dart                  # User / UserContext
│   │   │   ├── subscription_state.dart    # SubscriptionState（统一双端）
│   │   │   ├── message.dart               # Message / Conversation
│   │   │   ├── ai_response.dart           # AIResponse（严格 Schema）
│   │   │   ├── care_status.dart           # CareStatus（stable/needs_attention/escalate）
│   │   │   ├── follow_up_plan.dart        # FollowUpPlan
│   │   │   ├── life_phase_summary.dart    # LifePhaseSummary（摘要型）
│   │   │   ├── content_item.dart          # ContentItem + MediaAsset
│   │   │   ├── solar_term.dart            # SolarTerm
│   │   │   ├── constitution.dart          # Constitution
│   │   │   └── conditioning_plan.dart     # ConditioningPlan
│   │   ├── repositories/                  # 抽象接口（不含实现）
│   │   │   ├── auth_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   ├── subscription_repository.dart
│   │   │   ├── solar_term_repository.dart
│   │   │   ├── wellness_repository.dart
│   │   │   └── content_repository.dart
│   │   └── usecases/
│   │       ├── send_message.dart
│   │       ├── generate_daily_plan.dart
│   │       ├── schedule_follow_up.dart
│   │       ├── apply_presence_policy.dart
│   │       ├── get_subscription_state.dart
│   │       └── clear_life_phase_memory.dart
│   │
│   ├── data/                              # 数据层
│   │   ├── datasources/
│   │   │   ├── remote/
│   │   │   │   ├── ai_router_datasource.dart   # AI Router HTTP 调用
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── content_remote_datasource.dart
│   │   │   └── local/
│   │   │       ├── chat_local_datasource.dart   # SQLite/Drift  本地持久化
│   │   │       ├── care_local_datasource.dart
│   │   │       └── settings_local_datasource.dart
│   │   ├── models/                        # DTO（JSON ⇄ Entity 映射）
│   │   │   ├── user_dto.dart
│   │   │   ├── chat_dto.dart
│   │   │   ├── ai_response_dto.dart
│   │   │   ├── solar_term_dto.dart
│   │   │   └── content_dto.dart
│   │   └── repositories/                  # 接口实现
│   │       ├── auth_repository_impl.dart
│   │       ├── chat_repository_impl.dart
│   │       ├── subscription_repository_impl.dart
│   │       ├── solar_term_repository_impl.dart
│   │       └── content_repository_impl.dart
│   │
│   └── presentation/                      # 表现层
│       ├── providers/                     # Riverpod Providers
│       │   ├── auth_providers.dart
│       │   ├── chat_providers.dart
│       │   ├── subscription_providers.dart
│       │   ├── home_providers.dart
│       │   ├── care_providers.dart
│       │   └── feature_flag_providers.dart
│       ├── pages/
│       │   ├── home/
│       │   │   ├── home_page.dart
│       │   │   ├── today_plan_section.dart
│       │   │   └── solar_term_card.dart
│       │   ├── chat/
│       │   │   ├── chat_page.dart
│       │   │   ├── message_bubble.dart
│       │   │   ├── content_card_widget.dart    # 穴位/食谱/运动卡
│       │   │   └── system_notice_card.dart     # SafeMode 通知卡
│       │   ├── solar_term/
│       │   │   ├── solar_term_page.dart
│       │   │   └── solar_term_journey.dart     # 7天行动游程
│       │   ├── content/
│       │   │   ├── content_library_page.dart
│       │   │   ├── content_detail_page.dart
│       │   │   └── content_search_page.dart
│       │   ├── profile/
│       │   │   ├── profile_page.dart
│       │   │   └── settings_page.dart
│       │   │       ├── care_settings_section.dart
│       │   │       ├── memory_settings_section.dart
│       │   │       └── responsibility_disclaimer.dart
│       │   └── subscription/
│       │       └── subscription_page.dart
│       ├── widgets/                       # 共享组件
│       │   ├── shimmer_loading.dart
│       │   ├── error_fallback_widget.dart
│       │   ├── safe_mode_banner.dart
│       │   └── presence_indicator.dart
│       └── router/
│           └── app_router.dart            # GoRouter 路由
│
├── test/
│   ├── domain/usecases/                   # 单测
│   ├── data/repositories/
│   ├── presentation/
│   └── fixtures/                          # JSON Schema 测试数据
│       ├── ai_response_free.json
│       ├── ai_response_premium.json
│       ├── ai_response_abnormal.json
│       └── ai_response_malformed.json
│
├── integration_test/                      # 集成测试
├── pubspec.yaml
├── analysis_options.yaml
├── .env.dev / .env.staging / .env.prod    # 不入库，CI 注入
└── fastlane/                              # 双端打包
    ├── Fastfile
    ├── Appfile
    └── Matchfile
```

### A2. 状态管理：Riverpod 2.x

**关键决策**：选择 **Riverpod 2.x（flutter_riverpod + riverpod_annotation）**

| 因素 | Riverpod | Bloc |
|------|----------|------|
| 模板代码量 | 少（code-gen） | 多（Event/State/Bloc 三文件） |
| DI 内建 | ✅ Provider 即 DI | 需额外 get_it |
| 测试便利性 | ProviderContainer 即测 | 需 mock 多层 |
| 适配 Clean Arch | ✅ 天然分层 | ✅ 但冗余 |
| 学习曲线 | 中 | 中 |

**结论**：Riverpod 在本项目的 UseCase-Repository 分层中天然作为 DI + 状态容器，减少胶水代码。

### A3. DI 方案：纯 Riverpod Providers

```dart
// lib/core/di/injection.dart

// === 基础设施 ===
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(BaseOptions(baseUrl: config.aiRouterBaseUrl))
    ..interceptors.addAll([
      AuthInterceptor(ref),
      LoggingInterceptor(),
      RetryInterceptor(retries: 2),
    ]);
});

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

// === DataSources ===
final aiRouterDatasourceProvider = Provider<AIRouterDatasource>((ref) {
  return AIRouterDatasource(ref.watch(dioProvider));
});

// === Repositories ===
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    remote: ref.watch(aiRouterDatasourceProvider),
    local: ref.watch(chatLocalDatasourceProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(ref.watch(inAppPurchaseProvider));
});

// === UseCases ===
final sendMessageUseCaseProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
});
```

### A4. 环境配置 + Feature Flags

```dart
// lib/core/config/env.dart
enum Env { dev, staging, prod }

class AppConfig {
  final Env env;
  final String aiRouterBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig.dev()
      : env = Env.dev,
        aiRouterBaseUrl = 'https://ai-router-dev.shunshi.app',
        supabaseUrl = 'https://xxx.supabase.co',
        supabaseAnonKey = 'dev-anon-key';

  const AppConfig.staging()
      : env = Env.staging,
        aiRouterBaseUrl = 'https://ai-router-staging.shunshi.app',
        supabaseUrl = 'https://xxx.supabase.co',
        supabaseAnonKey = 'staging-anon-key';

  const AppConfig.prod()
      : env = Env.prod,
        aiRouterBaseUrl = 'https://ai-router.shunshi.app',
        supabaseUrl = 'https://xxx.supabase.co',
        supabaseAnonKey = 'prod-anon-key';
}

// lib/core/config/feature_flags.dart
class FeatureFlags {
  final bool enablePresencePolicy;      // 退让机制开关
  final bool enableLifePhaseMemory;     // 阶段记忆开关
  final bool enableSafeMode;            // SafeMode 开关
  final bool enableNewDailyPlanPrompt;  // 新版 Prompt 灰度
  final String promptCoreVersion;       // "core_v1.2"
  final String promptPolicyVersion;     // "policy_v1.0"
  final String promptTaskVersion;       // "task_v2.1"

  // 从 RemoteConfig / Supabase Edge Config 加载
  factory FeatureFlags.fromRemote(Map<String, dynamic> json) { ... }

  // 本地 fallback
  factory FeatureFlags.defaults() => FeatureFlags(
    enablePresencePolicy: true,
    enableLifePhaseMemory: true,
    enableSafeMode: true,
    enableNewDailyPlanPrompt: false,
    promptCoreVersion: 'core_v1.2',
    promptPolicyVersion: 'policy_v1.0',
    promptTaskVersion: 'task_v2.1',
  );
}
```

---

## B. 统一数据模型（Dart）

### B1. UserContext

```dart
// lib/domain/entities/user.dart

enum Gender { male, female, other }

enum MembershipType { free, premium, vip }

class User {
  final String id;
  final String? phone;
  final String? nickname;
  final String? avatarUrl;
  final Gender? gender;
  final DateTime? birthDate;
  final DateTime? birthTime;
  final Location? location;
  final UserConstitution? constitution;
  final UserPreferences preferences;
  final UserStats stats;
  final Membership membership;
  final List<String> concerns;
  final String? sleepHabit;
  final String? foodPreference;
  final String? exerciseHabit;
  final DateTime createdAt;

  bool get isPremium =>
      membership.type == MembershipType.premium ||
      membership.type == MembershipType.vip;

  String get displayName => nickname ?? phone?.maskedPhone ?? '用户';
}

class UserContext {
  final String userId;
  final UserMemory memory;
  final String? currentSolarTerm;
  final String? weather;
  final String? userProfile;
  final String? currentMood;
  final DateTime? lastActiveTime;
  final bool isPremium;
  final RelationshipTier relationshipTier;
  final TimeOfDay timeOfDay;
  final SilentPeriod? silentPeriod;     // 静默时段
  final bool lifePhaseEnabled;          // 记忆开关
  final bool presencePolicyEnabled;     // 退让开关

  UserContext({
    required this.userId,
    required this.memory,
    this.currentSolarTerm,
    this.weather,
    this.userProfile,
    this.currentMood,
    this.lastActiveTime,
    this.isPremium = false,
    RelationshipTier? relationshipTier,
    this.silentPeriod,
    this.lifePhaseEnabled = true,
    this.presencePolicyEnabled = true,
  }) : relationshipTier = relationshipTier ??
            (isPremium ? RelationshipTier.premium : RelationshipTier.free),
       timeOfDay = TimeOfDay.current;
}

enum RelationshipTier { free, premium, vip }
enum TimeOfDay { morning, noon, afternoon, evening, night;
  factory TimeOfDay.current { /* 按当前小时判定 */ }
}

class SilentPeriod {
  final int startHour;  // 22
  final int endHour;    // 7
  final bool isActive;
}

class UserMemory {
  final String constitution;
  final List<String> concerns;
  final List<String> foodTaboos;
  final Map<String, String> preferences;
}
```

### B2. SubscriptionState（统一双端）

```dart
// lib/domain/entities/subscription_state.dart

enum SubscriptionPlatform { ios, android }

enum SubscriptionStatus { none, active, expired, pending, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final SubscriptionPlatform? platform;
  final String? productId;
  final DateTime? expirationDate;
  final DateTime? purchaseDate;
  final bool isTrialPeriod;
  final String? errorMessage;

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPremium => isActive;
}
```

### B3. Message / Conversation

```dart
// lib/domain/entities/message.dart

enum MessageRole { user, assistant, system }
enum MessageType { text, card, system }

class Conversation {
  final String id;
  final DateTime createdAt;
  final List<Message> messages;
  final String? lastMessage;
  final DateTime? lastMessageAt;
}

class Message {
  final String id;
  final MessageRole role;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final List<ContentCard> contentCards;     // 穴位/食谱/运动
  final List<String> followUpQuestions;
  final bool isLoading;
  final SafetyFlag? safetyFlag;            // 安全标记
}

class ContentCard {
  final String id;
  final ContentCardType type;
  final String title;
  final String description;
  final String? imageUrl;

  enum ContentCardType { recipe, acupoint, exercise, article }
}
```

### B4. AIResponse（严格 JSON Schema）

```dart
// lib/domain/entities/ai_response.dart

class AIResponse {
  final String text;
  final String tone;                        // warm / gentle / professional
  final CareStatus careStatus;
  final FollowUpPlan? followUp;
  final bool offlineEncouraged;            // 是否鼓励线下连接
  final PresenceLevel presenceLevel;
  final SafetyFlag safetyFlag;
  final List<ContentCard> contentCards;
  final List<String> followUpQuestions;

  // Schema 解析失败降级
  factory AIResponse.fallback(String rawText) => AIResponse(
    text: rawText,
    tone: 'warm',
    careStatus: CareStatus.stable,
    followUp: null,
    offlineEncouraged: false,
    presenceLevel: PresenceLevel.normal,
    safetyFlag: SafetyFlag.green,
    contentCards: [],
    followUpQuestions: [],
  );
}
```

### B5. CareStatus / FollowUpPlan / LifePhaseSummary

```dart
// lib/domain/entities/care_status.dart
enum CareStatus { stable, needsAttention, escalate }

// lib/domain/entities/follow_up_plan.dart
class FollowUpPlan {
  final int inDays;           // 几天后跟进
  final String intent;        // sleep_check / mood_review / ...
  final String topic;         // 跟进话题描述
  final DateTime scheduledAt; // 计算后的触发时间
  final bool isDismissed;     // 用户是否已忽略
}

// lib/domain/entities/life_phase_summary.dart
class LifePhaseSummary {
  final String userId;
  final String summary;              // 摘要文本（非原始记录）
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> keyTopics;      // 核心关注主题
  final CareStatus overallStatus;
  final DateTime updatedAt;
}

// lib/domain/entities/presence_level.dart
enum PresenceLevel { normal, reduced, hidden }

// lib/domain/entities/safety_flag.dart
enum SafetyFlag { green, yellow, red }
```

### B6. ContentItem / MediaAsset

```dart
// lib/domain/entities/content_item.dart

enum ContentCategory { acupoint, recipe, movement }
enum MediaType { image, video }

class ContentItem {
  final String id;
  final ContentCategory category;
  final String title;
  final String description;
  final List<MediaAsset> media;
  final List<String> contraindications;   // 禁忌提醒
  final String? solarTermTag;
  final String? constitutionTag;
  final Map<String, dynamic>? metadata;
}

class MediaAsset {
  final String id;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final int? durationSeconds;             // 视频时长
  final String? altText;
}
```

---

## C. AI Router 协议

### C1. /chat/send 请求 & 响应

**请求体**：
```json
{
  "session_id": "uuid-v4",
  "message": "最近总是睡不好",
  "user_context": {
    "user_id": "u_123",
    "is_premium": true,
    "constitution": "气虚质",
    "solar_term": "惊蛰",
    "mood": "tired",
    "relationship_tier": "premium",
    "silent_period": { "start": 22, "end": 7, "active": false },
    "life_phase_enabled": true,
    "presence_policy_enabled": true
  },
  "prompt_versions": {
    "core": "core_v1.2",
    "policy": "policy_v1.0",
    "task": "chat_v2.1"
  },
  "feature_flags": {
    "enable_safe_mode": true,
    "enable_presence_policy": true
  }
}
```

**响应体**（严格 JSON Schema）：
```json
{
  "text": "听起来最近身体有点透支了...",
  "tone": "warm",
  "care_status": "stable",
  "follow_up": {
    "in_days": 2,
    "intent": "sleep_check",
    "topic": "睡眠改善跟进"
  },
  "offline_encouraged": false,
  "presence_level": "normal",
  "safety_flag": "green",
  "content_cards": [
    {
      "type": "acupoint",
      "title": "安眠穴",
      "description": "翳风穴与风池穴连线中点...",
      "image_url": "https://cdn.shunshi.app/acupoints/anmian.jpg"
    }
  ],
  "follow_up_questions": ["最近几点入睡？", "需要一套5分钟放松练习吗？"],
  "metadata": {
    "model": "qwen2.5-72b-instruct",
    "prompt_version": { "core": "core_v1.2", "policy": "policy_v1.0", "task": "chat_v2.1" },
    "tokens": { "prompt": 1200, "completion": 350, "total": 1550 },
    "latency_ms": 2340,
    "safety_flag": "green",
    "user_tier": "premium"
  }
}
```

### C2. /dailyPlan/generate

**请求体**：
```json
{
  "user_id": "u_123",
  "is_premium": true,
  "constitution": "气虚质",
  "solar_term": "惊蛰",
  "recent_mood": "tired",
  "prompt_versions": {
    "core": "core_v1.2",
    "policy": "policy_v1.0",
    "task": "daily_plan_v1.3"
  }
}
```

**响应体**：
```json
{
  "plan_date": "2026-03-05",
  "greeting": "惊蛰将至，万物苏醒，今天我们轻轻启动身体。",
  "steps": [
    {
      "id": "step_1",
      "title": "晨起润肠",
      "detail": "一杯温蜂蜜水，顺时针揉腹3分钟",
      "time": "07:00",
      "dimension": "diet",
      "action": "diet"
    }
  ],
  "care_status": "stable",
  "tone": "warm",
  "safety_flag": "green",
  "metadata": { "model": "qwen2.5-72b-instruct", "latency_ms": 3200 }
}
```

### C3. Schema 校验失败策略

```
┌──────────────────────────────────────────────────────┐
│                  AI Router 服务端                     │
│                                                      │
│  LLM 原始输出 ──→ JSON Schema 校验                    │
│       │                    │                         │
│       │              ┌─────┴─────┐                   │
│       │         校验通过      校验失败                 │
│       │              │           │                   │
│       │         直接返回    ┌────┴────┐               │
│       │              │    可修复   不可修复            │
│       │              │      │        │               │
│       │              │  自动修补  返回 fallback        │
│       │              │  (填默认值)  + error_code      │
│       │              │      │        │               │
└──────┴──────────────┴──────┴────────┴───────────────┘
                              │
                      ┌───────┴───────┐
                 端上收到响应          │
                      │               │
                 正常 Schema      error_code？
                 按 Schema 渲染   按 AIResponse.fallback()
                                 显示纯文本 + 降级 UI
```

### C4. 模型路由策略

| 场景 | 用户 | 模型 | Temperature | MaxTokens | 理由 |
|------|------|------|-------------|-----------|------|
| 聊天对话 | Premium | qwen2.5-72B | 0.8 | 800 | Deep-Context，个性化 |
| 聊天对话 | Free | qwen2.5-7B | 0.7 | 500 | 快速基础回复 |
| 每日计划 | Premium | qwen2.5-72B | 0.7 | 1200 | 深度洞察 |
| 每日计划 | Free | qwen2.5-7B | 0.6 | 600 | 简洁行动建议 |
| 安全检测 | All | qwen2.5-7B | 0.1 | 200 | 确定性判断，省 token |
| Schema 修补 | All | qwen2.5-7B | 0.0 | 300 | 结构化修补，低温更可靠 |

> **"省 token 但更可靠"策略**：安全检测、Schema 修补等结构化任务使用 7B + 低温，因为此类任务不需要创意性输出，小模型 + 低温反而更稳定、更快、更省成本。关键对话用 72B 确保内容深度。

---

## D. 订阅统一抽象

### D1. 插件选型

| 插件 | 优势 | 劣势 |
|------|------|------|
| **in_app_purchase** (官方) | Flutter 团队维护，双端统一 | API 较底层 |
| revenue_cat | 开箱即用 | 第三方依赖/费用 |

**选择 `in_app_purchase`**（官方插件），理由：
- 已有 StoreKit2 经验可复用
- Android 端 Google Play Billing 也原生支持
- 服务端收据验证由自有后端控制，不依赖第三方

### D2. 统一 SubscriptionRepository 接口

```dart
// lib/domain/repositories/subscription_repository.dart

abstract class SubscriptionRepository {
  /// 查询当前权益（isPremium + 到期时间）
  Future<SubscriptionState> getEntitlement();

  /// 实时监听订阅状态变更
  Stream<SubscriptionState> listenEntitlement();

  /// 发起购买
  Future<SubscriptionState> purchase(String productId);

  /// 恢复购买
  Future<SubscriptionState> restore();

  /// 查询可购买商品列表
  Future<List<SubscriptionProduct>> getProducts();
}

class SubscriptionProduct {
  final String id;           // "shunshi_premium_monthly"
  final String title;
  final String description;
  final String price;        // 格式化后的价格字符串
  final String currencyCode;
}
```

### D3. 订阅态注入 UserContext.isPremium 的时机

```
┌──────────────────────────────────────────────────────┐
│ 冷启动                                               │
│  App启动 → 读本地缓存 isPremium → 注入 UserContext    │
│        → 异步请求服务端校验 → 更新缓存 + UserContext    │
│                                                      │
│ 前台恢复                                              │
│  App回前台 → 触发 listenEntitlement() 刷新            │
│           → 状态变更 → 广播 UserContext 更新           │
│                                                      │
│ 购买回调                                              │
│  purchase() 成功 → 服务端验证收据 → 确认后             │
│                 → 更新本地缓存 + UserContext            │
│                 → 通知 Riverpod 重新构建相关 Provider   │
└──────────────────────────────────────────────────────┘
```

```dart
// lib/presentation/providers/subscription_providers.dart

final subscriptionStateProvider = StreamProvider<SubscriptionState>((ref) {
  return ref.watch(subscriptionRepositoryProvider).listenEntitlement();
});

final isPremiumProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionStateProvider);
  return sub.valueOrNull?.isPremium ?? false;
});

// 任何需要 isPremium 的地方直接 ref.watch(isPremiumProvider)
```

### D4. 防止状态不同步的兜底方案

1. **服务端收据验证**：所有购买完成后，客户端将 receipt/purchaseToken 发送到自有后端验证，后端写入数据库。
2. **双重来源**：客户端本地缓存 + 服务端 `GET /user/entitlement` 对账。
3. **定时校验**：每次 App 进前台 + 每 4 小时后台校验一次。
4. **乐观降级**：本地有缓存则信任，服务端校验失败不立即降级，而是标记 `needsRevalidation`，连续 3 次失败才降级。

```dart
// lib/data/repositories/subscription_repository_impl.dart

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final InAppPurchase _iap;
  final ApiClient _api;
  final LocalStorage _storage;

  @override
  Future<SubscriptionState> getEntitlement() async {
    // 1. 本地缓存优先（冷启动快）
    final cached = await _storage.getSubscriptionState();
    if (cached != null && !cached.needsRevalidation) return cached;

    // 2. 平台原生查询
    final nativeState = await _queryNativeEntitlement();

    // 3. 服务端对账
    try {
      final serverState = await _api.get('/user/entitlement');
      final verified = _mergeStates(nativeState, serverState);
      await _storage.saveSubscriptionState(verified);
      return verified;
    } catch (_) {
      // 服务端不可达，信任本地
      return nativeState;
    }
  }
}
```
