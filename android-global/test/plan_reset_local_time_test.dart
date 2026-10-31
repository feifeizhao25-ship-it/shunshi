import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/settings/plan_usage_page.dart';

final cjk = RegExp(r'[\u3400-\u9fff]');

Map<String, dynamic> usage({Object? resetsAt}) => {
      'plan': 'free',
      'plan_name': 'Free',
      'active': false,
      'expires_at': null,
      if (resetsAt != null) 'resets_at': resetsAt,
      'reset_note': 'Daily limits reset at 00:00 Beijing time (16:00 UTC).',
      'items': [
        {'key': 'audio_minutes', 'limit': 30, 'unlimited': false, 'used': 12, 'used_known': true, 'remaining': 18, 'unit': 'minutes'},
      ],
    };

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(' | ');

void main() {
  // Local wall-clock times so the checks do not depend on the machine's time zone.
  final now = DateTime(2026, 10, 31, 10, 0);

  test('same local day: "today at <local time>"', () {
    final line = planResetLine(DateTime(2026, 10, 31, 23, 0).toUtc().toIso8601String(), now: now)!;
    expect(line.startsWith('Daily limits reset today at 11:00'), isTrue);
    expect(line.endsWith('PM.'), isTrue);
  });

  test('next local day: "tomorrow at <local time>"', () {
    final line = planResetLine(DateTime(2026, 11, 1, 1, 30).toUtc().toIso8601String(), now: now)!;
    expect(line.startsWith('Daily limits reset tomorrow at 1:30'), isTrue);
    expect(line.endsWith('AM.'), isTrue);
  });

  test('later than tomorrow names the date', () {
    final line = planResetLine(DateTime(2026, 11, 3, 8, 0).toUtc().toIso8601String(), now: now)!;
    expect(line.startsWith('Daily limits reset on Nov 3 at 8:00'), isTrue);
  });

  test('is English only, never says Beijing, and rejects a missing or unreadable instant', () {
    final line = planResetLine(DateTime(2026, 10, 31, 23, 0).toUtc().toIso8601String(), now: now)!;
    expect(cjk.hasMatch(line), isFalse);
    expect(line.contains('Beijing'), isFalse);
    expect(planResetLine(null), isNull);
    expect(planResetLine(''), isNull);
    expect(planResetLine('not a time'), isNull);
  });

  testWidgets('the page shows the reset time in local time instead of the Beijing note', (t) async {
    final at = DateTime.now().add(const Duration(hours: 3));
    await t.pumpWidget(MaterialApp(home: PlanUsagePage(load: () async => usage(resetsAt: at.toUtc().toIso8601String()))));
    await t.pumpAndSettle();
    final text = allText(t);
    expect(text, contains('Daily limits reset '));
    expect(text.contains('Beijing'), isFalse);
    expect(text.contains('16:00 UTC'), isFalse);
    expect(find.byKey(const Key('plan-usage-reset')), findsOneWidget);
  });

  testWidgets('without a reset instant the server note is still shown', (t) async {
    await t.pumpWidget(MaterialApp(home: PlanUsagePage(load: () async => usage())));
    await t.pumpAndSettle();
    expect(allText(t), contains('Daily limits reset at 00:00 Beijing time'));
  });
}
