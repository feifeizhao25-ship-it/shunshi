// test/unit/entities/user_test.dart
// 用户实体测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/user.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('User entity', () {
    test('fromJson 创建普通用户', () {
      final user = User.fromJson(ApiFixtures.user);

      expect(user.id, 'user_test_001');
      expect(user.phone, '13800138000');
      expect(user.name, '测试用户');
      expect(user.subscription, SubscriptionTier.free);
      expect(user.constitution, ConstitutionType.balanced);
      expect(user.hemisphere, 'north');
      expect(user.aiMemoryEnabled, isTrue);
      expect(user.isPremium, isFalse);
      expect(user.isFamilyPlan, isFalse);
    });

    test('premium 用户 isPremium 为 true', () {
      final user = User.fromJson(ApiFixtures.userPremium);
      expect(user.isPremium, isTrue);
      expect(user.subscription, SubscriptionTier.premium);
      expect(user.constitution, ConstitutionType.qiDeficiency);
    });

    test('family 用户', () {
      final user = User.fromJson(ApiFixtures.userFamily);
      expect(user.subscription, SubscriptionTier.family);
      expect(user.isFamilyPlan, isTrue);
      expect(user.isPremium, isTrue); // family != free
      expect(user.constitution, ConstitutionType.yinDeficiency);
      expect(user.hemisphere, 'south');
      expect(user.aiMemoryEnabled, isFalse);
    });

    test('邮箱用户', () {
      final user = User.fromJson(ApiFixtures.userWithEmail);
      expect(user.email, 'test@example.com');
      expect(user.subscription, SubscriptionTier.standard);
      expect(user.constitution, ConstitutionType.phlegmDamp);
    });

    test('constitutionName 返回正确中文名', () {
      final user = User.fromJson(ApiFixtures.user);
      expect(user.constitutionName, '平和质');

      final qiUser = User.fromJson(ApiFixtures.userPremium);
      expect(qiUser.constitutionName, '气虚质');
    });

    test('所有体质类型的中文名', () {
      final names = {
        ConstitutionType.balanced: '平和质',
        ConstitutionType.qiDeficiency: '气虚质',
        ConstitutionType.yangDeficiency: '阳虚质',
        ConstitutionType.yinDeficiency: '阴虚质',
        ConstitutionType.phlegmDamp: '痰湿质',
        ConstitutionType.dampHeat: '湿热质',
        ConstitutionType.bloodStasis: '血瘀质',
        ConstitutionType.qiStagnation: '气郁质',
        ConstitutionType.allergic: '特禀质',
        ConstitutionType.unknown: '未识别',
      };

      for (final entry in names.entries) {
        final json = Map<String, dynamic>.from(ApiFixtures.user);
        json['constitution'] = entry.key.name;
        final user = User.fromJson(json);
        expect(user.constitutionName, entry.value, reason: '${entry.key.name}');
      }
    });

    test('copyWith 仅更新指定字段', () {
      final user = User.fromJson(ApiFixtures.user);
      final updated = user.copyWith(name: '新名字', subscription: SubscriptionTier.premium);

      expect(updated.id, user.id);
      expect(updated.name, '新名字');
      expect(updated.subscription, SubscriptionTier.premium);
      expect(updated.constitution, user.constitution);
    });

    test('toJson 正确序列化', () {
      final user = User.fromJson(ApiFixtures.user);
      final json = user.toJson();

      expect(json['id'], user.id);
      expect(json['hemisphere'], user.hemisphere);
      expect(json['subscription'], 'free');
      expect(json['constitution'], 'balanced');
    });

    test('未知 constitution 默认为 unknown', () {
      final json = Map<String, dynamic>.from(ApiFixtures.user);
      json['constitution'] = 'nonexistent_value';
      final user = User.fromJson(json);
      expect(user.constitution, ConstitutionType.unknown);
    });

    test('ConstitutionType 枚举完整 (9+1)', () {
      expect(ConstitutionType.values.length, 10);
    });

    test('SubscriptionTier 枚举完整 (4)', () {
      expect(SubscriptionTier.values.length, 4);
      expect(SubscriptionTier.values, containsAll([
        SubscriptionTier.free,
        SubscriptionTier.standard,
        SubscriptionTier.premium,
        SubscriptionTier.family,
      ]));
    });
  });
}
