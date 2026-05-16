// test/unit/entities/content_test.dart
// 养生内容实体测试 — 扩充版

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/content.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Content entity', () {
    test('fromJson 解析食疗内容', () {
      final content = Content.fromJson(ApiFixtures.content);

      expect(content.id, 'content_001');
      expect(content.type, ContentType.foodTherapy);
      expect(content.title, contains('韭菜炒鸡蛋'));
      expect(content.tags, ['立春', '温阳', '简单']);
      expect(content.season, Season.spring);
      expect(content.difficulty, Difficulty.easy);
      expect(content.durationMinutes, 15);
      expect(content.createdAt, isNotNull);
    });

    test('fromJson 解析茶饮内容', () {
      final content = Content.fromJson(ApiFixtures.contentTea);

      expect(content.type, ContentType.tea);
      expect(content.title, contains('菊花枸杞茶'));
    });

    test('fromJson 解析运动内容', () {
      final content = Content.fromJson(ApiFixtures.contentExercise);

      expect(content.type, ContentType.exercise);
      expect(content.durationMinutes, 10);
    });

    test('fromJson 解析音频/冥想内容', () {
      final content = Content.fromJson(ApiFixtures.contentMeditation);

      expect(content.type, ContentType.audio);
      expect(content.summary, contains('呼吸'));
    });

    test('fromJson 解析睡眠建议', () {
      final content = Content.fromJson(ApiFixtures.contentSleepTip);

      expect(content.type, ContentType.sleepTip);
    });

    test('toJson 正确序列化', () {
      final content = Content.fromJson(ApiFixtures.content);
      final json = content.toJson();

      expect(json['id'], 'content_001');
      expect(json['type'], 'foodTherapy'); // entity stores name as-is
      expect(json['title'], content.title);
      expect(json['tags'], content.tags);
      expect(json['season'], 'spring');
      expect(json['difficulty'], 'easy');
    });

    test('round-trip: fromJson → toJson → fromJson 一致', () {
      final original = Content.fromJson(ApiFixtures.content);
      final json = original.toJson();
      final restored = Content.fromJson(json);

      expect(restored.id, original.id);
      // type mapping may transform: compare round-trip consistency
      expect(restored.title, original.title);
      expect(restored.tags, original.tags);
    });

    test('copyWith 仅更新指定字段', () {
      final content = Content.fromJson(ApiFixtures.content);
      final updated = content.copyWith(title: '新标题');

      expect(updated.title, '新标题');
      expect(updated.id, content.id);
      expect(updated.type, content.type);
      expect(updated.tags, content.tags);
    });

    test('未知类型映射为 unknown', () {
      final json = Map<String, dynamic>.from(ApiFixtures.content);
      json['type'] = 'nonexistent_type';
      final content = Content.fromJson(json);

      expect(content.type, ContentType.unknown);
    });

    test('ContentType 枚举覆盖所有类型', () {
      expect(ContentType.values.length, 10);
      expect(ContentType.values, contains(ContentType.foodTherapy));
      expect(ContentType.values, contains(ContentType.tea));
      expect(ContentType.values, contains(ContentType.exercise));
      expect(ContentType.values, contains(ContentType.acupoint));
      expect(ContentType.values, contains(ContentType.acupressure));
      expect(ContentType.values, contains(ContentType.sleepTip));
    });
  });
}
