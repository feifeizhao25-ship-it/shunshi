import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/home/elder_home_text.dart';
import 'package:shunshi/presentation/widgets/shell/main_shell.dart';

Widget _app() {
  final router = GoRouter(initialLocation: '/today', routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        for (final p in ['/chat', '/today', '/solar', '/wellness', '/profile'])
          GoRoute(path: p, builder: (_, __) => const SizedBox.shrink()),
      ],
    ),
  ]);
  return MaterialApp.router(routerConfig: router);
}

double _labelSize(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.text(label));
  return text.style?.fontSize ?? DefaultTextStyle.of(tester.element(find.text(label))).style.fontSize!;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('长辈模式下底部导航字放大，「今日」不被中间按钮压住（问题 10）', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    ElderModeState.set(false);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_labelSize(tester, '聊天'), 10);
    expect(_labelSize(tester, '今日'), 10);

    ElderModeState.set(true);
    await tester.pumpAndSettle();
    for (final l in ['聊天', '今日', '节气', '养生', '我的']) {
      expect(_labelSize(tester, l), ElderModeState.navLabelSize, reason: l);
    }
    final icon = tester.getRect(find.byIcon(Icons.wb_sunny));
    final label = tester.getRect(find.text('今日'));
    expect(label.top, greaterThanOrEqualTo(icon.bottom));
    expect(tester.takeException(), isNull);
    ElderModeState.set(false);
  });
}
