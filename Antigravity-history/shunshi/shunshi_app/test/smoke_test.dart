import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi_app/design_system/design_system.dart';
import 'package:shunshi_app/presentation/providers/infrastructure_providers.dart';

/// Smoke test: App initialization + basic page routing
void main() {
  SharedPreferences.setMockInitialValues({});

  Future<Widget> buildTestApp() async {
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/chat',
      routes: [
        GoRoute(
          path: '/chat',
          builder: (_, __) => const Scaffold(
            body: Center(child: AppText.bodyMedium('Chat Page')),
          ),
        ),
        GoRoute(
          path: '/daily',
          builder: (_, __) => const Scaffold(
            body: Center(child: AppText.bodyMedium('Daily Plan')),
          ),
        ),
        GoRoute(
          path: '/me',
          builder: (_, __) => const Scaffold(
            body: Center(child: AppText.bodyMedium('Settings')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }

  testWidgets('App starts on chat route', (tester) async {
    final app = await buildTestApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Chat Page'), findsOneWidget);
  });

  testWidgets('Can navigate to daily plan route', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/daily',
      routes: [
        GoRoute(
          path: '/daily',
          builder: (_, __) => const Scaffold(
            body: Center(child: AppText.bodyMedium('Daily Plan')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily Plan'), findsOneWidget);
  });

  testWidgets('AppTheme builds without error', (tester) async {
    final theme = buildAppTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  testWidgets('AppText renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              AppText.headlineLarge('大标题'),
              AppText.bodyMedium('正文内容'),
              AppText.labelSmall('小标签'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('大标题'), findsOneWidget);
    expect(find.text('正文内容'), findsOneWidget);
    expect(find.text('小标签'), findsOneWidget);
  });

  testWidgets('AppButton renders and is tappable', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AppButton.primary(
            label: '测试按钮',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试按钮'), findsOneWidget);
    await tester.tap(find.text('测试按钮'));
    expect(tapped, isTrue);
  });

  testWidgets('AppNoticeCard safety type renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: AppNoticeCard.safety(
            message: '这是一个安全提示',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('这是一个安全提示'), findsOneWidget);
  });
}
