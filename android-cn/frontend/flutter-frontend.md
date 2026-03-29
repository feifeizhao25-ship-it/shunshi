# 顺时 ShunShi Flutter 前端专用开发提示词

你是世界级 Flutter 双端架构师、精通 Riverpod 状态管理、GoRouter路由设计、Material Design 3 的移动端专家。

你的任务是为「顺时 ShunShi」生成完整的、可直接开发的 Flutter 双端代码结构。

---

## 一、项目配置

### pubspec.yaml

```yaml
name: shunshi_app
description: 顺时 - AI生活节律系统
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # 路由
  go_router: ^13.0.0
  
  # 网络
  dio: ^5.3.3
  retrofit: ^4.0.1
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  
  # UI 组件
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  lottie: ^3.0.0
  flutter_animate: ^4.3.0
  
  # 表单
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  
  # 媒体
  image_picker: ^1.0.7
  audio_waveforms: ^1.0.5
  audioplayers: ^5.2.1
  
  # 支付
  in_app_purchase: ^3.2.0
  
  # 通知
  flutter_local_notifications: ^16.3.0
  onesignal_flutter: ^3.11.1
  
  # 工具
  intl: ^0.18.1
  uuid: ^4.2.2
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  collection: ^1.18.0
  
  # 功能
  webview_flutter: ^4.4.1
  url_launcher: ^6.2.4
  share_plus: ^7.2.1
  
  # 统计
  appsflyer_sdk: ^6.12.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  riverpod_generator: ^2.3.9
  retrofit_generator: ^7.0.0
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
    - assets/fonts/
```

---

## 二、核心架构

### 2.1 Clean Architecture 分层

```
lib/
├── main.dart
├── app.dart                    # App 入口
│
├── core/                       # 核心层
│   ├── constants/              # 常量
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   └── app_strings.dart
│   │
│   ├── theme/                  # 主题
│   │   ├── app_theme.dart
│   │   └── theme_extension.dart
│   │
│   ├── utils/                  # 工具
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── extensions.dart
│   │
│   ├── errors/                 # 错误处理
│   │   ├── exceptions.dart
│   │   └── error_handler.dart
│   │
│   └── widgets/                # 通用组件
│       ├── app_button.dart
│       ├── app_card.dart
│       ├── app_text_field.dart
│       ├── app_loading.dart
│       └── ...
│
├── data/                       # 数据层
│   ├── repositories/           # Repository 实现
│   │   ├── auth_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   ├── chat_repository_impl.dart
│   │   └── ...
│   │
│   ├── datasources/           # 数据源
│   │   ├── local/
│   │   │   ├── local_storage.dart
│   │   │   └── hive_boxes.dart
│   │   └── remote/
│   │       ├── api_client.dart
│   │       ├── api_endpoints.dart
│   │       └── interceptors.dart
│   │
│   └── models/                # 数据模型
│       ├── user/
│       │   ├── user_model.dart
│       │   └── user_model.g.dart
│       ├── chat/
│       │   ├── message_model.dart
│       │   └── ...
│       └── ...
│
├── domain/                     # 领域层
│   ├── entities/               # 实体
│   │   ├── user_entity.dart
│   │   └── ...
│   │
│   ├── repositories/           # Repository 接口
│   │   ├── i_auth_repository.dart
│   │   └── ...
│   │
│   └── usecases/              # 用例
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   └── ...
│       └── ...
│
├── presentation/               # 展示层
│   ├── providers/             # Riverpod Providers
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── chat_provider.dart
│   │   └── ...
│   │
│   ├── widgets/               # 页面组件
│   │   ├── home/
│   │   ├── chat/
│   │   ├── wellness/
│   │   ├── family/
│   │   └── profile/
│   │
│   └── pages/                 # 页面
│       ├── splash/
│       ├── auth/
│       ├── main/
│       ├── home/
│       ├── chat/
│       ├── wellness/
│       ├── family/
│       └── profile/
│
├── router/                     # 路由
│   ├── app_router.dart
│   ├── routes.dart
│   └── guards/
│       ├── auth_guard.dart
│       └── subscription_guard.dart
│
└── services/                   # 服务
    ├── notification_service.dart
    ├── voice_service.dart
    ├── audio_service.dart
    └── purchase_service.dart
```

---

## 三、状态管理 (Riverpod)

### 3.1 Provider 结构

```dart
// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  
  AuthNotifier(this._repository) : super(const AuthState());
  
  Future<void> login(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _repository.login(phone, code);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(apiClientProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// 便捷访问
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
```

### 3.2 异步 Provider

```dart
// 对话列表 Provider
final conversationListProvider = FutureProvider.family<List<Conversation>, String>((ref, userId) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getConversations(userId);
});

// 每日计划 Provider
final dailyPlanProvider = FutureProvider.family<DailyPlan, DateTime>((ref, date) async {
  final repository = ref.read(wellnessRepositoryProvider);
  return repository.getDailyPlan(date);
});
```

### 3.3 Stream Provider

