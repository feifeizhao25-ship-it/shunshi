// test/unit/entities/message_test.dart
// 聊天消息实体测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/message.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Message entity', () {
    test('fromJson 解析助手消息', () {
      final msg = Message.fromJson(ApiFixtures.message);

      expect(msg.id, 'msg_001');
      expect(msg.conversationId, 'conv_001');
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, contains('立春'));
      expect(msg.safetyFlag, SafetyFlag.none);
      expect(msg.careStatus, CareStatus.stable);
      expect(msg.tone, 'warm');
      expect(msg.isUser, isFalse);
      expect(msg.isAssistant, isTrue);
    });

    test('fromJson 解析用户消息', () {
      final msg = Message.fromJson(ApiFixtures.messageUser);

      expect(msg.role, MessageRole.user);
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
      expect(msg.content, '今天适合吃什么？');
    });

    test('fromJson 解析带卡片消息', () {
      final msg = Message.fromJson(ApiFixtures.messageWithCard);

      expect(msg.hasCard, isTrue);
      expect(msg.cardData, isNotNull);
      expect(msg.cardData!['card_type'], 'tea');
      expect(msg.cardData!['title'], '玫瑰花茶');
    });

    test('fromJson 解析被拦截消息', () {
      final msg = Message.fromJson(ApiFixtures.messageBlocked);

      expect(msg.safetyFlag, SafetyFlag.blocked);
      expect(msg.careStatus, CareStatus.attention);
      expect(msg.content, isEmpty);
    });

    test('无卡片时 hasCard 为 false', () {
      final msg = Message.fromJson(ApiFixtures.message);
      expect(msg.hasCard, isFalse);
    });

    test('toJson 正确序列化', () {
      final msg = Message.fromJson(ApiFixtures.message);
      final json = msg.toJson();

      expect(json['id'], msg.id);
      expect(json['role'], 'assistant');
      expect(json['safety_flag'], 'none');
    });

    test('round-trip: fromJson → toJson → fromJson 一致', () {
      final original = Message.fromJson(ApiFixtures.messageWithCard);
      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.safetyFlag, original.safetyFlag);
    });

    test('copyWith 更新内容', () {
      final msg = Message.fromJson(ApiFixtures.message);
      final updated = msg.copyWith(content: '新回复', isStreaming: true);

      expect(updated.content, '新回复');
      expect(updated.isStreaming, isTrue);
      expect(updated.id, msg.id); // 不变
    });

    test('unknown role defaults to user', () {
      final json = Map<String, dynamic>.from(ApiFixtures.message);
      json['role'] = 'nonexistent_role';
      final msg = Message.fromJson(json);

      expect(msg.role, MessageRole.user);
    });
  });
}
