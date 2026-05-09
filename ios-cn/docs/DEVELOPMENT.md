# DEVELOPMENT.md - 顺时中国版 开发指南

## 项目概述

- **项目名称**：shunshi（顺时）
- **技术栈**：Flutter 3.x + Riverpod + GoRouter + Freezed
- **目标平台**：iOS 12.0+ / Android API 21+
- **定位**：中医养生 AI 陪伴 App（中国市场版）

---

## 技术架构总览

```
┌─────────────────────────────────────────────┐
│                   Flutter App               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Riverpod │  │  GoRouter │  │ Freezed  │  │
│  │ 状态管理  │  │  路由导航  │  │ 数据模型 │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
                    │ HTTP / WebSocket
                    ▼
┌─────────────────────────────────────────────┐
│          顺时后端 API (FastAPI)              │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌───────┐  │
│  │ Auth   │ │ Chat/AI │ │Wellness│ │ Sub  │  │
│  └────────┘ └────────┘ └────────┘ └───────┘  │
└─────────────────────────────────────────────┘
```

---

## 目录结构

```
shunshi/
├── lib/
│   ├── main.dart                 # 入口文件
│   ├── app.dart                  # MaterialApp 配置
│   │
│   ├── core/                     # 核心层
│   │   ├── constants/
│   │   │   ├── app_colors.dart   # Color Tokens（青绿主色系）
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_radius.dart
│   │   │   └── app_strings.dart  # 静态中文文案
│   │   ├── theme/
│   │   │   ├── app_theme.dart    # ThemeData
│   │   │   └── theme_extension.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart   # 节气计算、农历
│   │   │   ├── string_utils.dart
│   │   │   └── validators.dart
│   │   ├── extensions/
│   │   │   └── context_extensions.dart
│   │   └── errors/
│   │       ├── exceptions.dart
│   │       └── error_handler.dart
│   │
│   ├── data/                     # 数据层
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── user_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   ├── wellness_repository.dart
│   │   │   ├── family_repository.dart
│   │   │   └── subscription_repository.dart
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── local_storage.dart  # SharedPreferences
│   │   │   │   └── hive_boxes.dart
│   │   │   └── remote/
│   │   │       ├── api_client.dart     # Dio HTTP 客户端
│   │   │       ├── api_endpoints.dart  # API 路由常量
│   │   │       └── interceptors.dart  # 拦截器（Auth/Error）
│   │   └── models/                 # Freezed 模型
│   │       ├── user/
│   │       ├── chat/
│   │       ├── wellness/          # 体质/节气/穴位/食疗/茶饮
│   │       ├── family/
│   │       └── subscription/
│   │
│   ├── domain/                   # 领域层
│   │   ├── entities/
│   │   └── providers/           # Riverpod providers
│   │
│   ├── presentation/             # UI 层
│   │   ├── pages/
│   │   │   ├── onboarding/
│   │   │   ├── home/
│   │   │   ├── chat/
│   │   │   ├── solar_term/
│   │   │   ├── wellness/
│   │   │   ├── profile/
│   │   │   ├── subscription/
│   │   │   └── settings/
│   │   ├── widgets/
│   │   │   ├── cards/
│   │   │   ├── buttons/
│   │   │   └── dialogs/
│   │   └── router/
│   │       └── app_router.dart   # GoRouter 配置
│   │
│   └── core/router/
│       └── app_router.dart
│
├── backend/                      # Python FastAPI 后端
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── api/v1/
│   │   │   ├── auth/
│   │   │   ├── chat/
│   │   │   ├── wellness/
│   │   │   ├── family/
│   │   │   └── subscription/
│   │   ├── core/
│   │   └── ai/
│   │       ├── router.py
│   │       ├── intent_detector.py
│   │       ├── safety_guard.py
│   │       └── skills/
│   └── requirements.txt
│
├── integration_test/             # Flutter 集成测试
├── test/                         # 单元测试
├── testing/                      # QA 文档
└── docs/                         # 项目文档（本目录）
```

