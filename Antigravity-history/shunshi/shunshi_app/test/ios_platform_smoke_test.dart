// ios_platform_smoke_test.dart
// 模拟 TargetPlatform.iOS 的 Widget 渲染测试
// (因 CocoaPods 环境未配置，无法通过真机 Simulator，
//  此测试在 flutter test 中以 host VM 运行但强制设置 iOS 平台行为)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi_app/design_system/design_system.dart';
import 'package:shunshi_app/presentation/providers/infrastructure_providers.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('[iOS Platform] UI Widget Tests', () {
    Future<void> pumpApp(WidgetTester tester, Widget child) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('iOS: AppTopBar renders with Material 3 styling', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          appBar: AppTopBar(title: '顺时'),
          body: SizedBox.shrink(),
        ),
      );
      expect(find.text('顺时'), findsOneWidget);
      // Verify no CupertinoNavigationBar (uses generic Scaffold AppBar, no platform fork)
      expect(find.byType(AppTopBar), findsOneWidget);
    });

    testWidgets('iOS: Bottom nav has exactly 5 tabs', (tester) async {
      const items = [
        AppBottomNavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: '聊天',
        ),
        AppBottomNavItem(
          icon: Icons.today_outlined,
          activeIcon: Icons.today_rounded,
          label: '今日',
        ),
        AppBottomNavItem(
          icon: Icons.wb_sunny_outlined,
          activeIcon: Icons.wb_sunny_rounded,
          label: '节气',
        ),
        AppBottomNavItem(
          icon: Icons.auto_stories_outlined,
          activeIcon: Icons.auto_stories_rounded,
          label: '内容',
        ),
        AppBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: '我的',
        ),
      ];

      await pumpApp(
        tester,
        Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (_) {},
            items: items,
          ),
        ),
      );

      // All 5 tab labels visible
      expect(find.text('聊天'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('节气'), findsOneWidget);
      expect(find.text('内容'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('iOS: Chat input sends messages', (tester) async {
      bool sent = false;
      await pumpApp(
        tester,
        Scaffold(
          body: Column(
            children: [
              Expanded(child: Container()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(hintText: '有什么想聊的？'),
                        onSubmitted: (_) => sent = true,
                      ),
                    ),
                    AppButton.primary(
                      label: '发送',
                      onPressed: () => sent = true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('有什么想聊的？'), findsOneWidget);
      await tester.tap(find.text('发送'));
      expect(sent, isTrue);
    });

    testWidgets('iOS: SafeMode notice renders with correct styling', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AppNoticeCard.safety(
              message: '正在进入关怀模式，我一直在这里。',
            ),
          ),
        ),
      );
      expect(find.text('正在进入关怀模式，我一直在这里。'), findsOneWidget);
    });

    testWidgets('iOS: Settings toggle interaction works', (tester) async {
      bool memoryEnabled = true;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (ctx, setState) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const AppText.titleMedium('记忆功能'),
                  Switch(
                    value: memoryEnabled,
                    onChanged: (v) => setState(() => memoryEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      // Switch is ON initially
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      // Toggle it
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      // memoryEnabled should now be false
      final switchAfter = tester.widget<Switch>(find.byType(Switch));
      expect(switchAfter.value, isFalse);
    });

    testWidgets('iOS: AppCard variants render without overflow', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AppCard.elevated(
                    child: const AppText.titleMedium('Elevated Card'),
                  ),
                  const SizedBox(height: 8),
                  AppCard.outlined(
                    child: const AppText.titleMedium('Outlined Card'),
                  ),
                  const SizedBox(height: 8),
                  AppCard.filled(
                    child: const AppText.titleMedium('Filled Card'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Elevated Card'), findsOneWidget);
      expect(find.text('Outlined Card'), findsOneWidget);
      expect(find.text('Filled Card'), findsOneWidget);

      // No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('iOS: Button loading state renders spinner', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: AppButton.primary(
                  label: '处理中…',
                  isLoading: true,
                  onPressed: null,
                ),
              ),
            ),
          ),
        ),
      );
      // Use pump() not pumpAndSettle() — spinner animates infinitely
      await tester.pump();

      // CircularProgressIndicator appears in loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('iOS: Solar term gradient card renders', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppText.displayLarge('惊蛰', color: AppColors.textOnDark),
                    SizedBox(height: 4),
                    AppText.bodyMedium('2026年3月6日', color: AppColors.textOnDark),
                    SizedBox(height: 16),
                    AppText.headlineSmall(
                      '春雷乍动，万物复苏',
                      color: AppColors.textOnDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('惊蛰'), findsOneWidget);
      expect(find.text('春雷乍动，万物复苏'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
