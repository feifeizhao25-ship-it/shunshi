// test/unit/entities/reflection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/reflection.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Reflection entity', () {
    test('fromJson creates reflection correctly', () {
      final r = Reflection.fromJson(ApiFixtures.reflection);

      expect(r.id, 'refl_001');
      expect(r.userId, 'user_test_001');
      expect(r.content, contains('顺时'));
      expect(r.mood, MoodType.good);
      expect(r.sleepHours, 8);
      expect(r.tags, contains('睡眠'));
    });

    test('toJson round-trip', () {
      final r = Reflection.fromJson(ApiFixtures.reflection);
      final json = r.toJson();
      final restored = Reflection.fromJson(json);

      expect(restored.id, r.id);
      expect(restored.mood, r.mood);
      expect(restored.sleepHours, r.sleepHours);
    });

    test('copyWith updates mood only', () {
      final r = Reflection.fromJson(ApiFixtures.reflection);
      final updated = r.copyWith(mood: MoodType.great);
      expect(updated.mood, MoodType.great);
      expect(updated.content, r.content);
    });

    test('null mood is handled', () {
      final json = Map<String, dynamic>.from(ApiFixtures.reflection);
      json.remove('mood');
      final r = Reflection.fromJson(json);
      expect(r.mood, isNull);
    });
  });
}
