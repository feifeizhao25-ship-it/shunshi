// test/integration/content_flow_test.dart
// 内容浏览流程集成测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/content.dart';
import '../fixtures/api_responses.dart';

void main() {
  group('Content Flow', () {
    test('按类型筛选 — 食疗', () {
      final content = Content.fromJson(ApiFixtures.content);
      expect(content.type, ContentType.foodTherapy);
    });

    test('按类型筛选 — 茶饮', () {
      final content = Content.fromJson(ApiFixtures.contentTea);
      expect(content.type, ContentType.tea);
    });

    test('按类型筛选 — 运动', () {
      final content = Content.fromJson(ApiFixtures.contentExercise);
      expect(content.type, ContentType.exercise);
    });

    test('按季节筛选 — 春季', () {
      final all = [
        ApiFixtures.content,
        ApiFixtures.contentTea,
        ApiFixtures.contentExercise,
      ];

      for (final fixture in all) {
        final content = Content.fromJson(fixture);
        expect(content.season, Season.spring);
      }
    });

    test('内容列表分页', () {
      final response = ApiFixtures.contentsResponse;
      expect(response['total'], 2);
      expect(response['page'], 1);
    });

    test('内容详情包含摘要', () {
      final content = Content.fromJson(ApiFixtures.content);
      expect(content.summary, isNotNull);
      expect(content.summary, contains('韭菜'));
    });

    test('内容难度和时长', () {
      final content = Content.fromJson(ApiFixtures.content);
      expect(content.difficulty, Difficulty.easy);
      expect(content.durationMinutes, 15);
    });
  });
}
