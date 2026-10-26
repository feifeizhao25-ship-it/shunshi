import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/chat/chat_history_codec.dart';
import 'package:shunshi/presentation/pages/chat/chat_models.dart';

void main() {
  test('round trips 25 multiline messages without truncation', () {
    final messages = List.generate(
      25,
      (i) => ChatMessage(
        role: i.isEven ? 'user' : 'ai',
        text: '第$i条\n第二段|分隔符\n\nuser|正文\n"引号"😀',
        time: '12:34',
      ),
    );
    final restored = decodeChatHistory(encodeChatHistory(messages));
    expect(restored.length, 25);
    for (var i = 0; i < messages.length; i++) {
      expect(restored[i].text, messages[i].text);
      expect(restored[i].role, messages[i].role);
      expect(restored[i].time, messages[i].time);
    }
  });
  test('preserves sources and complete cards', () {
    final restored = decodeChatHistory(
      encodeChatHistory([
        ChatMessage(
          role: 'ai',
          text: '正文',
          time: '09:00',
          sources: ['来源一', 'https://example.cn'],
          cards: [
            SuggestionCard(type: 'diet', title: '建议', subtitle: '第一段\n第二段'),
          ],
        ),
      ]),
    );
    expect(restored.single.sources, ['来源一', 'https://example.cn']);
    expect(restored.single.cards!.single.subtitle, '第一段\n第二段');
  });
  test('migrates legacy multiline messages beyond ten rows', () {
    final legacy = List.generate(
      15,
      (i) => 'user|第$i条\nai|回复$i\n继续回复$i',
    ).join('\n');
    final restored = decodeChatHistory(legacy);
    expect(restored.length, 30);
    expect(restored.last.text, '回复14\n继续回复14');
    expect(
      decodeChatHistory(encodeChatHistory(restored)).last.text,
      restored.last.text,
    );
  });
  test('damaged data does not crash', () {
    for (final raw in [
      null,
      '',
      '{broken',
      '{"version":2,"messages":[]}',
      '{"version":1,"messages":[null]}',
    ]) {
      expect(decodeChatHistory(raw), isEmpty);
    }
  });
}
