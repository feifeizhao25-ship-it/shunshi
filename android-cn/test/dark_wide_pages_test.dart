import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/design_system/theme.dart';
import 'package:shunshi/presentation/pages/library/wellness_library_page.dart';
import 'package:shunshi/presentation/pages/library/library_page.dart';
import 'package:shunshi/presentation/pages/meditation/meditation_library_page.dart';
import 'package:shunshi/presentation/pages/growth/growth_milestones_page.dart';

/// 文库 / 冥想 / 成长：深色模式 + 1024 / 1440 宽屏下不能残留浅色主题写死的底色和文字色。
void main() {
  final pages = <String, Widget Function()>{
    '文库': () => const WellnessLibraryPage(),
    '文库首页': () => const LibraryPage(),
    '冥想': () => const MeditationLibraryPage(),
    '成长': () => const GrowthMilestonesPage(),
  };
  final lightText = <Color>{
    ShunShiColors.textPrimary,
    ShunShiColors.textSecondary,
    ShunShiColors.textTertiary,
  };
  final lightSurface = <Color>{
    ShunShiColors.surface,
    ShunShiColors.textPrimary,
    ShunShiColors.textSecondary,
    ShunShiColors.textTertiary,
    ShunShiColors.surfaceContainerLow,
    ShunShiColors.surfaceContainerLowest,
  };

  Future<void> pump(WidgetTester tester, Widget page, double width, ThemeMode mode) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ShunShiTheme.lightTheme,
      darkTheme: ShunShiTheme.darkTheme,
      themeMode: mode,
      home: page,
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final width in [1024.0, 1440.0]) {
    for (final e in pages.entries) {
      testWidgets('${e.key} 深色 @${width.toInt()}', (tester) async {
        await pump(tester, e.value(), width, ThemeMode.dark);
        final bg = tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
        expect(bg, isNotNull);
        expect(bg!.computeLuminance() < 0.2, isTrue, reason: '深色模式底色过亮: $bg');
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          expect(lightText.contains(t.style?.color), isFalse, reason: '文字「${t.data}」仍用浅色主题颜色');
        }
        for (final c in tester.widgetList<Container>(find.byType(Container))) {
          final dec = c.decoration;
          final col = dec is BoxDecoration ? dec.color : c.color;
          expect(lightSurface.contains(col), isFalse, reason: '卡片底色仍是浅色主题颜色 $col');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      });
      testWidgets('${e.key} 浅色 @${width.toInt()}', (tester) async {
        await pump(tester, e.value(), width, ThemeMode.light);
        final bg = tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
        expect(bg == null || bg.computeLuminance() > 0.5, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      });
    }
  }
}