```dart
// 实时消息
final messageStreamProvider = StreamProvider.family<Message, String>((ref, conversationId) {
  final repository = ref.read(chatRepositoryProvider);
  return repository.watchMessages(conversationId);
});

// 家庭动态
final familyDigestStreamProvider = StreamProvider.family<FamilyDigest, String>((ref, familyId) {
  final repository = ref.read(familyRepositoryProvider);
  return repository.watchFamilyDigest(familyId);
});
```

---

## 四、路由 (GoRouter)

### 4.1 路由配置

```dart
// router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // 启动页
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // 登录注册
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // 主页面 (5 Tab)
      ShellRoute(
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListPage(),
            ),
          ),
          GoRoute(
            path: '/wellness',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WellnessPage(),
            ),
          ),
          GoRoute(
            path: '/family',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FamilyPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      
      // 对话详情
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatDetailPage(conversationId: conversationId);
        },
      ),
      
      // 养生详情页
      GoRoute(
        path: '/solar-term/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SolarTermDetailPage(id: id);
        },
      ),
      
      // ... 其他路由
    ],
  );
});
```

### 4.2 路由守卫

```dart
// guards/auth_guard.dart
class AuthGuard extends GoRouteGuard {
  final Ref _ref;
  
  AuthGuard(this._ref) {
    asyncRedirect((state) async {
      final isAuthenticated = _ref.read(authProvider).isAuthenticated;
      
      if (!isAuthenticated) {
        return state.redirect('/login');
      }
      
      return null;
    });
  }
}

// guards/subscription_guard.dart
class SubscriptionGuard extends GoRouteGuard {
  final Ref _ref;
  
  SubscriptionGuard(this._ref) {
    asyncRedirect((state) async {
      final user = _ref.read(authProvider).user;
      
      if (user == null) {
        return state.redirect('/login');
      }
      
      // 检查会员功能
      if (state.matchedLocation.startsWith('/family') && !user.isPremium) {
        return state.redirect('/subscription');
      }
      
      return null;
    });
  }
}
```

---

## 五、通用组件

### 5.1 AppButton

```dart
// widgets/common/app_button.dart
enum AppButtonVariant { primary, secondary, ghost, text }
enum AppButtonSize { large, medium, small, mini }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    // 实现根据 variant 和 size 渲染不同样式
  }
}
```

### 5.2 AppCard

```dart
// widgets/common/app_card.dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? background;
  final BorderRadius? radius;
  final List<BoxShadow>? shadow;
  
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.background,
    this.radius,
    this.shadow,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: radius ?? AppRadius.cardRadius,
        boxShadow: shadow ?? AppShadow.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius ?? AppRadius.cardRadius,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### 5.3 ChatBubble

```dart
// widgets/chat/chat_bubble.dart
class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final List<ContentCard>? cards;
  final List<String>? followUps;
  final bool isLoading;
  
  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.cards,
    this.followUps,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text('顺'),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              // 内容卡片
              if (cards != null) ...[
                const SizedBox(height: 8),
                ...cards!.map((card) => ContentCardWidget(card: card)),
              ],
              // 跟进 chips
              if (followUps != null && followUps!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: followUps!
                      .map((text) => ActionChip(
                            label: Text(text),
                            onPressed: () {},
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person, size: 20),
          ),
        ],
      ],
    );
  }
}
```

### 5.4 ContentCard

```dart
// widgets/chat/content_card.dart
enum ContentCardType { acupoint, food, tea, movement, breathing, sleep, solarTerm, note }

class ContentCard extends StatelessWidget {
  final ContentCardType type;
  final String title;
  final String? subtitle;
  final List<String> steps;
  final int? durationMin;
  final List<String>? contraindications;
  final List<String>? cta;
  
