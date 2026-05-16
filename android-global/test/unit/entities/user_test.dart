// test/unit/entities/user_test.dart
// Global SEASONS User entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/user.dart';

void main() {
  group('User entity', () {
    test('creates with required fields', () {
      final user = User(
        id: 'user_001',
        email: 'test@example.com',
      );

      expect(user.id, 'user_001');
      expect(user.email, 'test@example.com');
      expect(user.subscription, SubscriptionTier.free);
    });

    test('creates with all fields', () {
      final user = User(
        id: 'user_002',
        email: 'premium@example.com',
        name: 'Premium User',
        avatarUrl: 'https://example.com/avatar.png',
        country: 'US',
        subscription: SubscriptionTier.serenity,
        createdAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 5, 15),
        preferences: {'theme': 'dark'},
      );

      expect(user.name, 'Premium User');
      expect(user.country, 'US');
      expect(user.subscription, SubscriptionTier.serenity);
    });

    test('SubscriptionTier values', () {
      expect(SubscriptionTier.values.length, 5);
      expect(SubscriptionTier.values, containsAll([
        SubscriptionTier.free,
        SubscriptionTier.serenity,
        SubscriptionTier.harmony,
        SubscriptionTier.family,
        SubscriptionTier.premium,
      ]));
    });

    test('default subscription is free', () {
      final user = User(id: 'test', email: 'test@test.com');
      expect(user.subscription, SubscriptionTier.free);
    });
  });
}
