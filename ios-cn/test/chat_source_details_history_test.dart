import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/presentation/pages/chat/chat_history_codec.dart';
import 'package:shunshi/presentation/pages/chat/chat_models.dart';
import 'package:shunshi/presentation/widgets/chat_sources.dart';

void main() {
  test('structured sources survive saving and restoring the chat history', () {
    final restored = decodeChatHistory(
      encodeChatHistory([
        ChatMessage(
          role: 'ai',
          text: '正文',
          time: '09:00',
          sources: const ['睡眠｜官方资料已核验'],
          sourceDetails: const [
            ChatSource(title: '睡眠与光照', lastVerifiedAt: '2026-08-30', validUntil: '2026-11-30', freshness: 'review_due', url: 'https://example.cn/x'),
          ],
        ),
      ]),
    );
    final d = restored.single.sourceDetails!.single;
    expect(d.title, '睡眠与光照');
    expect(d.lastVerifiedAt, '2026-08-30');
    expect(d.reviewDue, isTrue);
    expect(restored.single.sources, ['睡眠｜官方资料已核验']);
  });

  test('old saved histories without source_details still load', () {
    final restored = decodeChatHistory(encodeChatHistory([ChatMessage(role: 'ai', text: '正文', time: '09:00', sources: const ['x'])]));
    expect(restored.single.sourceDetails, anyOf(isNull, isEmpty));
  });
}
