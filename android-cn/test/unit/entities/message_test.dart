// test/unit/entities/message_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/message.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Message entity', () {
    test('fromJson creates message correctly', () {
      final msg = Message.fromJson(ApiFixtures.message);

      expect(msg.id, 'msg_001');
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, contains('立春'));
      expect(msg.safetyFlag, SafetyFlag.none);
      expect(msg.careStatus, CareStatus.stable);
      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);
    });

    test('message with card data is detected', () {
      final msg = Message.fromJson(ApiFixtures.messageWithCard);
      expect(msg.hasCard, isTrue);
      expect(msg.cardData?['card_type'], 'tea');
      expect(msg.cardData?['title'], '玫瑰花茶');
    });

    test('copyWith updates content for streaming', () {
      final msg = Message.fromJson(ApiFixtures.message);
      final streaming = msg.copyWith(
        content: msg.content + '...',
        isStreaming: true,
      );
      expect(streaming.isStreaming, isTrue);
      expect(streaming.id, msg.id);
    });

    test('toJson round-trip preserves data', () {
      final msg = Message.fromJson(ApiFixtures.message);
      final json = msg.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, msg.id);
      expect(restored.content, msg.content);
      expect(restored.role, msg.role);
    });

    test('safety flag blocked is parsed', () {
      final json = Map<String, dynamic>.from(ApiFixtures.message);
      json['safety_flag'] = 'blocked';
      final msg = Message.fromJson(json);
      expect(msg.safetyFlag, SafetyFlag.blocked);
    });
  });
}
