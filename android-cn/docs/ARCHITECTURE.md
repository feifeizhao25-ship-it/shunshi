# ARCHITECTURE.md - 顺时中国版 架构文档

## 整体架构

```
┌──────────────────────────────────────────────────────────────────┐
│                        用户设备 (iOS / Android)                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    Flutter App                            │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐  │    │
│  │  │ Riverpod │  │ GoRouter │  │ Freezed  │  │ Dio     │  │    │
│  │  │ 状态管理  │  │ 路由导航  │  │ 数据模型  │  │ HTTP   │  │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘  │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                               │ HTTP / WebSocket
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                     顺时后端 (FastAPI)                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Auth API │  │ Chat/AI   │  │ Wellness  │  │ Subscription │   │
│  │ /users   │  │ /chat     │  │ /wellness │  │ /subscription│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              AI Router (Intent + Skills + LLM)          │    │
│  │  IntentDetector → SafetyGuard → SkillRouter → LLM       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────┐  ┌────────────────┐  ┌───────────────────┐   │
│  │  PostgreSQL   │  │     Redis      │  │  MinIO / 阿里OSS   │   │
│  │  用户/内容数据 │  │  会话/缓存     │  │   音频/图片存储    │   │
│  └──────────────┘  └────────────────┘  └───────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 数据流

### 用户首次打开 App

```
用户操作          系统响应
─────────────────────────────────────────────────
App 启动
  │
  ├─→ SplashPage (显示品牌动画 1.5s)
  │         │
  │         ▼
  ├─→ 检查 SharedPreferences['onboarding_completed']
  │         │
  │    ┌────┴────┐
  │    │  未完成  │───────────────────→ OnboardingPage (7步)
  │    │  已完成  │
  │    └────┬────┘
  │         ▼
  │    HomePage ──→ POST /onboarding/complete ──→ 显示 Dashboard
```

### AI 对话流程

```
用户输入消息
     │
     ▼
┌─────────────────────┐
│  SafetyGuard        │──高风险内容──→ SafeMode 响应（显示危机帮助）
│  (安全检查)         │
└─────────────────────┘
     │正常
     ▼
┌─────────────────────┐
│  IntentDetector     │──→ sleep ──→ SleepWindDownSkill
│  (意图识别)         │──→ emotion ─→ MoodFirstAidSkill
│                     │──→ food ──→ FoodTeaRecommenderSkill
│                     │──→ solar_term ─→ SolarTermGuideSkill
│                     │──→ general ─→ DefaultChatSkill
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  LLM (通义千问/     │
│    百度文心/智谱)    │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  响应格式化         │
│  (text + cards +    │
│   follow_up)        │
└─────────────────────┘
     │
     ▼
ChatPage (展示消息)
```

---

## 分层架构

### 核心层 (core/)

| 文件 | 职责 |
|------|------|
| `constants/app_colors.dart` | 颜色 Token，与 round2-design-system.md 一致 |
| `constants/app_typography.dart` | 字体 Token |
| `theme/app_theme.dart` | Material ThemeData，统一主题 |
| `errors/exceptions.dart` | 自定义异常类 |
| `errors/error_handler.dart` | 全局错误处理 |

### 数据层 (data/)

```
data/
├── repositories/        # 业务数据聚合
│   ├── auth_repository.dart       # 认证相关
│   ├── user_repository.dart       # 用户数据
│   ├── chat_repository.dart       # 对话管理
│   └── wellness_repository.dart   # 养生内容
│
├── datasources/
│   ├── local/local_storage.dart   # SharedPreferences 封装
│   └── remote/
│       ├── api_client.dart        # Dio HTTP 客户端
│       └── api_endpoints.dart     # API 路由常量
│
└── models/              # Freezed 不可变数据模型
    ├── user/user_model.dart
    ├── chat/message_model.dart
    └── wellness/solar_term_model.dart
```

### 领域层 (domain/)

```
domain/
├── entities/            # 纯 Dart 领域实体（可选）
└── providers/           # Riverpod StateNotifier
    ├── auth_provider.dart
    ├── home_provider.dart
    ├── chat_provider.dart
    └── wellness_provider.dart
```

### 展示层 (presentation/)

```
presentation/
├── pages/               # 完整页面
│   ├── home/home_page.dart
│   ├── chat/chat_page.dart
│   ├── onboarding/onboarding_page.dart
│   └── ...
├── widgets/             # 可复用组件
│   ├── cards/suggestion_card.dart
│   ├── dialogs/insight_dialog.dart
│   └── buttons/gradient_button.dart
└── router/app_router.dart  # GoRouter 路由配置
```

---

## 路由结构

| 路径 | 页面 | Shell |
|------|------|-------|
| `/splash` | SplashPage | ❌ |
| `/onboarding` | OnboardingPage (7步) | ❌ |
| `/login` | LoginPage | ❌ |
| `/home` | HomePage | ✅ |
| `/chat` | ChatPage | ✅ |
| `/seasons` | SolarTermPage | ✅ |
| `/library` | WellnessPage | ✅ |
| `/profile` | ProfilePage | ✅ |
| `/reflection` | ReflectionPage | ❌ |
| `/subscribe` | SubscriptionPage | ❌ |
| `/settings` | SettingsPage | ❌ |
| `/records` | RecordsPage | ❌ |

---

## 设计系统（Color Tokens）

来自 round2-design-system.md：

```dart
class AppColors {
  // 主色 - 青绿系
  static const Color primary       = Color(0xFF4A7C6F);
  static const Color primaryLight  = Color(0xFF6B9E8F);
  static const Color primaryDark   = Color(0xFF2D5A4D);

  // 背景 - 米白系
  static const Color background    = Color(0xFFFAF8F5);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVariant= Color(0xFFF5F2ED);

  // 点缀色
  static const Color accent        = Color(0xFFE8A87C);   // 暖橙
  static const Color gold          = Color(0xFFD4B896);
  static const Color blue          = Color(0xFF8EB8C9);

  // 文字
  static const Color textPrimary   = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // 状态色（柔和，不过度使用红色）
  static const Color success = Color(0xFF6B9E8F);
  static const Color warning = Color(0xFFE8A87C);
  static const Color error   = Color(0xFFD4726A);
  static const Color info    = Color(0xFF8EB8C9);
}
```

---

## 半球感知逻辑

中国属北半球，App 内置半球感知：

```dart
// 北半球节气计算（简化）
String getSolarTerm(DateTime date) {
  // 3月惊蛰: 3月5日±1
  if (_inRange(date, 3, 4, 6)) return '惊蛰';
  // 3月春分: 3月20日±1
  if (_inRange(date, 3, 19, 21)) return '春分';
  // ...
}

// 南半球则取相反季节
String getHemisphereSeason(String northSeason) {
  return switch (northSeason) {
    'spring' => 'autumn',
    'summer' => 'winter',
    'autumn' => 'spring',
    'winter' => 'summer',
    _ => northSeason,
  };
}
```

---

## 关键设计决策

1. **为什么用 Riverpod**：Flutter 官方推荐的异步状态管理方案，社区生态成熟，支持代码生成
2. **为什么用 GoRouter**：Flutter 官方路由方案，支持深层链接和路径参数
3. **为什么用 Freezed**：不可变数据类，减少 null 安全错误，支持 copyWith
4. **不采用 BLoC**：Riverpod 更轻量，代码更简洁
