import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/account/account_surface.dart';
import 'package:shunshi/presentation/pages/home/elder_home_text.dart';
import 'package:shunshi/presentation/pages/home/home_clock.dart';
import 'package:shunshi/presentation/pages/home/home_recommend.dart';
import 'package:shunshi/presentation/pages/home/ultimate_home_page.dart';
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
        HomeSuggest(id: 'angelica', title: '当归', subtitle: '补血活血、调经止痛。', tag: '饮食', season: 'winter', homeSafe: true),
        HomeSuggest(id: 'porridge', title: '热粥', subtitle: '晚饭喝一碗热粥。', tag: '饮食', season: 'winter', homeSafe: true),
        HomeSuggest(id: 'unmarked', title: '晚饭加一碗热汤', subtitle: '晚饭喝一碗热汤，别吃得太晚。', tag: '饮食', season: 'winter'),
      ],
    );
    final blob = winter.map((item) => item.blob).join();
    expect(winter.map((item) => item.id), isNot(contains('spring-greens')));
    expect(winter.map((item) => item.id), isNot(contains('lettuce')));
    expect(winter.map((item) => item.id), isNot(contains('almond')));
    expect(winter.map((item) => item.id), isNot(contains('angelica')));
    expect(winter.map((item) => item.id), isNot(contains('unmarked')));
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
    const mint = HomeSuggest(id: 'mint-tea', title: '热茶', subtitle: '下午喝一杯薄荷茶。', tag: '饮食', season: 'winter', homeSafe: true);
    final nursing = homeSuggestionsFor(season: 'winter', lifeStage: '哺乳期', extra: const [mint]);
    final general = homeSuggestionsFor(season: 'winter', lifeStage: '上班', extra: const [mint]);
    expect(nursing.map((item) => item.id), isNot(contains('mint-tea')));
    expect(general.map((item) => item.id), contains('mint-tea'));
    expect(nursing.any((item) => item.blob.contains('薄荷')), isFalse);
  });

  test('seed teas with efficacy or grams stay off the home list', () {
    const teas = [
      HomeSuggest(
        id: 'seed_tea_020',
        title: '姜枣茶',
        subtitle: '生姜温中散寒，红枣补中益气。冬季饮用姜枣茶可驱寒暖身，预防感冒。生姜3片、红枣5颗，加水煮10分钟。风寒感冒初期尤宜。',
        tag: '茶饮',
        season: 'winter',
        homeSafe: true,
      ),
      HomeSuggest(
        id: 'seed_tea_021',
        title: '黑芝麻茶',
        subtitle: '黑芝麻性平味甘，补肝肾、润五脏。冬季饮用可滋养肝肾，润肠通便。黑芝麻20g炒香研磨，加温水冲饮。',
        tag: '茶饮',
        season: 'winter',
        homeSafe: true,
      ),
      HomeSuggest(
        id: 'seed_tea_023',
        title: '枸杞红枣茶',
        subtitle: '枸杞滋补肝肾，红枣补中益气。冬季饮用可温补肝肾，益气养血。枸杞15g、红枣8颗，沸水冲泡10分钟。',
        tag: '茶饮',
        season: 'winter',
        homeSafe: true,
      ),
      HomeSuggest(
        id: 'seed_tea_024',
        title: '核桃露',
        subtitle: '核桃性温味甘，补肾固精、温肺定喘。冬季饮用核桃露可补肾健脑，温肺润肠。核桃仁50g研磨，加牛奶200ml煮10分钟。',
        tag: '茶饮',
        season: 'winter',
        homeSafe: true,
      ),
    ];
    for (final stage in [null, '上班', '孕期', '哺乳期']) {
      final shown = homeSuggestionsFor(season: 'winter', lifeStage: stage, extra: teas);
      final blob = shown.map((item) => item.blob).join();
      for (final tea in teas) {
        expect(shown.map((item) => item.id), isNot(contains(tea.id)));
      }
      for (final term in ['补中益气', '滋补肝肾', '补肾固精', '润肠通便', '风寒感冒初期尤宜', '引火归元', '滋养气血', '运化', '清心导浊']) {
        expect(blob.contains(term), isFalse, reason: term);
      }
      expect(homeDosagePattern.hasMatch(blob), isFalse);
      expect(shown.any((item) => item.blob.contains('热粥')), isTrue);
    }

    for (final tea in <Map<String, dynamic>>[
      {
        'id': 'seed_tea_020',
        'title': '姜枣茶',
        'description': '生姜温中散寒，红枣补中益气。生姜3片、红枣5颗。风寒感冒初期尤宜。',
        'type': 'tea',
        'season': 'winter',
        'home_safe': true,
        'ingredients': ['生姜3片', '红枣5颗'],
      },
      {
        'id': 'seed_tea_021',
        'title': '黑芝麻茶',
        'description': '冬季饮用可滋养肝肾，润肠通便。黑芝麻20g。',
        'type': 'tea',
        'season': 'winter',
        'home_safe': true,
        'ingredients': ['黑芝麻20g'],
      },
      {
        'id': 'seed_tea_023',
        'title': '枸杞红枣茶',
        'description': '枸杞滋补肝肾，红枣补中益气。枸杞15g、红枣8颗。',
        'type': 'tea',
        'season': 'winter',
        'home_safe': true,
      },
      {
        'id': 'seed_tea_024',
        'title': '核桃露',
        'description': '核桃性温味甘，补肾固精。核桃仁50g，牛奶200ml。',
        'type': 'tea',
        'season': 'winter',
        'tags': ['home_safe'],
      },
    ]) {
      expect(keepHomePayload(tea, season: 'winter'), isFalse, reason: tea['id'] as String);
      expect(keepHomePayload(tea, season: 'winter', lifeStage: '孕期'), isFalse);
      expect(keepHomePayload(tea, season: 'winter', lifeStage: '哺乳期'), isFalse);
    }

    expect(
      keepHomePayload(
        {'id': 'porridge', 'title': '热粥', 'description': '晚饭喝一碗热粥。', 'type': 'food_therapy', 'season': 'winter', 'home_safe': true},
        season: 'winter',
        lifeStage: '孕期',
      ),
      isTrue,
    );
    expect(
      keepHomePayload(
        {'id': 'porridge', 'title': '热粥', 'description': '晚饭喝一碗热粥。', 'type': 'food_therapy', 'season': 'winter', 'home_safe': true},
        season: 'winter',
        lifeStage: '哺乳期',
      ),
      isTrue,
    );
    expect(
      keepHomePayload(
        {'id': 'dg', 'title': '当归蛋汤', 'description': '晚饭喝一碗热汤。', 'type': 'food_therapy', 'season': 'winter', 'home_safe': true},
        season: 'winter',
        lifeStage: '孕期',
      ),
      isFalse,
    );
    expect(
      keepHomePayload(
        {'id': 'unmarked', 'title': '晚饭加一碗热汤', 'description': '晚饭喝一碗热汤，别吃得太晚。', 'type': 'food_therapy', 'season': 'winter'},
        season: 'winter',
      ),
      isFalse,
    );
  });

  test('home efficacy class allows plain 补充 and blocks the scan terms', () {
    expect(homeVisibleTextHasEfficacy('午后记得小口多喝水，补充水分'), isFalse);
    expect(homeDosagePattern.hasMatch('歇一会儿'), isFalse);
    expect(homeDosagePattern.hasMatch('生姜3片、红枣5颗'), isTrue);
    for (final sample in [
      '温胃健脾，补中益气',
      '生姜红枣泡水暖胃驱寒，调和脾胃',
      '玫瑰花茶疏肝理气，宁心安神',
      '小肠经活跃，负责将食物精华吸收、糟粕排出',
      '养心安神',
      '百脉通调',
      '陈皮普洱健脾理气',
      '健脾土',
      '引火归元',
      '滋养气血',
      '运化',
      '清心导浊',
      '固精',
      '润肠通便',
      '感冒',
      '尤宜',
    ]) {
      expect(homeVisibleTextHasEfficacy(sample), isTrue, reason: sample);
    }
  });

  test('whole home static copy has no efficacy, dosage, tea, or listed foods', () {
    final copy = visibleHomeCopy();
    expect(copy.length, greaterThan(visibleHomeTimeOfDayCopy().length));
    expect(visibleHomeTimeOfDayCopy().where((line) => line == '子时'), isNotEmpty);
    expect(visibleHomeTimeOfDayCopy().where((line) => line == '亥时'), isNotEmpty);
    expect(visibleHomeTimeOfDayCopy().join().contains('补充水分'), isTrue);
    for (final line in copy) {
      expect(homeVisibleTextHasEfficacy(line), isFalse, reason: line);
      expect(homeDosagePattern.hasMatch(line), isFalse, reason: line);
    }
    final joined = copy.join('\n');
    expect(joined.contains('茶'), isFalse);
    for (final stage in ['孕期', '哺乳期']) {
      for (final name in homeExclusionNames(stage)) {
        expect(joined.contains(name), isFalse, reason: '$stage $name');
      }
    }
    for (final term in [
      '经络',
      '经活跃',
      '当令',
      '胆经',
      '肝经',
      '肺经',
      '大肠经',
      '胃经',
      '脾经',
      '心经',
      '小肠经',
      '膀胱经',
      '肾经',
      '心包经',
      '三焦经',
      '养百脉',
    ]) {
      expect(joined.contains(term), isFalse, reason: term);
    }
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
