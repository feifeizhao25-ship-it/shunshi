import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

PersonalHomeApi fake(Future<Map<String, dynamic>> Function() load) =>
    PersonalHomeApi(load: load, setEnabled: (_) async {});

Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  test('401 is a login failure, other statuses stay network errors', () {
    expect(mapPersonalHomeError(Exception('no'), statusCode: 401), isA<PersonalHomeAuthRequired>());
    expect(mapPersonalHomeError(const PersonalHomeAuthRequired()), isA<PersonalHomeAuthRequired>());
    final other = mapPersonalHomeError(Exception('offline'), statusCode: 503);
    expect(other, isA<Exception>());
    expect(other, isNot(isA<PersonalHomeAuthRequired>()));
  });

  testWidgets('401 shows a login prompt instead of a network error', (tester) async {
    var calls = 0;
    var loggedIn = false;
    await tester.pumpWidget(host(PersonalHomeSection(
      strings: kPersonalHomeStringsZh,
      onLogin: () async {
        loggedIn = true;
      },
      api: fake(() async {
        calls += 1;
        if (!loggedIn) throw const PersonalHomeAuthRequired();
        return {
          'greeting': '早上好',
          'personalization': {'enabled': true},
          'suggestions': [
            {'id': 'c0', 'title': '建议 0', 'reason': '你选的目标', 'category': 'breathing', 'duration_min': 3},
          ],
        };
      }),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-login')), findsOneWidget);
    expect(find.text('请先登录'), findsOneWidget);
    expect(find.text('登录后就能看到为你准备的内容。'), findsOneWidget);
    expect(find.text('请检查网络后再试一次。'), findsNothing);
    await tester.tap(find.byKey(const Key('personal-home-login-action')));
    await tester.pumpAndSettle();
    expect(find.text('去登录'), findsNothing);
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
    expect(calls, 2);
  });
}
