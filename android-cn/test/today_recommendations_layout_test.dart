import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/home/ultimate_home_page.dart';

/// 今日推荐横滑卡片：固定高度 150 在默认字号下底部溢出 4px。
/// 字号 1.0 和 1.3 都要能放下标题、两行说明和底部标签。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _loadFonts();
  });

  final recs = plainTodayRecommendations(DateTime(2026, 11, 13));

  for (final scale in [1.0, 1.3]) {
    testWidgets('today recommendations do not overflow at text scale $scale', (tester) async {
      final height = await _pumpRecommendations(tester, recs, scale);
      expect(tester.takeException(), isNull);
      expect(height, greaterThan(150));
      _expectTagsInsideCards(tester, recs);
    });
  }

  testWidgets('today recommendations grow when text scale goes from 1.0 to 1.3', (tester) async {
    final atDefault = await _pumpRecommendations(tester, recs, 1.0);
    expect(tester.takeException(), isNull);
    final enlarged = await _pumpRecommendations(tester, recs, 1.3);
    expect(tester.takeException(), isNull);
    expect(enlarged, greaterThan(atDefault));
  });
}

Future<double> _pumpRecommendations(
  WidgetTester tester,
  List<TodayRecommendation> recs,
  double scale,
) async {
  tester.view.devicePixelRatio = 2.625;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TodayRecommendationsSection(recommendations: recs),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();

  expect(find.text(kHomeRecommendHeading), findsOneWidget);
  for (final rec in recs) {
    expect(find.text(rec.title), findsOneWidget);
    expect(find.text(rec.subtitle), findsOneWidget);
    expect(find.text(rec.tag), findsWidgets);
  }
  return _cardHeight(tester);
}

double _cardHeight(WidgetTester tester) {
  final cards = _cardElements(tester);
  expect(cards, isNotEmpty);
  var height = 0.0;
  for (final element in cards) {
    final box = element.renderObject! as RenderBox;
    expect(box.hasSize, isTrue);
    if (box.size.height > height) height = box.size.height;
  }
  return height;
}

void _expectTagsInsideCards(WidgetTester tester, List<TodayRecommendation> recs) {
  final cards = _cardElements(tester).map((element) => element.renderObject! as RenderBox).toList();
  for (final rec in recs) {
    final tags = tester.renderObjectList<RenderBox>(find.text(rec.tag));
    expect(tags, isNotEmpty);
    for (final tag in tags) {
      final inside = cards.any((card) => _contains(card, tag));
      expect(inside, isTrue, reason: rec.tag);
    }
  }
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('NotoSansSC', const [
    'assets/fonts/NotoSansSC-Regular.ttf',
    'assets/fonts/NotoSansSC-Bold.ttf',
  ]);
  await load('NotoSerifSC', const [
    'assets/fonts/NotoSerifSC-Regular.ttf',
    'assets/fonts/NotoSerifSC-Bold.ttf',
  ]);
}

Iterable<Element> _cardElements(WidgetTester tester) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Container) return false;
    final constraints = widget.constraints;
    return constraints != null && constraints.minWidth == 140 && constraints.maxWidth == 140;
  }).evaluate();
}

bool _contains(RenderBox outer, RenderBox inner) {
  final top = inner.localToGlobal(Offset.zero);
  final bottom = inner.localToGlobal(inner.size.bottomRight(Offset.zero));
  final outerTop = outer.localToGlobal(Offset.zero);
  final outerBottom = outer.localToGlobal(outer.size.bottomRight(Offset.zero));
  return top.dx >= outerTop.dx - 0.5 &&
      top.dy >= outerTop.dy - 0.5 &&
      bottom.dx <= outerBottom.dx + 0.5 &&
      bottom.dy <= outerBottom.dy + 0.5;
}
