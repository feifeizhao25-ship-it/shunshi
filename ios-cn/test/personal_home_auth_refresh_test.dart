import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/account/auth_session.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

PersonalHomeApi fake(Future<Map<String, dynamic>> Function() load) =>
    PersonalHomeApi(load: load, setEnabled: (_) async {});

void main() {
  testWidgets('home reloads the personal section when auth becomes logged in', (tester) async {
    final auth = AuthSession();
    var loggedIn = false;
    var calls = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [authSessionProvider.overrideWith((ref) => auth)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => SingleChildScrollView(
              child: PersonalHomeSection(
                strings: kPersonalHomeStringsZh,
                auth: ref.watch(authSessionProvider),
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
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('请先登录'), findsOneWidget);
    expect(find.byKey(const Key('personal-home-card-c0')), findsNothing);

    loggedIn = true;
    auth.markLoggedIn();
    await tester.pumpAndSettle();

    expect(find.text('请先登录'), findsNothing);
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
    expect(calls, greaterThanOrEqualTo(2));
  });
}
