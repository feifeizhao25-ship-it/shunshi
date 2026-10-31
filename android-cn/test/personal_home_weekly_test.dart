import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

const bool zh = true;
final cjk = RegExp(r'[\u3400-\u9fff]');

List<Map<String, dynamic>> weekJson(List<bool> done) => [
      for (var i = 0; i < 7; i++) {'date': '2026-11-${(3 + i).toString().padLeft(2, '0')}', 'done': done[i], 'today': i == 6},
    ];

Map<String, dynamic> board({
  List<bool>? week,
  int reached = 0,
  String milestone = '',
  Map<String, dynamic>? recall,
}) =>
    {
      'greeting': zh ? '早上好' : 'Good morning',
      'hero': {'id': 'c0', 'title': 'x'},
      'streak': {'kind': 'steady', 'days': 0, 'text': zh ? '今天再做一件小行动就很好' : 'One more small action today is plenty.'},
      'personalization': {'enabled': true, 'note': zh ? '仅为生活方式提示。' : 'Lifestyle ideas only.'},
      'week': week == null ? null : weekJson(week),
      'milestone': {'reached': reached, 'text': milestone},
      'recall': recall,
      'suggestions': [
        {'id': 'c0', 'category': 'sleep', 'title': zh ? '早点睡' : 'Sleep earlier', 'description': zh ? '早点睡' : 'Sleep earlier', 'reason': zh ? '你选的目标' : 'You chose sleep', 'duration_min': 3},
        {'id': 'c1', 'category': 'food', 'title': zh ? '喝温水' : 'Warm water', 'description': zh ? '喝温水' : 'Warm water', 'reason': zh ? '季节' : 'Season', 'duration_min': 2},
        {'id': 'c2', 'category': 'exercise', 'title': zh ? '散步' : 'Walk', 'description': zh ? '散步' : 'Walk', 'reason': zh ? '早晨' : 'Morning', 'duration_min': 10},
      ],
    };

Widget host(Map<String, dynamic> json) => MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PersonalHomeSection(key: UniqueKey(), strings: kPersonalHomeStringsZh, api: PersonalHomeApi(load: () async => json, setEnabled: (_) async {})),
        ),
      ),
    );

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').join(' ');

void main() {
  testWidgets('week strip shows the real days and hides itself when nothing was done', (t) async {
    await t.pumpWidget(host(board(week: [false, false, false, false, false, false, false])));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-week')), findsNothing);

    await t.pumpWidget(host(board(week: [false, true, true, false, true, true, true])));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-week')), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(zh ? '11-04 做了小行动' : '11-04: took a small action'))), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(zh ? '11-03 没有记录' : '11-03: nothing recorded'))), findsOneWidget);
  });

  testWidgets('day-3 and day-7 milestones show the server text; no streak means no chip', (t) async {
    await t.pumpWidget(host(board(reached: 0, milestone: '')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-milestone')), findsNothing);

    await t.pumpWidget(host(board(reached: 3, milestone: zh ? '连续 3 天了，好习惯已经起步' : 'Three days in a row. A habit is getting started.')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-milestone')), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);

    await t.pumpWidget(host(board(reached: 7, milestone: zh ? '连续 7 天' : 'Seven days in a row')));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
  });

  testWidgets('recall card is gentle, replaces the streak line, and can be dismissed for the session', (t) async {
    final recall = {'kind': 'recall', 'tier': 'week', 'text': zh ? '隔了一周，没关系。' : 'A week away is okay.', 'delivery': 'in_app_only'};
    await t.pumpWidget(host(board(recall: recall)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-recall')), findsOneWidget);
    expect(find.byKey(const Key('personal-home-streak')), findsNothing);
    expect(allText(t), contains(zh ? '欢迎回来' : 'Welcome back'));
    await t.tap(find.byKey(const Key('personal-home-recall-dismiss')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-recall')), findsNothing);
    expect(find.byKey(const Key('personal-home-streak')), findsOneWidget);
  });

  testWidgets('older backends without the new fields still render', (t) async {
    final json = board()..remove('week')..remove('milestone')..remove('recall');
    await t.pumpWidget(host(json));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-card-c0')), findsOneWidget);
    expect(find.byKey(const Key('personal-home-week')), findsNothing);
  });

  testWidgets('language is single-edition', (t) async {
    final json = board(week: [true, true, true, true, true, true, true], reached: 7, milestone: zh ? '连续 7 天' : 'Seven days in a row', recall: {'text': zh ? '隔了一周' : 'A week away', 'tier': 'week'});
    await t.pumpWidget(host(json));
    await t.pumpAndSettle();
    expect(cjk.hasMatch(allText(t)), zh);
  });
}
