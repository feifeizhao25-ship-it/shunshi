import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/solar/solar_term_ai_detail_page.dart';
import 'package:shunshi/web/readable_semantics.dart';

void main() {
  testWidgets('2026 大寒 09:45 and 大雪 10:53 are in the semantics text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: SolarTermAIDetailPage(termName: '大寒')));
    await tester.pump();
    var copy = collectReadableSemanticsText();
    expect(copy, contains('大寒'));
    expect(copy, contains('09:45'));

    await tester.pumpWidget(const MaterialApp(home: SolarTermAIDetailPage(termName: '大雪')));
    await tester.pump();
    copy = collectReadableSemanticsText();
    expect(copy, contains('大雪'));
    expect(copy, contains('10:53'));
    handle.dispose();
  });
}
