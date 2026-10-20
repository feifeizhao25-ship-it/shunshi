import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shunshi/presentation/pages/chat/chat_widgets.dart';
import 'package:shunshi/presentation/pages/chat/chat_history_codec.dart';
import 'package:shunshi/presentation/pages/chat/chat_models.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('restored full reply and cards render at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final text = List.generate(30, (i) => '第$i段完整正文，包含分隔符|和换行。').join('\n\n');
      final subtitle = List.generate(10, (i) => '建议$i：保留完整建议内容。').join('\n');
      final restored = decodeChatHistory(
        encodeChatHistory([
          ChatMessage(
            role: 'ai',
            text: text,
            time: '10:00',
            sources: ['来源一'],
            cards: [
              SuggestionCard(type: 'diet', title: '饮食建议', subtitle: subtitle),
            ],
          ),
        ]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIBubble(message: restored.single),
            ),
          ),
        ),
      );
      for (final fullText in [text, subtitle]) {
        expect(find.text(fullText), findsOneWidget);
        final widget = tester.widget<Text>(find.text(fullText));
        expect(widget.maxLines, isNull);
        expect(widget.overflow, isNot(TextOverflow.ellipsis));
      }
      await tester.ensureVisible(find.text('来源一'));
      await tester.pumpAndSettle();
      expect(find.text('来源一').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
