import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi_app/data/models/ai_response.dart';
import 'package:shunshi_app/data/models/care_status.dart';
import 'package:shunshi_app/data/models/follow_up_plan.dart';

void main() {
  group('AiResponse Schema Parse', () {
    test('parses valid full response', () {
      final json = {
        'text': '今天的建议：保持充足的睡眠，顺应节气养生。',
        'tone': 'gentle',
        'care_status': 'stable',
        'follow_up': {
          'in_days': 2,
          'intent': 'sleep_check',
        },
        'offline_encouraged': false,
        'presence_level': 'normal',
        'safety_flag': 'none',
        'cards': [
          {
            'type': 'acupoint',
            'content_id': 'content_002',
            'title': '足三里穴位按摩',
          }
        ],
      };

      final response = AiResponse.safeParse(json);

      expect(response.text, '今天的建议：保持充足的睡眠，顺应节气养生。');
      expect(response.tone, 'gentle');
      expect(response.careStatus, 'stable');
      expect(response.isSafe, isTrue);
      expect(response.presenceLevel, 'normal');
      expect(response.safetyFlag, 'none');
      expect(response.followUp, isNotNull);
      expect(response.followUp!.inDays, 2);
      expect(response.followUp!.intent, 'sleep_check');
      expect(response.cards, hasLength(1));
      expect(response.cards!.first.type, 'acupoint');
    });

    test('parses minimal valid response', () {
      final json = {
        'text': '你好。',
        'tone': 'gentle',
        'care_status': 'stable',
        'offline_encouraged': false,
        'presence_level': 'normal',
        'safety_flag': 'none',
      };

      final response = AiResponse.safeParse(json);
      expect(response.text, '你好。');
      expect(response.isSafe, isTrue);
      expect(response.followUp, isNull);
      expect(response.cards, isNull);
    });

    test('degrades gracefully when JSON is malformed', () {
      final json = {'broken': 'data'};
      final response = AiResponse.safeParse(json);

      // Degraded response should have empty text and safety_flag=sensitive
      expect(response.safetyFlag, 'sensitive');
      expect(response.needsSafeMode, isTrue);
    });

    test('degrades gracefully when response is a plain string', () {
      const rawText = '这是一段纯文字响应';
      final response = AiResponse.safeParse(rawText);

      expect(response.text, rawText);
      expect(response.safetyFlag, 'sensitive');
      expect(response.needsSafeMode, isTrue);
    });

    test('degrades gracefully when response is null', () {
      final response = AiResponse.safeParse(null);

      expect(response.safetyFlag, 'sensitive');
      expect(response.needsSafeMode, isTrue);
    });

    test('parses escalate care_status correctly', () {
      final json = {
        'text': '我感觉你现在可能需要更多支持。',
        'tone': 'gentle',
        'care_status': 'escalate',
        'offline_encouraged': true,
        'presence_level': 'normal',
        'safety_flag': 'sensitive',
      };

      final response = AiResponse.safeParse(json);
      expect(response.parsedCareStatus, CareStatus.escalate);
      expect(response.needsSafeMode, isTrue);
      expect(response.offlineEncouraged, isTrue);
    });

    test('presence_level reduced is detected', () {
      final json = {
        'text': '我会少一些主动问候。',
        'tone': 'gentle',
        'care_status': 'stable',
        'offline_encouraged': false,
        'presence_level': 'reduced',
        'safety_flag': 'none',
      };

      final response = AiResponse.safeParse(json);
      expect(response.isPresenceReduced, isTrue);
    });
  });

  group('FollowUpPlan', () {
    test('isDue returns false for future date', () {
      final plan = FollowUpPlan(
        inDays: 3,
        intent: 'sleep_check',
        scheduledAt: DateTime.now(),
      );

      // Due date = now + 3 days → not due yet
      expect(plan.isDue, isFalse);
    });

    test('isDue returns true for past due date', () {
      final plan = FollowUpPlan(
        inDays: 1,
        intent: 'emotion_check',
        scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // scheduled 2 days ago + in_days 1 = due 1 day ago
      final dueDate = plan.scheduledAt!.add(Duration(days: plan.inDays));
      expect(DateTime.now().isAfter(dueDate), isTrue);
    });

    test('intentLabel returns correct label', () {
      const plan = FollowUpPlan(inDays: 2, intent: 'sleep_check');
      expect(plan.intentLabel, '睡眠状况');

      const plan2 = FollowUpPlan(inDays: 1, intent: 'emotion_check');
      expect(plan2.intentLabel, '情绪状态');
    });
  });
}
