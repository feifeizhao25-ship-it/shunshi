import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/settings/settings_page_v2.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GoRouter> pumpSettings(WidgetTester t) async {
    t.view.physicalSize = const Size(900, 2600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(path: '/settings', builder: (c, s) => const SettingsPageV2()),
      GoRoute(path: '/plan-usage', builder: (c, s) => const Scaffold(body: Text('PLAN-USAGE-ROUTE'))),
      GoRoute(path: '/culture-settings', builder: (c, s) => const Scaffold(body: Text('CULTURE-ROUTE'))),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    return router;
  }

  testWidgets('settings has a Plan & usage entry that opens the page', (t) async {
    await pumpSettings(t);
    final tile = find.text('套餐与用量');
    expect(tile, findsOneWidget);
    await t.tap(tile);
    await t.pumpAndSettle();
    expect(find.text('PLAN-USAGE-ROUTE'), findsOneWidget);
  });
}
