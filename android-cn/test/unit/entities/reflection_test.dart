// test/unit/entities/reflection_test.dart
// 每日感悟实体测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/reflection.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Reflection entity', () {
    test('fromJson 解析正常感悟', () {
      final ref = Reflection.fromJson(ApiFixtures.reflection);

      expect(ref.id, 'refl_001');
      expect(ref.userId, 'user_test_001');
      expect(ref.content, contains('早睡早起'));
      expect(ref.mood, MoodType.good);
      expect(ref.sleepHours, 8);
      expect(ref.tags, ['睡眠', '早起']);
      expect(ref.date, isNotNull);
      expect(ref.createdAt, isNotNull);
    });

    test('fromJson 解析差心情', () {
      final ref = Reflection.fromJson(ApiFixtures.reflectionBadMood);

      expect(ref.mood, MoodType.bad);
      expect(ref.sleepHours, 4);
      expect(ref.tags, ['失眠']);
    });

    test('toJson 正确序列化', () {
      final ref = Reflection.fromJson(ApiFixtures.reflection);
      final json = ref.toJson();

      expect(json['id'], ref.id);
      expect(json['user_id'], ref.userId);
      expect(json['mood'], 'good');
      expect(json['sleep_hours'], 8);
      expect(json['tags'], ['睡眠', '早起']);
    });

    test('round-trip: fromJson → toJson → fromJson 一致', () {
      final original = Reflection.fromJson(ApiFixtures.reflection);
      final json = original.toJson();
      final restored = Reflection.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.mood, original.mood);
      expect(restored.sleepHours, original.sleepHours);
    });

    test('copyWith 更新指定字段', () {
      final ref = Reflection.fromJson(ApiFixtures.reflection);
      final updated = ref.copyWith(
        mood: MoodType.great,
        sleepHours: 9,
      );

      expect(updated.mood, MoodType.great);
      expect(updated.sleepHours, 9);
      expect(updated.id, ref.id); // 不变
      expect(updated.content, ref.content);
    });

    test('无 mood 时为 null', () {
      final json = Map<String, dynamic>.from(ApiFixtures.reflection);
      json.remove('mood');
      final ref = Reflection.fromJson(json);

      expect(ref.mood, isNull);
    });

    test('MoodType 枚举完整', () {
      expect(MoodType.values.length, 5);
      expect(MoodType.values, containsAll([
        MoodType.great,
        MoodType.good,
        MoodType.neutral,
        MoodType.bad,
        MoodType.awful,
      ]));
    });
  });
}
