import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/settings/plan_usage_page.dart';

const bool zh = false;
final cjk = RegExp(r'[\u3400-\u9fff]');

Map<String, dynamic> usage({bool active = false, int? chatUsed = 4, bool chatKnown = true, bool unlimitedReflections = false}) => {
      'plan': active ? 'yiyang' : 'free',
      'plan_name': active ? (zh ? '会员' : 'Member') : (zh ? '免费版' : 'Free'),
      'active': active,
      'expires_at': active ? 1798675200 : null,
      'reset_note': zh ? '每日额度于北京时间零点重置。' : 'Daily limits reset at 00:00 Beijing time (16:00 UTC).',
      'items': [
        {'key': 'chat_messages', 'limit': 20, 'unlimited': false, 'used': chatUsed, 'used_known': chatKnown, 'remaining': chatKnown && chatUsed != null ? 20 - chatUsed : null, 'unit': 'messages'},
        {'key': 'reflections', 'limit': unlimitedReflections ? null : 3, 'unlimited': unlimitedReflections, 'used': 1, 'used_known': true, 'remaining': unlimitedReflections ? null : 2, 'unit': 'entries'},
        {'key': 'audio_minutes', 'limit': 30, 'unlimited': false, 'used': null, 'used_known': false, 'remaining': null, 'unit': 'minutes'},
      ],
    };

Widget host(Future<Map<String, dynamic>> Function() load, {VoidCallback? onUpgrade}) => MaterialApp(home: PlanUsagePage(load: load, onUpgrade: onUpgrade));

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').join(' ');

void main() {
  testWidgets('free plan: real numbers, remaining, reset note and an upgrade button', (t) async {
    var upgraded = false;
    await t.pumpWidget(host(() async => usage(), onUpgrade: () => upgraded = true));
    await t.pumpAndSettle();
    expect(find.text(zh ? '免费版' : 'Free'), findsWidgets);
    expect(find.byKey(const Key('plan-usage-summary-chat_messages')), findsOneWidget);
    expect(find.text(zh ? '已用 4 / 20' : '4 of 20 used'), findsOneWidget);
    expect(find.text(zh ? '剩余 16' : '16 left'), findsOneWidget);
    expect(find.byKey(const Key('plan-usage-reset')), findsOneWidget);
    await t.tap(find.byKey(const Key('plan-usage-upgrade')));
    expect(upgraded, isTrue);
    expect(cjk.hasMatch(allText(t)), zh);
  });

  testWidgets('unknown usage is shown as unavailable, never as zero; audio has a limit only', (t) async {
    await t.pumpWidget(host(() async => usage(chatKnown: false, chatUsed: null)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan-usage-unknown-chat_messages')), findsOneWidget);
    expect(find.text(zh ? '已用 0 / 20' : '0 of 20 used'), findsNothing);
    expect(find.text(zh ? '每天最多 30' : 'Up to 30 per day'), findsOneWidget);
  });

  testWidgets('paid plan shows the expiry date and no upgrade button; unlimited rows say so', (t) async {
    await t.pumpWidget(host(() async => usage(active: true, unlimitedReflections: true), onUpgrade: () {}));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan-usage-upgrade')), findsNothing);
    expect(find.text(zh ? '不限' : 'Unlimited'), findsOneWidget);
    expect(allText(t), contains('2026-12-31'.substring(0, 4)));
  });

  testWidgets('loading then error with retry that recovers', (t) async {
    var calls = 0;
    await t.pumpWidget(host(() async {
      calls++;
      if (calls == 1) throw Exception('offline');
      return usage();
    }));
    expect(find.byKey(const Key('plan-usage-loading')), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan-usage-error')), findsOneWidget);
    await t.tap(find.byKey(const Key('plan-usage-retry')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan-usage-error')), findsNothing);
    expect(find.byKey(const Key('plan-usage-row-chat_messages')), findsOneWidget);
  });

  testWidgets('rows have a combined screen-reader label', (t) async {
    await t.pumpWidget(host(() async => usage()));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(zh ? '今日 AI 对话. 已用 4 / 20' : 'AI chat messages today. 4 of 20 used'))), findsOneWidget);
  });
}
