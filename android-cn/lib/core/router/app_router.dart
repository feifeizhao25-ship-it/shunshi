import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/chat_page.dart';
import '../../presentation/pages/solar_term_page.dart';
import '../../presentation/pages/wellness_page.dart';
import '../../presentation/pages/profile_page.dart';
import '../../presentation/pages/reflection/reflection_page.dart';
import '../../presentation/pages/subscription/subscription_page.dart';
import '../../presentation/pages/content_detail_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/records_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/wellness/constitution_page.dart';
import '../../presentation/pages/wellness/boundaries_page.dart';
import '../../presentation/pages/wellness/wellness_category_page.dart';
import '../../presentation/pages/family/family_page.dart';
import '../../presentation/pages/solar/solar_term_detail_page.dart';
import '../../presentation/widgets/shell/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // 防止从 Shell 内页面返回时回到 splash 或 onboarding
      // GoRouter 按返回键时默认 pop 路由，如果回到 splash 会黑屏
      // 这里不做强制 redirect，让 splash 自己处理导航
      // PopScope 在 MainShell 中阻止 shell 内页面的返回
      return null;
    },
    routes: [
      // ── Splash ───────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Onboarding ───────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Login (预留) ────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── 独立全屏页面（不在 Shell 内） ─────────────────────
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final conversationId = state.uri.queryParameters['conversation_id'];
          return ChatPage(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/reflection',
        builder: (context, state) => const ReflectionPage(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/content/:id',
        builder: (context, state) {
          final contentId = state.pathParameters['id']!;
          return ContentDetailPage(contentId: contentId);
        },
      ),
      GoRoute(
        path: '/records',
        builder: (context, state) => const RecordsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/boundaries',
        builder: (context, state) => const BoundariesPage(),
      ),
      GoRoute(
        path: '/constitution',
        builder: (context, state) => const ConstitutionPage(),
      ),
      GoRoute(
        path: '/wellness-category/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'food_therapy';
          return WellnessCategoryPage(type: type);
        },
      ),
      GoRoute(
        path: '/solar-term-detail/:name',
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '春分';
          final season = state.uri.queryParameters['season'];
          return SolarTermDetailPage(termName: name, season: season);
        },
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyPage(),
      ),

      // ── Main Shell — 5 Tab 底部导航 ─────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/companion',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatPage(),
            ),
          ),
          GoRoute(
            path: '/seasons',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SolarTermPage(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WellnessPage(),
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
    ],
    // Splash page handles onboarding redirect via context.go()
    // No sync redirect needed here — splash navigates after delay
  );
}


