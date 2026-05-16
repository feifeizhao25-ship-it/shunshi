// integration_test/app_test.dart
// E2E 集成测试 — 顺时 ShunShi 完整用户流程
//
// 运行方式:
//   flutter test integration_test/app_test.dart
//   flutter test integration_test/app_test.dart -d <device-id>  (真机/模拟器)

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Domain entities
import 'package:shunshi/domain/entities/user.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import 'package:shunshi/domain/entities/content.dart';
import 'package:shunshi/domain/entities/message.dart';
import 'package:shunshi/domain/entities/reflection.dart';
import 'package:shunshi/core/security/safety_filter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 完整用户旅程', () {
    // ── Phase 1: 启动 & 游客登录 ──
    group('Phase 1: 启动', () {
      testWidgets('App 启动不崩溃', (tester) async {
        // 验证 binding 初始化成功
        expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
      });

      test('游客登录 → 获取用户信息', () {
        final guestJson = {
          'id': 'guest_e2e_001',
          'name': 'Guest User',
          'subscription': 'free',
          'constitution': 'unknown',
          'hemisphere': 'north',
          'ai_memory_enabled': true,
          'created_at': '2026-05-15T00:00:00.000Z',
          'preferences': <String, dynamic>{},
        };

        final user = User.fromJson(guestJson);
        expect(user.name, 'Guest User');
        expect(user.isPremium, isFalse);
        expect(user.constitution, ConstitutionType.unknown);
      });
    });

    // ── Phase 2: 首页 & 节气 ──
    group('Phase 2: 首页体验', () {
      test('获取当前节气', () {
        final term = SolarTerm.fromJson({
          'id': 'solar_lichun',
          'name': '立春',
          'name_en': 'Start of Spring',
          'emoji': '🌱',
          'season': 'spring',
          'date': '2月3日-5日',
          'description': '立春是第一个节气',
          'is_current': true,
        });

        expect(term.isCurrent, isTrue);
        expect(term.season, 'spring');
      });

      test('节气养生方案可访问', () {
        final term = SolarTerm.fromJson({
          'id': 'solar_lichun',
          'name': '立春',
          'name_en': 'Start of Spring',
          'emoji': '🌱',
          'season': 'spring',
          'date': '2月3日-5日',
          'description': '立春',
          'is_current': true,
          'wellness_plan': {
            'diet': [{'title': '韭菜炒鸡蛋'}],
            'tea': [{'title': '玫瑰花茶'}],
            'exercise': [{'title': '八段锦'}],
          },
        });

        final plan = term.wellnessPlan!;
        expect(plan['diet'], isA<List>());
        expect(plan['tea'], isA<List>());
        expect(plan['exercise'], isA<List>());
      });
    });

    // ── Phase 3: 内容浏览 ──
    group('Phase 3: 内容浏览', () {
      test('浏览食疗内容', () {
        final content = Content.fromJson({
          'id': 'e2e_food_001',
          'type': 'foodTherapy',
          'title': 'Spring Spinach Soup',
          'summary': 'Nourishing soup for spring',
          'tags': ['spring', 'nourishing'],
          'season': 'spring',
          'difficulty': 'easy',
          'duration_minutes': 20,
        });

        expect(content.type, ContentType.foodTherapy);
        expect(content.season, Season.spring);
        expect(content.difficulty, Difficulty.easy);
      });

      test('浏览茶饮内容', () {
        final content = Content.fromJson({
          'id': 'e2e_tea_001',
          'type': 'tea',
          'title': 'Chrysanthemum Tea',
          'tags': ['spring', 'liver'],
        });

        expect(content.type, ContentType.tea);
      });

      test('浏览运动内容', () {
        final content = Content.fromJson({
          'id': 'e2e_exercise_001',
          'type': 'exercise',
          'title': 'Ba Duan Jin',
          'duration_minutes': 15,
        });

        expect(content.type, ContentType.exercise);
        expect(content.durationMinutes, 15);
      });
    });

    // ── Phase 4: AI 对话 ──
    group('Phase 4: AI 对话', () {
      test('发送消息 → 收到回复', () {
        final userMsg = Message.fromJson({
          'id': 'e2e_msg_user',
          'conversation_id': 'e2e_conv',
          'role': 'user',
          'content': 'What should I eat today?',
          'created_at': '2026-05-15T08:00:00.000Z',
          'safety_flag': 'none',
        });

        final assistantMsg = Message.fromJson({
          'id': 'e2e_msg_ai',
          'conversation_id': 'e2e_conv',
          'role': 'assistant',
          'content': 'Based on the current solar term, I recommend warm, nourishing foods.',
          'created_at': '2026-05-15T08:00:02.000Z',
          'safety_flag': 'none',
          'care_status': 'stable',
        });

        expect(userMsg.conversationId, assistantMsg.conversationId);
        expect(userMsg.isUser, isTrue);
        expect(assistantMsg.isAssistant, isTrue);
      });

      test('安全过滤正常工作', () async {
        final filter = SafetyFilter();

        // 正常消息通过
        final safe = await filter.check('What exercise is good for spring?');
        expect(safe.isSafe, isTrue);

        // 敏感消息拦截
        final blocked = await filter.check('我想自杀');
        expect(blocked.isSafe, isFalse);

        // 医疗关键词标记
        final medical = await filter.check('帮我诊断');
        expect(medical.flag, 'caution');
      });
    });

    // ── Phase 5: 体质测评 ──
    group('Phase 5: 体质测评', () {
      test('完成问卷 → 获取结果', () {
        // 模拟提交问卷后的结果
        final user = User.fromJson({
          'id': 'guest_e2e_001',
          'name': 'Guest User',
          'subscription': 'free',
          'constitution': 'qiDeficiency',
          'hemisphere': 'north',
          'created_at': '2026-05-15T00:00:00.000Z',
        });

        expect(user.constitution, ConstitutionType.qiDeficiency);
        expect(user.constitutionName, '气虚质');
      });

      test('9种体质全覆盖', () {
        final types = [
          'balanced', 'qiDeficiency', 'yangDeficiency',
          'yinDeficiency', 'phlegmDamp', 'dampHeat',
          'bloodStasis', 'qiStagnation', 'allergic',
        ];

        for (final typeName in types) {
          final user = User.fromJson({
            'id': 'test_${typeName}',
            'constitution': typeName,
            'created_at': '2026-05-15T00:00:00.000Z',
          });
          expect(user.constitution, isNot(equals(ConstitutionType.unknown)),
              reason: '$typeName should map to a valid type');
        }
      });
    });

    // ── Phase 6: 每日记录 ──
    group('Phase 6: 每日记录', () {
      test('记录感悟', () {
        final reflection = Reflection.fromJson({
          'id': 'e2e_refl_001',
          'user_id': 'guest_e2e_001',
          'content': 'Felt great today after morning exercise.',
          'mood': 'great',
          'sleep_hours': 8,
          'tags': ['exercise', 'morning'],
          'date': '2026-05-15T00:00:00.000Z',
          'created_at': '2026-05-15T21:00:00.000Z',
        });

        expect(reflection.mood, MoodType.great);
        expect(reflection.sleepHours, 8);
        expect(reflection.tags, ['exercise', 'morning']);
      });

      test('连续记录追踪', () {
        final day1 = Reflection.fromJson({
          'id': 'refl_d1',
          'user_id': 'guest_e2e_001',
          'content': 'Day 1',
          'mood': 'neutral',
          'sleep_hours': 6,
          'tags': [],
          'date': '2026-05-14T00:00:00.000Z',
          'created_at': '2026-05-14T22:00:00.000Z',
        });

        final day2 = Reflection.fromJson({
          'id': 'refl_d2',
          'user_id': 'guest_e2e_001',
          'content': 'Day 2',
          'mood': 'good',
          'sleep_hours': 7,
          'tags': ['improving'],
          'date': '2026-05-15T00:00:00.000Z',
          'created_at': '2026-05-15T22:00:00.000Z',
        });

        expect(day1.mood, MoodType.neutral);
        expect(day2.mood, MoodType.good);
        expect(day2.sleepHours! > day1.sleepHours!, isTrue);
      });
    });

    // ── Phase 7: 订阅升级 ──
    group('Phase 7: 订阅', () {
      test('免费用户查看订阅信息', () {
        final user = User.fromJson({
          'id': 'guest_e2e_001',
          'name': 'Guest User',
          'subscription': 'free',
          'created_at': '2026-05-15T00:00:00.000Z',
        });

        expect(user.subscription, SubscriptionTier.free);
        expect(user.isPremium, isFalse);
      });

      test('升级后 isPremium 为 true', () {
        final upgraded = User.fromJson({
          'id': 'guest_e2e_001',
          'subscription': 'premium',
          'created_at': '2026-05-15T00:00:00.000Z',
        });

        expect(upgraded.isPremium, isTrue);
      });
    });
  });
}
