// test/integration/chat_flow_test.dart
// 聊天流程集成测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/message.dart';
import 'package:shunshi/core/security/safety_filter.dart';
import '../fixtures/api_responses.dart';

void main() {
  group('Chat Flow', () {
    test('用户发送消息 → 助手回复', () {
      final userMsg = Message.fromJson(ApiFixtures.messageUser);
      final assistantMsg = Message.fromJson(ApiFixtures.message);

      expect(userMsg.isUser, isTrue);
      expect(assistantMsg.isAssistant, isTrue);
      expect(userMsg.conversationId, assistantMsg.conversationId);
    });

    test('助手回复带推荐卡片', () {
      final msg = Message.fromJson(ApiFixtures.messageWithCard);

      expect(msg.hasCard, isTrue);
      expect(msg.cardData!['card_type'], 'tea');
      expect(msg.cardData!['ingredients'], isA<List>());
    });

    test('安全过滤 — 正常消息通过', () async {
      final filter = SafetyFilter();
      final result = await filter.check('今天适合做什么运动？');

      expect(result.isSafe, isTrue);
      expect(result.flag, 'none');
    });

    test('安全过滤 — 敏感消息被拦截', () async {
      final filter = SafetyFilter();
      final result = await filter.check('我想自杀');

      expect(result.isSafe, isFalse);
      expect(result.flag, 'sensitive');
    });

    test('安全过滤 — 医疗问题标记 caution', () async {
      final filter = SafetyFilter();
      final result = await filter.check('帮我诊断一下');

      expect(result.isSafe, isTrue);
      expect(result.flag, 'caution');
      expect(result.needsDoctorConsult, isTrue);
    });

    test('被拦截消息标记正确', () {
      final msg = Message.fromJson(ApiFixtures.messageBlocked);

      expect(msg.safetyFlag, SafetyFlag.blocked);
      expect(msg.careStatus, CareStatus.attention);
    });

    test('消息序列化循环一致', () {
      final messages = [
        ApiFixtures.message,
        ApiFixtures.messageUser,
        ApiFixtures.messageWithCard,
      ];

      for (final fixture in messages) {
        final original = Message.fromJson(fixture);
        final json = original.toJson();
        final restored = Message.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.role, original.role);
        expect(restored.content, original.content);
      }
    });
  });
}
