import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/widgets/personal_home_section.dart';

const bool zh = false;
final cjk = RegExp(r'[\u3400-\u9fff]');

Map<String, dynamic> shunshiJson({bool enabled = true, int cards = 3}) => {
      'greeting': zh ? '早上好，今天从一件小事开始' : 'Good morning. Start with one small thing.',
      'hero': {'id': 'c0', 'title': zh ? '三次深呼吸' : 'Three deep breaths'},
      'streak': {'kind': 'streak', 'days': 3, 'text': zh ? '已连续 3 天做了一件小事' : 'Three days of small things in a row'},
      'personalization': {'enabled': enabled, 'note': zh ? '这些建议只是生活方式提示，不是诊断。' : 'Lifestyle ideas, not medical advice.'},
      'suggestions': [
        for (var i = 0; i < cards; i++)
          {
            'id': 'c$i',
            'category': ['breathing', 'sleep', 'food', 'exercise'][i % 4],
            'title': zh ? '建议 $i' : 'Suggestion $i',
            'description': zh ? '建议 $i' : 'Suggestion $i',
            'reason': zh ? '你选的目标：睡得更好' : 'Because you chose "sleep better"',
            'duration_min': 3 + i,
          }
      ],
    };

Map<String, dynamic> energyJson({bool personalized = true, int cards = 3}) => {
      'code': 0,
      'data': {
        'personalized': personalized,
        'hero': {'greeting': zh ? '早上好' : 'Good morning', 'headline': zh ? '你有 1 个项目，还没做资源评估' : 'You have 1 project without a resource assessment', 'subtext': zh ? '今天是第 2 天连续打开' : 'Day 2 in a row'},
        'streak': 2,
        'note': zh ? '这些建议来自你的项目进度。' : 'These come from your project progress.',
        'disclaimer': zh ? '以上不构成投资建议。' : 'Not investment advice.',
        'cards': [
          for (var i = 0; i < cards; i++)
            {
              'id': 'e$i',
              'kind': ['analysis', 'ops', 'policy'][i % 3],
              'title': zh ? '步骤 $i' : 'Step $i',
              'body': zh ? '说明 $i' : 'Detail $i',
              'reason': zh ? '根据你的项目进度' : 'Because of your project progress',
              'href': '/calculator',
            }
        ],
      },
    };

PersonalHomeApi fake(Future<Map<String, dynamic>> Function() load, [Future<void> Function(bool)? set]) =>
    PersonalHomeApi(load: load, setEnabled: set ?? (_) async {});

Widget host(Widget child) => MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

