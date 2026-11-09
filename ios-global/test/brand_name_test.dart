import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/about/about_page.dart';

void main() {
  testWidgets('about screen is SEASONS and does not pitch a constitution quiz', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();
    final text = tester.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join('\n');
    expect(text.contains('ShunShi'), isFalse, reason: text);
    expect(text.contains('顺时'), isFalse);
    expect(text.toLowerCase().contains('constitution'), isFalse, reason: text);
    expect(text.contains('SEASONS'), isTrue);
  });
}
