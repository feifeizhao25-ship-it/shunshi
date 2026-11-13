import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/settings/settings_page_v2.dart';

void main() {
  testWidgets('设置里可以关掉个性化推荐，保存失败会改回去', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final saved = <bool>[];
    var fail = false;
    await tester.pumpWidget(MaterialApp(
      home: SettingsPageV2(
        loadAccount: () async => throw StateError('skip'),
        loadPersonalization: () async => true,
        savePersonalization: (value) async {
          if (fail) throw StateError('down');
          saved.add(value);
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('个性化推荐'), findsOneWidget);
    expect(find.textContaining('卡片和大家看到的一样'), findsOneWidget);
    final latin = RegExp(r'[A-Za-z]');
    expect(latin.hasMatch('关掉之后，首页不再按你的目标和地区来排，卡片和大家看到的一样。'), isFalse);

    await tester.tap(find.byKey(const Key('settings-personalization')));
    await tester.pumpAndSettle();
    expect(saved, [false]);

    fail = true;
    await tester.tap(find.byKey(const Key('settings-personalization')));
    await tester.pumpAndSettle();
    expect(find.text('没能保存设置，请稍后再试'), findsOneWidget);
    expect(saved, [false]);
  });
}