  const ContentCard({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.steps = const [],
    this.durationMin,
    this.contraindications,
    this.cta,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标 + 标题
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      )),
                  ],
                ),
              ),
            ],
          ),
          
          // 步骤
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key + 1}. ', style: AppTypography.bodySmall),
                  Expanded(child: Text(entry.value, style: AppTypography.bodySmall)),
                ],
              ),
            )),
          ],
          
          // 时长
          if (durationMin != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('$durationMin 分钟', style: AppTypography.bodySmall),
              ],
            ),
          ],
          
          // CTA 按钮
          if (cta != null && cta!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: cta!
                  .map((text) => TextButton(
                        onPressed: () {},
                        child: Text(text),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildIcon() {
    IconData icon;
    Color color;
    
    switch (type) {
      case ContentCardType.acupoint:
        icon = Icons.self_improvement;
        color = AppColors.primary;
      case ContentCardType.food:
        icon = Icons.restaurant;
        color = AppColors.accent;
      case ContentCardType.tea:
        icon = Icons.local_cafe;
        color = AppColors.gold;
      case ContentCardType.movement:
        icon = Icons.directions_run;
        color = AppColors.blue;
      case ContentCardType.breathing:
        icon = Icons.air;
        color = AppColors.primaryLight;
      case ContentCardType.sleep:
        icon = Icons.bedtime;
        color = AppColors.primaryDark;
      case ContentCardType.solarTerm:
        icon = Icons.wb_sunny;
        color = AppColors.accent;
      case ContentCardType.note:
        icon = Icons.note;
        color = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
```

---

## 六、页面实现

### 6.1 MainPage (5 Tab)

```dart
// pages/main/main_page.dart
class MainPage extends StatefulWidget {
  final Widget child;
  
  const MainPage({super.key, required this.child});
  
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  
  final _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('首页'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.chat_outlined),
      selectedIcon: Icon(Icons.chat),
      label: Text('对话'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.spa_outlined),
      selectedIcon: Icon(Icons.spa),
      label: Text('养生'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.family_restroom_outlined),
      selectedIcon: Icon(Icons.family_restroom),
      label: Text('家庭'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('我的'),
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/chat');
            case 2: context.go('/wellness');
            case 3: context.go('/family');
            case 4: context.go('/profile');
          }
        },
        destinations: _destinations,
      ),
    );
  }
}
```

### 6.2 HomePage

```dart
// pages/home/home_page.dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dailyPlan = ref.watch(dailyPlanProvider);
    final solarTerm = ref.watch(currentSolarTermProvider);
    
    return CustomScrollView(
      slivers: [
        // 问候卡片
        SliverToBoxAdapter(
          child: GreetingCard(
            nickname: user?.nickname ?? '朋友',
            lifeStage: user?.lifeStage ?? 'exploring',
          ),
        ),
        
        // 节气卡片
        SliverToBoxAdapter(
          child: solarTerm.when(
            data: (term) => SolarTermCard(solarTerm: term),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        
        // 今日洞察
        SliverToBoxAdapter(
          child: dailyPlan.when(
            data: (plan) => TodayInsightCard(insight: plan.insight),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        
        // 今日三件事
        SliverToBoxAdapter(
          child: dailyPlan.when(
            data: (plan) => ThreeThingsCard(things: plan.threeThings),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        
        // 习惯打卡
        SliverToBoxAdapter(
          child: dailyPlan.when(
            data: (plan) => HabitChecklist(habits: plan.habits),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        
        // 家庭入口
        SliverToBoxAdapter(
          child: FamilyEntryCard(
            memberCount: user?.familyMemberCount ?? 0,
          ),
        ),
      ],
    );
  }
}
```

### 6.3 ChatDetailPage

```dart
// pages/chat/chat_detail_page.dart
class ChatDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  
  const ChatDetailPage({super.key, required this.conversationId});
  
  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isLoading = true);
    _controller.clear();
    
    try {
      await ref.read(chatProvider.notifier).sendMessage(
        conversationId: widget.conversationId,
        message: text,
      );
      
      // 滚动到底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('顺时'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => _startVoiceChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: messages.when(
              data: (msgs) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ChatBubble(
                      content: msg.content,
                      isUser: msg.role == 'user',
                      cards: msg.cards,
                      followUps: msg.followUps,
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          
          // 快捷 chips
          _buildQuickChips(),
          
          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
  }
  
  Widget _buildQuickChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          '睡眠', '情绪', '饮食', '节气', '穴位', '运动'
        ].map((chip) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(chip),
            onPressed: () {
              _controller.text = chip;
              _sendMessage();
            },
          ),
        )).toList(),
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: '和顺时聊聊...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 七、API 客户端

### 7.1 Dio 配置

```dart
// data/datasources/remote/api_client.dart
class ApiClient {
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.shunshi.com/api/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }
  
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<T>(path, queryParameters: queryParameters);
  
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _dio.post<T>(path, data: data, queryParameters: queryParameters);
  
  // ...
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.getString('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 处理 token 过期
      LocalStorage.remove('access_token');
      // 跳转登录
    }
    handler.next(err);
  }
}
```

---

## 八、本地存储

### 8.1 Hive 初始化

```dart
// data/datasources/local/hive_boxes.dart
class HiveBoxes {
  static const String user = 'user';
  static const String settings = 'settings';
  static const String cache = 'cache';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // 注册 Adapter
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());
    
    // 打开 Box
    await Hive.openBox<UserModel>(user);
    await Hive.openBox<SettingsModel>(settings);
    await Hive.openBox<dynamic>(cache);
  }
}
```

---

## 九、支付集成

### 9.1 Apple IAP

```dart
// services/purchase_service.dart
class PurchaseService {
  final InAppPurchase _purchase = InAppPurchase.instance;
  
  Future<void> initialize() async {
    await _purchase.isAvailable();
    _purchase.stream.listen(_handlePurchaseUpdate);
  }
  
  Future<bool> purchase(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    return _purchase.buyNonConsumable(purchaseParam: param);
  }
  
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased) {
        _verifyPurchase(purchase);
      }
    }
  }
  
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    // 调用后端验证
    await ApiClient.instance.post('/subscription/verify', data: {
      'receipt': purchase.verificationData.localVerificationData,
      'platform': 'ios',
    });
  }
}
```

---

## 十、通知

### 10.1 本地通知

```dart
// services/notification_service.dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shunshi_channel',
      '顺时通知',
      channelDescription: '顺时应用通知',
      importance: Importance.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details);
  }
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // 定时通知
  }
}
```
