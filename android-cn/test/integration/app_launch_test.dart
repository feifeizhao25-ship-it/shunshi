// test/integration/app_launch_test.dart
// 应用启动集成测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/user.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import 'package:shunshi/domain/entities/content.dart';
import '../fixtures/api_responses.dart';

void main() {
  group('App Launch Flow', () {
    test('游客登录获取用户信息', () {
      final response = ApiFixtures.guestLoginResponse;
      final user = User.fromJson(response['user'] as Map<String, dynamic>);

      expect(user.name, 'Guest User');
      expect(user.subscription, SubscriptionTier.free);
      expect(user.constitution, ConstitutionType.unknown);
    });

    test('启动时获取当前节气', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);

      expect(term.isCurrent, isTrue);
      expect(term.name, '立春');
    });

    test('获取每日建议', () {
      final advice = ApiFixtures.dailyAdviceResponse;

      expect(advice['greeting'], isNotNull);
      expect(advice['solar_term'], isNotNull);
      expect(advice['advice'], isA<List>());
      expect((advice['advice'] as List).length, 3);
    });

    test('获取内容列表', () {
      final response = ApiFixtures.contentsResponse;

      expect(response['total'], 2);
      final items = response['items'] as List;
      expect(items.length, 2);

      final content = Content.fromJson(items[0] as Map<String, dynamic>);
      expect(content.type, ContentType.foodTherapy);
    });

    test('健康检查', () {
      final health = ApiFixtures.healthResponse;

      expect(health['status'], 'healthy');
      expect(health['services']['database'], 'ok');
      expect(health['services']['redis'], 'ok');
    });

    test('完整启动流程: 登录 → 节气 → 内容', () {
      // Step 1: 游客登录
      final user = User.fromJson(
        (ApiFixtures.guestLoginResponse['user'] as Map<String, dynamic>),
      );
      expect(user.id, isNotEmpty);

      // Step 2: 获取节气
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      expect(term.isCurrent, isTrue);

      // Step 3: 获取内容
      final items = ApiFixtures.contentsResponse['items'] as List;
      expect(items.isNotEmpty, isTrue);

      final content = Content.fromJson(items[0] as Map<String, dynamic>);
      expect(content.title, isNotEmpty);
    });
  });
}