String allText(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join(' ');

void main() {
  test('parses the 顺时 shape: hero, suggestions, streak, note, switch', () {
    final d = PersonalHomeData.fromJson(shunshiJson());
    expect(d.enabled, isTrue);
    expect(d.cards.length, 3);
    expect(d.cards.first.minutes, 3);
    expect(d.cards.first.kind, 'breathing');
    expect(d.cards.first.body, isEmpty, reason: 'description equal to title must not be shown twice');
    expect(d.streakText, isNotEmpty);
    expect(PersonalHomeData.fromJson(shunshiJson(enabled: false)).enabled, isFalse);
  });

  test('parses the 新能源 shape (wrapped in data) incl. links', () {
    final d = PersonalHomeData.fromJson(energyJson());
    expect(d.cards.first.href, '/calculator');
    expect(d.headline, isNotEmpty);
    expect(d.streakText, isNotEmpty);
    expect(d.note, contains(zh ? '不构成投资建议' : 'Not investment advice'), reason: 'the disclaimer must reach the screen');
    expect(PersonalHomeData.fromJson(energyJson(personalized: false)).enabled, isFalse);
  });

  test('ignores junk cards instead of crashing', () {
    final d = PersonalHomeData.fromJson({'suggestions': [1, null, {'title': ''}, {'title': 'ok'}], 'streak': 'x'});
    expect(d.cards.length, 1);
  });

  testWidgets('shows a loading skeleton, then the cards with a why-line each', (tester) async {
    final c = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() => c.future))));
    expect(find.byKey(const Key('personal-home-loading')), findsOneWidget);
    c.complete(shunshiJson());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-loading')), findsNothing);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('personal-home-card-c$i')), findsOneWidget);
      expect(find.byKey(Key('personal-home-why-c$i')), findsOneWidget);
    }
    expect(find.textContaining(zh ? '为什么看到这个' : 'Why you see this'), findsNWidgets(3));
    expect(find.byKey(const Key('personal-home-streak')), findsOneWidget);
    expect(find.byKey(const Key('personal-home-turn-off')), findsOneWidget);
  });

  testWidgets('error state offers retry and recovers', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async {
      if (++calls == 1) throw Exception('offline');
      return shunshiJson();
    }))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('personal-home-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-error')), findsNothing);
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('empty state when the backend has nothing to suggest', (tester) async {
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async => shunshiJson(cards: 0)))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-empty')), findsOneWidget);
  });

  testWidgets('turning off asks first, saves, and shows the off state; turning on restores', (tester) async {
    var enabled = true;
    final saved = <bool>[];
    await tester.pumpWidget(host(PersonalHomeSection(
      api: fake(() async => shunshiJson(enabled: enabled), (v) async {
        saved.add(v);
        enabled = v;
      }),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-home-turn-off')));
    await tester.pumpAndSettle();
    expect(find.textContaining(zh ? '关闭个性化推荐' : 'Turn off personalised'), findsOneWidget);
    await tester.tap(find.byKey(const Key('personal-home-cancel')));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    await tester.tap(find.byKey(const Key('personal-home-turn-off')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-home-confirm')));
    await tester.pumpAndSettle();
    expect(saved, [false]);
    expect(find.byKey(const Key('personal-home-off')), findsOneWidget);
    expect(find.byKey(const Key('personal-home-card-c0')), findsNothing);
    await tester.tap(find.byKey(const Key('personal-home-turn-on')));
    await tester.pumpAndSettle();
    expect(saved, [false, true]);
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
  });

  testWidgets('a failed save keeps the page and tells the user', (tester) async {
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async => shunshiJson(), (_) async => throw Exception('500')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-home-turn-off')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-home-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(zh ? '没能保存设置，请稍后再试' : 'Could not save your setting. Please try again.'), findsOneWidget);
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
  });

  testWidgets('cards with a link are tappable and report which card', (tester) async {
    PersonalHomeCard? opened;
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async => energyJson()), onOpen: (c) => opened = c)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personal-home-card-e1')));
    expect(opened?.href, '/calculator');
    expect(opened?.id, 'e1');
  });

  testWidgets('language gate: every visible string matches the edition', (tester) async {
    for (final json in [shunshiJson(), energyJson()]) {
      await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async => json))));
      await tester.pumpAndSettle();
      final t = allText(tester);
      expect(t.isNotEmpty, isTrue);
      expect(cjk.hasMatch(t), zh, reason: t);
    }
    // the non-content states too
    for (final api in [fake(() async => throw Exception('x')), fake(() async => shunshiJson(cards: 0)), fake(() async => shunshiJson(enabled: false))]) {
      await tester.pumpWidget(host(PersonalHomeSection(api: api)));
      await tester.pumpAndSettle();
      expect(cjk.hasMatch(allText(tester)), zh, reason: allText(tester));
    }
  });

  testWidgets('long text and a narrow screen do not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final j = shunshiJson();
    (j['suggestions'] as List)[0]['title'] = List.filled(40, zh ? '很长的标题' : 'a very long title').join(' ');
    (j['suggestions'] as List)[0]['reason'] = List.filled(40, zh ? '很长的原因' : 'a very long reason').join(' ');
    await tester.pumpWidget(host(PersonalHomeSection(api: fake(() async => j))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
