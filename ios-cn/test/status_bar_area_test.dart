import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/data/storage/storage_manager.dart';
import 'package:shunshi/presentation/pages/profile/profile_page_v2.dart';
import 'package:shunshi/presentation/pages/wellness/wellness_home_page.dart';
import 'package:shunshi/presentation/widgets/status_bar_area.dart';

Future<void> _pump(WidgetTester tester, Widget page, Brightness b) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 32);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: ThemeData(brightness: b), home: page));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
  });

  test('浅色主题深色图标，深色主题浅色图标（Android 与 iOS 两个字段）', () {
    final light = StatusBarArea.styleFor(Brightness.light);
    expect(light.statusBarIconBrightness, Brightness.dark);
    expect(light.statusBarBrightness, Brightness.light);
    final dark = StatusBarArea.styleFor(Brightness.dark);
    expect(dark.statusBarIconBrightness, Brightness.light);
    expect(dark.statusBarBrightness, Brightness.dark);
  });

  for (final entry in {'我的': const ProfilePageV2(), '养生': const WellnessHomePage()}.entries) {
    testWidgets('「${entry.key}」页设置状态栏样式，滚动内容在状态栏下面（问题 44）', (tester) async {
      await _pump(tester, entry.value, Brightness.light);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byWidgetPredicate((w) => w is AnnotatedRegion<SystemUiOverlayStyle> && w.child is SafeArea),
      );
      expect(region.value.statusBarIconBrightness, Brightness.dark);
      final scroll = tester.getRect(find.byType(Scrollable).first);
      expect(scroll.top, greaterThanOrEqualTo(32), reason: '滚动区域不能伸进状态栏');
    });
  }
}
