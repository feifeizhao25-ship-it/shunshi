import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/account/account_surface.dart';
import 'package:shunshi/presentation/account/settings_account.dart';
import 'package:shunshi/presentation/pages/settings/settings_page_v2.dart';

void main() {
  test('2026-11-11 follows the solar-term table: 立冬, early winter', () {
    final line = solarTermSeasonLine(DateTime(2026, 11, 11));
    expect(line, '立冬 · 孟冬之节');
    expect(line.contains('秋'), isFalse);
  });

  test('logged out ignores a stored mock name and a paid flag', () {
    final surface = accountSurface(
      loggedIn: false,
      nickname: '云水禅心',
      membershipActive: true,
      beijingDay: DateTime(2026, 11, 11),
    );
    expect(surface.name, '未登录');
    expect(surface.membership, '未登录');
    expect(surface.seasonText, '立冬 · 孟冬之节');
  });

  test('signed-in name prefers the account record; membership matches chat labels', () {
    expect(accountNickname(userInfoJson: '{"name":"小林"}', userName: '云水禅心'), '小林');
    expect(accountNickname(userName: '小林'), '小林');
    final free = accountSurface(loggedIn: true, nickname: '小林', membershipActive: false, beijingDay: DateTime(2026, 11, 11));
    expect(free.name, '小林');
    expect(free.membership, '免费版');
    expect(free.seasonText, '立冬 · 孟冬之节');
    expect(accountSurface(loggedIn: true, nickname: '小林', membershipActive: true, beijingDay: DateTime(2026, 11, 11)).membership, '会员');
    expect(accountSurface(loggedIn: true, nickname: '小林', beijingDay: DateTime(2026, 11, 11)).membership, '状态待查询');
    expect(accountName(loggedIn: true), '顺时用户');
  });

  test('settings loader does not invent a member when logged out', () async {
    SharedPreferences.setMockInitialValues({'user_name': '云水禅心'});
    final surface = await loadSettingsAccount(beijingDay: DateTime(2026, 11, 11));
    expect(surface.name, '未登录');
    expect(surface.membership, '未登录');
    expect(surface.seasonText, '立冬 · 孟冬之节');
  });

  testWidgets('settings shows the shared lines, not 云水禅心', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => SettingsPageV2(
          loadAccount: () async => accountSurface(
            loggedIn: true,
            nickname: '小林',
            membershipActive: false,
            beijingDay: DateTime(2026, 11, 11),
          ),
        ),
      ),
      GoRoute(path: '/plan-usage', builder: (context, state) => const Scaffold(body: Text('PLAN'))),
      GoRoute(path: '/privacy', builder: (context, state) => const Scaffold(body: Text('PRIVACY'))),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('LOGIN'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('云水禅心'), findsNothing);
    expect(find.text('朋友'), findsNothing);
    expect(find.byKey(const Key('settings-account-name')), findsOneWidget);
    expect(find.text('小林'), findsOneWidget);
    expect(find.text('免费版'), findsOneWidget);
    expect(find.text('立冬 · 孟冬之节'), findsOneWidget);
  });
}
