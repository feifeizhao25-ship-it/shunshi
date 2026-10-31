// 个性化首页上的「资料库」卡：显示理由、点一下进资料库页；外链和非法路径不跳转。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shunshi/presentation/pages/home/widgets/personal_home_binding.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';

Map<String, dynamic> homeJson({String href = '/reference-library'}) => {
      'greeting': '早上好',
      'hero': {'id': 'c0', 'title': '三次深呼吸'},
      'personalization': {'enabled': true, 'note': '这些建议只是生活方式提示，不是诊断。'},
      'suggestions': [
        {'id': 'term', 'category': 'season', 'title': '立冬：早睡一点', 'description': '立冬：早睡一点', 'reason': '今天是立冬'},
        {
          'id': 'library_for_you',
          'category': 'library',
          'kind': 'library',
          'title': '资料库有更新：成人身体活动建议',
          'description': '官方资料的表述有更新。',
          'reason': '你关注了「运动」，这篇最近有更新',
          'href': href,
          'entry_id': 'ss-lib-005',
        },
      ],
    };

Widget app(Map<String, dynamic> json) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (c, _) => Scaffold(
        body: SingleChildScrollView(
          child: PersonalHomeSection(
            api: PersonalHomeApi(load: () async => json, setEnabled: (_) async {}),
            onOpen: (card) => PersonalHomeBinding.open(c, card),
          ),
        ),
      ),
    ),
    GoRoute(path: '/reference-library', builder: (c, _) => const Scaffold(body: Text('资料库页'))),
  ]);
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('资料库卡显示标题和「为什么推荐」，点一下进入资料库页', (tester) async {
    await tester.pumpWidget(app(homeJson()));
    await tester.pumpAndSettle();
    expect(find.text('资料库有更新：成人身体活动建议'), findsOneWidget);
    expect(find.textContaining('你关注了「运动」'), findsOneWidget);
    expect(find.byIcon(Icons.local_library_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('personal-home-card-library_for_you')));
    await tester.pumpAndSettle();
    expect(find.text('资料库页'), findsOneWidget);
  });

  testWidgets('外链或非法路径不会跳转', (tester) async {
    for (final bad in ['https://example.com/x', '//evil.example/x']) {
      await tester.pumpWidget(app(homeJson(href: bad)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('personal-home-card-library_for_you')));
      await tester.pumpAndSettle();
      expect(find.text('资料库页'), findsNothing, reason: bad);
      expect(find.text('资料库有更新：成人身体活动建议'), findsOneWidget);
    }
  });
}
