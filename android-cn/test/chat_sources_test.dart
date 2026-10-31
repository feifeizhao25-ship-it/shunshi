import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/widgets/chat_sources.dart';

const bool zh = true;
final cjk = RegExp(r'[\u3400-\u9fff]');

List<Map<String, dynamic>> details() => [
      {'title': 'Sleep', 'source_file': 'a.md', 'reviewed_at': '2026-08-30', 'last_verified_at': '2026-08-30', 'valid_until': '2027-02-28', 'freshness': 'current', 'url': 'https://example.org/sleep'},
      {'title': 'Heat', 'last_verified_at': '2026-08-30', 'valid_until': '2026-11-30', 'freshness': 'review_due', 'url': 'javascript:alert(1)'},
      {'title': 'No date', 'freshness': 'current'},
    ];

Widget host(List<ChatSource> s, {Future<bool> Function(Uri)? opener}) =>
    MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: ChatSourcesBar(sources: s, opener: opener))));

String allText(WidgetTester t) => t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').join(' ');

void main() {
  test('parses source_details, falls back to reviewed_at, ignores junk', () {
    final s = ChatSource.parseAll([...details(), 'x', {'no': 'title'}, {'title': ' '}]);
    expect(s.map((e) => e.title), ['Sleep', 'Heat', 'No date']);
    expect(s[0].lastVerifiedAt, '2026-08-30');
    expect(ChatSource.parseAll({'reviewed_at': '2026-01-01', 'title': 'T'}), isEmpty, reason: 'not a list');
    expect(ChatSource.parseAll([{'title': 'T', 'reviewed_at': '2026-01-01'}]).single.lastVerifiedAt, '2026-01-01');
    expect(ChatSource.parseAll(null), isEmpty);
  });

  test('toJson round-trips through parseAll (chat history keeps the sources)', () {
    final s = ChatSource.parseAll(details());
    final back = ChatSource.parseAll(s.map((e) => e.toJson()).toList());
    expect([for (final e in back) e.toJson()], [for (final e in s) e.toJson()]);
  });

  test('only http(s) links are openable', () {
    final s = ChatSource.parseAll(details());
    expect([for (final e in s) e.hasSafeLink], [true, false, false]);
  });

  testWidgets('chips show the last-verified date and a review-due tag only when due', (t) async {
    await t.pumpWidget(host(ChatSource.parseAll(details())));
    expect(find.byKey(const Key('chat-source-verified-0')), findsOneWidget);
    expect(find.text(zh ? '最近核验：2026-08-30' : 'Last verified 2026-08-30'), findsNWidgets(2));
    expect(find.byKey(const Key('chat-source-due-0')), findsNothing);
    expect(find.byKey(const Key('chat-source-due-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-source-verified-2')), findsNothing, reason: 'no date sent, none invented');
    expect(cjk.hasMatch(allText(t)), zh);
  });

  testWidgets('empty list renders nothing', (t) async {
    await t.pumpWidget(host(const []));
    expect(find.byKey(const Key('chat-sources')), findsNothing);
  });

  testWidgets('tapping a chip shows details; the open button appears only for a safe link and calls the opener', (t) async {
    Uri? opened;
    await t.pumpWidget(host(ChatSource.parseAll(details()), opener: (u) async {
      opened = u;
      return true;
    }));
    await t.tap(find.byKey(const Key('chat-source-0')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-source-details')), findsOneWidget);
    expect(find.byKey(const Key('chat-source-detail-due')), findsNothing);
    await t.tap(find.byKey(const Key('chat-source-open')));
    expect(opened.toString(), 'https://example.org/sleep');
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('chat-source-1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-source-detail-due')), findsOneWidget);
    expect(find.byKey(const Key('chat-source-open')), findsNothing, reason: 'javascript: links are never offered');
  });

  testWidgets('chips have a screen-reader label with the date', (t) async {
    await t.pumpWidget(host(ChatSource.parseAll(details())));
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(zh ? '最近核验：2026-08-30' : 'Last verified 2026-08-30'))), findsNWidgets(2));
  });
}
