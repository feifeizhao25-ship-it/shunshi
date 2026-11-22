import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/personal_home_section.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

/// 2026-11-22 顺时实测：首页连续天数 / 一周打卡条靠 /personalization/action/complete，
/// 但客户端从来没调过它，进度永远是 0。卡片上加「做完了」，点了就记一次，再刷新首页。
Map<String, dynamic> home({bool done = false, bool enabled = true}) => {
      'greeting': '晚上好',
      'personalization': {'enabled': enabled},
      'streak': done ? {'kind': 'streak', 'days': 1, 'text': '今天做了一件小事'} : null,
      'week': [
        for (var i = 6; i >= 0; i--)
          {'date': DateTime(2026, 11, 22).subtract(Duration(days: i)).toIso8601String().substring(0, 10), 'done': done && i == 0, 'today': i == 0}
      ],
      'suggestions': [
        {'id': 'sleep_warm_feet', 'category': 'sleep', 'title': '睡前泡脚 10 分钟', 'reason': '你选的目标：睡得更好', 'duration_min': 10},
        {'id': 'breath_box', 'category': 'breathing', 'title': '方块呼吸', 'reason': '晚上适合放松', 'duration_min': 3},
      ],
    };

Widget host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('点「做完了」记下这张卡、提示一句、然后首页重新加载出今天已完成', (t) async {
    var loads = 0;
    final completed = <PersonalHomeCard>[];
    await t.pumpWidget(host(PersonalHomeSection(
      strings: kPersonalHomeStringsZh,
      api: PersonalHomeApi(
        load: () async => home(done: loads++ > 0),
        setEnabled: (_) async {},
        complete: (card) async => completed.add(card),
      ),
    )));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('personal-home-done-sleep_warm_feet')), findsOneWidget);
    expect(find.text('做完了'), findsNWidgets(2));
    expect(find.byKey(const Key('personal-home-week')), findsNothing);

    await t.tap(find.byKey(const Key('personal-home-done-sleep_warm_feet')));
    await t.pumpAndSettle();
    expect(completed.single.id, 'sleep_warm_feet');
    expect(completed.single.kind, 'sleep');
    expect(completed.single.minutes, 10);
    expect(find.text('记下了，今天算打卡'), findsOneWidget);
    expect(loads, 2);
    expect(find.text('今天做了一件小事'), findsOneWidget);
    expect(find.byKey(const Key('personal-home-week')), findsOneWidget);
  });

  testWidgets('没接 complete 的版本不显示「做完了」', (t) async {
    await t.pumpWidget(host(PersonalHomeSection(
      strings: kPersonalHomeStringsZh,
      api: PersonalHomeApi(load: () async => home(), setEnabled: (_) async {}),
    )));
    await t.pumpAndSettle();
    expect(find.text('做完了'), findsNothing);
    expect(find.text('不再推荐'), findsNWidgets(2));
  });

  testWidgets('记失败时提示没保存，不假装完成', (t) async {
    await t.pumpWidget(host(PersonalHomeSection(
      strings: kPersonalHomeStringsZh,
      api: PersonalHomeApi(load: () async => home(), setEnabled: (_) async {}, complete: (_) async => throw Exception('500')),
    )));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('personal-home-done-breath_box')));
    await t.pumpAndSettle();
    expect(find.text(kPersonalHomeStringsZh.saveFailed), findsOneWidget);
    expect(find.text('记下了，今天算打卡'), findsNothing);
  });
}
