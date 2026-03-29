import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/seasons/seasons_page.dart';
import '../../presentation/pages/library/library_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/settings/privacy_settings_page.dart';
import '../../presentation/pages/audio/audio_player_page.dart';
import '../../presentation/pages/settings/help_center_page.dart';
import '../../presentation/pages/chat/chat_page.dart';
import '../../presentation/pages/content/content_detail_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/reflection/reflection_page.dart';
import '../../presentation/pages/subscription/subscription_page.dart';
import '../../presentation/pages/records/records_page.dart';
import '../../presentation/widgets/shell/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
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

      // ── Login (reserved) ─────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Standalone pages (outside Shell) ─────────────────
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
        path: '/subscribe',
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
        path: '/audio/:id',
        builder: (context, state) {
          final audioId = state.pathParameters['id'] ?? '';
          return AudioPlayerPage(audioId: audioId);
        },
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpCenterPage(),
      ),

      // ── Main Shell — 5 Tab bottom navigation ─────────────
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
              child: SeasonsPage(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryPage(),
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
    // Splash handles onboarding redirect via context.go()
    // No sync redirect needed here — splash page navigates after delay
  );
}


