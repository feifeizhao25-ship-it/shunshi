import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shunshi/presentation/pages/profile/profile_setup_page.dart';

void main() {
  test('每一步缺什么都有提示，体质那一步说明不是诊断', () {
    expect(profileSetupMissingHint(0), contains('昵称'));
    expect(profileSetupMissingHint(1), contains('性别'));
    expect(profileSetupMissingHint(2), isNull);
    expect(profileSetupMissingHint(3), allOf(contains('体质标签'), contains('不是诊断')));
  });

  testWidgets('没填昵称点「下一步」会弹提示，而不是没有反应', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pump();
    expect(find.text('先填一个昵称，再点下一步'), findsOneWidget);
  });
}
