// test/unit/entities/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/user.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('User entity', () {
    test('fromJson creates user correctly', () {
      final user = User.fromJson(ApiFixtures.user);

      expect(user.id, 'user_test_001');
      expect(user.phone, '13800138000');
      expect(user.name, '测试用户');
      expect(user.subscription, SubscriptionTier.free);
      expect(user.constitution, ConstitutionType.balanced);
      expect(user.hemisphere, 'north');
      expect(user.aiMemoryEnabled, isTrue);
      expect(user.isPremium, isFalse);
    });

    test('isPremium is true for premium tier', () {
      final user = User.fromJson(ApiFixtures.userPremium);
      expect(user.isPremium, isTrue);
      expect(user.subscription, SubscriptionTier.premium);
    });

    test('constitutionName returns correct Chinese name', () {
      final user = User.fromJson(ApiFixtures.user);
      expect(user.constitutionName, '平和质');

      final qiUser = User.fromJson(ApiFixtures.userPremium);
      expect(qiUser.constitutionName, '气虚质');
    });

    test('copyWith updates only specified fields', () {
      final user = User.fromJson(ApiFixtures.user);
      final updated = user.copyWith(name: '新名字', subscription: SubscriptionTier.premium);

      expect(updated.id, user.id);
      expect(updated.name, '新名字');
      expect(updated.subscription, SubscriptionTier.premium);
      expect(updated.constitution, user.constitution); // unchanged
    });

    test('toJson serializes correctly', () {
      final user = User.fromJson(ApiFixtures.user);
      final json = user.toJson();

      expect(json['id'], user.id);
      expect(json['hemisphere'], user.hemisphere);
      expect(json['constitution'], user.constitution.name);
    });

    test('unknown constitution defaults correctly', () {
      final json = Map<String, dynamic>.from(ApiFixtures.user);
      json['constitution'] = 'nonexistent_value';
      final user = User.fromJson(json);
      expect(user.constitution, ConstitutionType.unknown);
    });
  });
}
