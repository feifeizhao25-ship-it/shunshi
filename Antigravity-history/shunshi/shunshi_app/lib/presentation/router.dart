import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/chat_page.dart';
import 'pages/content_detail_page.dart';
import 'pages/content_library_page.dart';
import 'pages/daily_plan_page.dart';
import 'pages/me_settings_page.dart';
import 'pages/solar_term_page.dart';
import 'pages/subscribe_page.dart';
import 'shell_page.dart';

final router = GoRouter(
  initialLocation: '/chat',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => _noTransitionPage(
            state,
            child: const ChatPage(),
          ),
        ),
        GoRoute(
          path: '/daily',
          pageBuilder: (context, state) => _noTransitionPage(
            state,
            child: const DailyPlanPage(),
          ),
        ),
        GoRoute(
          path: '/solar-term',
          pageBuilder: (context, state) => _noTransitionPage(
            state,
            child: const SolarTermPage(),
          ),
        ),
        GoRoute(
          path: '/content',
          pageBuilder: (context, state) => _noTransitionPage(
            state,
            child: const ContentLibraryPage(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => ContentDetailPage(
                contentId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/me',
          pageBuilder: (context, state) => _noTransitionPage(
            state,
            child: const MeSettingsPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/subscribe',
      builder: (context, state) => const SubscribePage(),
    ),
  ],
);

NoTransitionPage<void> _noTransitionPage(GoRouterState state, {required Widget child}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}
