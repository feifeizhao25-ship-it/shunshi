import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/user.dart';

void main() {
  group('User', () {
    test('creates a user with required fields', () {
      const user = User(
        id: 'usr_001',
        email: 'jane@example.com',
      );

      expect(user.id, 'usr_001');
      expect(user.email, 'jane@example.com');
      expect(user.name, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.country, isNull);
      expect(user.subscription, SubscriptionTier.free);
      expect(user.createdAt, isNull);
      expect(user.lastActiveAt, isNull);
      expect(user.preferences, isEmpty);
    });

    test('creates a user with all optional fields', () {
      final createdAt = DateTime(2025, 1, 15);
      final lastActive = DateTime(2025, 3, 20);

      final user = User(
        id: 'usr_001',
        email: 'jane@example.com',
        name: 'Jane',
        avatarUrl: 'https://cdn.example.com/avatar.jpg',
        country: 'US',
        subscription: SubscriptionTier.serenity,
        createdAt: createdAt,
        lastActiveAt: lastActive,
        preferences: {'theme': 'dark', 'notifications_enabled': true},
      );

      expect(user.name, 'Jane');
      expect(user.avatarUrl, 'https://cdn.example.com/avatar.jpg');
      expect(user.country, 'US');
      expect(user.subscription, SubscriptionTier.serenity);
      expect(user.createdAt, createdAt);
      expect(user.lastActiveAt, lastActive);
      expect(user.preferences['theme'], 'dark');
      expect(user.preferences['notifications_enabled'], true);
    });

    test('copyWith creates a new user with updated fields', () {
      const original = User(
        id: 'usr_001',
        email: 'jane@example.com',
        name: 'Jane',
        subscription: SubscriptionTier.free,
      );

      final updated = original.copyWith(
        name: 'Jane Doe',
        subscription: SubscriptionTier.serenity,
      );

      // Original unchanged
      expect(original.name, 'Jane');
      expect(original.subscription, SubscriptionTier.free);

      // Updated copy
      expect(updated.id, 'usr_001');
      expect(updated.email, 'jane@example.com');
      expect(updated.name, 'Jane Doe');
      expect(updated.subscription, SubscriptionTier.serenity);
    });

    test('copyWith preserves unchanged fields', () {
      const original = User(
        id: 'usr_001',
        email: 'jane@example.com',
        country: 'CA',
      );

      final updated = original.copyWith(name: 'Updated Name');

      expect(updated.country, 'CA');
      expect(updated.email, 'jane@example.com');
    });
  });

  group('SubscriptionTier', () {
    test('has all expected tiers', () {
      expect(SubscriptionTier.values, contains(SubscriptionTier.free));
      expect(SubscriptionTier.values, contains(SubscriptionTier.serenity));
      expect(SubscriptionTier.values, contains(SubscriptionTier.harmony));
      expect(SubscriptionTier.values, contains(SubscriptionTier.family));
    });

    test('premium is an alias for serenity', () {
      // premium is kept for backward compatibility
      expect(SubscriptionTier.premium, SubscriptionTier.serenity);
    });

    test('default subscription is free', () {
      const user = User(id: 'usr_001', email: 'test@example.com');
      expect(user.subscription, SubscriptionTier.free);
    });
  });
}
