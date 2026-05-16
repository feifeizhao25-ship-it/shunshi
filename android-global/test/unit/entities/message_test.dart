// test/unit/entities/message_test.dart
// Global SEASONS Message entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/message.dart';

void main() {
  group('Message entity', () {
    test('creates with required fields', () {
      final msg = Message(
        id: 'msg_001',
        conversationId: 'conv_001',
        content: 'Hello!',
        role: MessageRole.user,
        timestamp: DateTime(2026, 5, 15),
        metadata: {},
      );

      expect(msg.id, 'msg_001');
      expect(msg.conversationId, 'conv_001');
      expect(msg.content, 'Hello!');
      expect(msg.role, MessageRole.user);
    });

    test('MessageRole has all values', () {
      expect(MessageRole.values.length, 3);
      expect(MessageRole.values, containsAll([
        MessageRole.user,
        MessageRole.assistant,
        MessageRole.system,
      ]));
    });

    test('user and assistant messages', () {
      final userMsg = Message(
        id: 'msg_u',
        conversationId: 'c1',
        content: 'Question',
        role: MessageRole.user,
        timestamp: DateTime(2026, 5, 15),
        metadata: {},
      );

      final aiMsg = Message(
        id: 'msg_a',
        conversationId: 'c1',
        content: 'Answer',
        role: MessageRole.assistant,
        timestamp: DateTime(2026, 5, 15),
        metadata: {},
      );

      expect(userMsg.role, MessageRole.user);
      expect(aiMsg.role, MessageRole.assistant);
      expect(userMsg.conversationId, aiMsg.conversationId);
    });
  });
}
