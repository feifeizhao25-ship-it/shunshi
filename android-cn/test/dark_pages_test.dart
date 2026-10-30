import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/design_system/theme.dart';
import 'package:shunshi/presentation/pages/growth/growth_milestones_page.dart';
import 'package:shunshi/presentation/pages/library/wellness_library_page.dart';
import 'package:shunshi/presentation/pages/meditation/meditation_focus_page.dart';

/// 文库 / 冥想 / 成长 三个页面：深色模式下不能再出现浅色写死的底色和文字色。
void main() {
  final pages = <String, Widget Function()>{
    '文库': () => const WellnessLibraryPage(),
    '成长': () => const GrowthMilestonesPage(),
    '冥想': () => const MeditationFocusPage(),
  };

  Future<void> pump(WidgetTester tester, Widget page, ThemeMode mode) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ShunShiTheme.lightTheme,
      darkTheme: ShunShiTheme.darkTheme,
      themeMode: mode,
      home: page,
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final entry in pages.entries) {
    testWidgets('${entry.key}页深色模式用深色底，文字不是浅色写死的颜色', (tester) async {
      await pump(tester, entry.value(), ThemeMode.dark);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, ShunShiColors.darkBackground);
      final lightOnly = {
        ShunShiColors.textPrimary,
        ShunShiColors.textSecondary,
        ShunShiColors.textTertiary,
        ShunShiColors.surfaceContainerLow,
        ShunShiColors.surfaceContainerLowest,
      };
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(lightOnly.contains(t.style?.color), isFalse, reason: '深色模式下文字「${t.data}」仍用了浅色主题的颜色');
      }
    });

    testWidgets('${entry.key}页浅色模式保持原来的浅色底', (tester) async {
      await pump(tester, entry.value(), ThemeMode.light);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, ShunShiColors.background);
    });
  }
}
