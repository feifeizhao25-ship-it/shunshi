import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/account/account_surface.dart';
import 'package:shunshi/presentation/pages/home/elder_home_text.dart';
import 'package:shunshi/presentation/pages/home/home_clock.dart';
import 'package:shunshi/presentation/pages/home/home_recommend.dart';
import 'package:shunshi/presentation/widgets/personal_home_strings_zh.dart';

void main() {
  test('November after 立冬 is winter; early November stays autumn', () {
    expect(seasonKeyOn(DateTime(2026, 11, 13)), 'winter');
    expect(seasonKeyOn(DateTime(2026, 11, 3)), 'autumn');
    expect(seasonKeyOn(DateTime(2026, 4, 10)), 'spring');
    expect(seasonKeyOn(DateTime(2026, 7, 1)), 'summer');
  });

  test('home suggestions stay in season and carry no efficacy terms', () {
    final winter = homeSuggestionsFor(
      season: 'winter',
      extra: const [
        HomeSuggest(id: 'spring-greens', title: '春菜', subtitle: '午饭加一盘青菜。', tag: '饮食', season: 'spring'),
        HomeSuggest(id: 'lettuce', title: '莴笋', subtitle: '通乳汁。', tag: '饮食', season: 'summer'),
        HomeSuggest(id: 'almond', title: '苦杏仁', subtitle: '有毒需炮制。', tag: '饮食', season: 'autumn'),
        HomeSuggest(id: 'angelica', title: '当归', subtitle: '补血活血、调经止痛。', tag: '饮食', season: 'winter'),
        HomeSuggest(id: 'porridge', title: '热粥', subtitle: '晚饭喝一碗热粥。', tag: '饮食', season: 'winter'),
      ],
    );
    final blob = winter.map((item) => item.blob).join();
    expect(winter.map((item) => item.id), isNot(contains('spring-greens')));
    expect(winter.map((item) => item.id), isNot(contains('lettuce')));
    expect(winter.map((item) => item.id), isNot(contains('almond')));
    expect(winter.map((item) => item.id), isNot(contains('angelica')));
    expect(winter.map((item) => item.id), contains('porridge'));
    for (final term in homeEfficacyTerms) {
      expect(blob.contains(term), isFalse, reason: term);
    }
    expect(winter.every((item) => item.season == 'winter'), isTrue);

    final payload = keepHomePayload(
      {'title': '肩井穴', 'description': '乳汁不下。孕妇禁用。', 'type': 'acupressure', 'season': 'winter'},
      season: 'winter',
    );
    expect(payload, isFalse);
  });

  test('a breastfeeding profile does not see listed foods', () {
    const mint = HomeSuggest(id: 'mint-tea', title: '热茶', subtitle: '下午喝一杯薄荷茶。', tag: '饮食', season: 'winter');
    final nursing = homeSuggestionsFor(season: 'winter', lifeStage: '哺乳期', extra: const [mint]);
    final general = homeSuggestionsFor(season: 'winter', lifeStage: '上班', extra: const [mint]);
    expect(nursing.map((item) => item.id), isNot(contains('mint-tea')));
    expect(general.map((item) => item.id), contains('mint-tea'));
    expect(nursing.any((item) => item.blob.contains('薄荷')), isFalse);
  });

  test('节气 chip date matches an injected card date', () {
    final live = DateTime(2026, 11, 13);
    final injected = homeClockDay(deviceNow: live, injectedTestNow: '2026-11-04T21:00:00+08:00');
    expect(injected, DateTime(2026, 11, 4));
    expect(solarTermSeasonLine(injected), '霜降 · 季秋之节');
    expect(solarTermSeasonLine(live), '立冬 · 孟冬之节');
    expect(homeClockDay(deviceNow: live), DateTime(2026, 11, 13));
  });

  test('streak fallback uses the same small-action wording', () {
    expect(kPersonalHomeStringsZh.days(4), '已经连续 4 天做小行动，保持这个节奏就好');
    expect(kPersonalHomeStringsZh.days(4).contains('打开'), isFalse);
  });

  testWidgets('elder mode enlarges home text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ElderHomeScope(
        enabled: true,
        child: _ScaleProbe(),
      ),
    ));
    expect(find.text('20.0'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: ElderHomeScope(
        enabled: false,
        child: _ScaleProbe(),
      ),
    ));
    expect(find.text('16.0'), findsOneWidget);
  });
}

class _ScaleProbe extends StatelessWidget {
  const _ScaleProbe();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(16);
    return Text(size.toString());
  }
}
