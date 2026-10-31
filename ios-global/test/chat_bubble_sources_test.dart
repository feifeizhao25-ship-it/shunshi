import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/pages/chat/chat_models.dart';
import 'package:seasons/presentation/pages/chat/chat_widgets.dart';
import 'package:seasons/presentation/widgets/chat_sources.dart';

Widget host(ChatMessage m) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AIBubble(message: m))));

void main() {
  testWidgets('AI bubble shows structured sources with the last-verified date', (t) async {
    final m = ChatMessage(
      role: 'ai',
      text: 'reply',
      time: '10:00',
      sources: const ['plain label'],
      sourceDetails: [const ChatSource(title: 'Sleep and light', lastVerifiedAt: '2026-08-30', validUntil: '2027-02-28')],
    );
    await t.pumpWidget(host(m));
    expect(find.byKey(const Key('chat-sources')), findsOneWidget);
    expect(find.byKey(const Key('chat-source-verified-0')), findsOneWidget);
    expect(find.text('plain label'), findsNothing, reason: 'structured sources replace the plain label list');
  });

  testWidgets('without structured sources the plain labels still show', (t) async {
    await t.pumpWidget(host(ChatMessage(role: 'ai', text: 'reply', time: '10:00', sources: const ['plain label'])));
    expect(find.byKey(const Key('chat-sources')), findsNothing);
    expect(find.text('plain label'), findsOneWidget);
  });

  testWidgets('no sources, no source row', (t) async {
    await t.pumpWidget(host(ChatMessage(role: 'ai', text: 'reply', time: '10:00')));
    expect(find.byKey(const Key('chat-sources')), findsNothing);
  });
}