---

## 核心模块说明

### 状态管理 — Riverpod

所有状态通过 Riverpod 管理，典型模式：

```dart
// 定义 StateNotifier
class HomeState {
  final bool isLoading;
  final DashboardModel? dashboard;
  final String? error;
}

class HomeNotifier extends StateNotifier<HomeState> {
  final UserRepository _userRepo;
  final WellnessRepository _wellnessRepo;

  HomeNotifier(this._userRepo, this._wellnessRepo) : super(HomeState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await Future.wait([
        _userRepo.getProfile(),
        _wellnessRepo.getDailyPlan(),
      ]);
      state = state.copyWith(isLoading: false, dashboard: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.read(userRepositoryProvider), ref.read(wellnessRepositoryProvider));
});
```

### 路由 — GoRouter

```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashPage()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingPage()),
    GoRoute(path: '/login', builder: (_, __) => LoginPage()),
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => HomePage()),
        GoRoute(path: '/chat', builder: (_, __) => ChatPage()),
        GoRoute(path: '/seasons', builder: (_, __) => SolarTermPage()),
        GoRoute(path: '/library', builder: (_, __) => WellnessPage()),
        GoRoute(path: '/profile', builder: (_, __) => ProfilePage()),
      ],
    ),
    GoRoute(path: '/reflection', builder: (_, __) => ReflectionPage()),
    GoRoute(path: '/subscribe', builder: (_, __) => SubscriptionPage()),
  ],
);
```

### API 客户端

```dart
class ApiClient {
  final Dio _dio;
  final LocalStorage _local;

  ApiClient(this._local) : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        final token = _local.getString('access_token');
        if (token != null) opts.headers['Authorization'] = 'Bearer $token';
        return handler.next(opts);
      },
      onError: (err, handler) {
        if (err.response?.statusCode == 401) {
          // 跳转登录
        }
        return handler.next(err);
      },
    ));
  }
}
```

---

## 开发环境配置

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 配置 API 地址

开发环境默认连接 `http://localhost:8000`，可在 `lib/core/constants/api_config.dart` 修改。

### 3. 运行应用

```bash
# iOS 模拟器
flutter run -d <simulator_id>

# Android 模拟器
flutter run -d <emulator_id>

# Web
flutter run -d chrome
```

### 4. 代码生成

部分模型使用 Freezed，需运行：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 中国市场特殊配置

### 第三方 SDK 集成

| 功能 | SDK | 配置 |
|------|-----|------|
| 登录 | 微信 OpenSDK | `ios/wechat` |
| 支付 | 微信支付 / 支付宝 | `android/app/build.gradle` |
| 推送 | 极光 / 华为 Push | `android/app` |
| 统计 | 友盟 | `android/umeng` |

### 隐私合规

- App 首次启动需展示隐私政策弹窗
- 位置权限用于半球感知（非必须）
- 相机/相册权限用于头像上传

---

## 主要功能清单

| 模块 | 功能 | 状态 |
|------|------|------|
| Onboarding | 7步引导（生命阶段/体质/风格偏好）| ✅ |
| Home Dashboard | 每日洞察 + 3条建议卡片 | ✅ |
| AI Chat | AI 陪伴对话（节气/食疗/穴位/情绪）| ✅ |
| Solar Term | 24节气内容展示 | ✅ |
| Wellness | 食疗/穴位/运动/茶饮内容库 | ✅ |
| Reflection | 每日情绪/能量/睡眠记录 | ✅ |
| Profile | 使用统计 + 健康记录 | ✅ |
| Subscription | 免费/养心计划/家庭计划 | ✅ |
| Settings | 半球切换/隐私政策/账号管理 | ✅ |

---

## 调试技巧

```bash
# 查看详细日志
flutter run --verbose

# 清理并重新构建
flutter clean && flutter pub get && flutter run

# 运行测试
flutter test

# 运行集成测试
flutter test integration_test/app_test.dart
```
