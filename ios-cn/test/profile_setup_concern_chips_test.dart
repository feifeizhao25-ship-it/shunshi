import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/profile/profile_setup_page.dart';

void main() {
  testWidgets('出生年那一步显示四个关注选项，「睡眠」能点选', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '测试');
    await tester.pump();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('女'));
    await tester.pump();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    for (final c in ['睡眠', '饮食', '走动', '情绪']) {
      expect(find.text(c), findsOneWidget, reason: c);
    }
    BoxDecoration deco() => tester.widget<AnimatedContainer>(
            find.ancestor(of: find.text('睡眠'), matching: find.byType(AnimatedContainer)).first)
        .decoration as BoxDecoration;
    final before = deco().color;
    await tester.ensureVisible(find.text('睡眠'));
    await tester.tap(find.text('睡眠'));
    await tester.pumpAndSettle();
    expect(deco().color, isNot(equals(before)), reason: '点了以后变成选中样式');
  });
}
