// SEASONS Global — API Integration Tests
// Based on TEST_SPEC.md TC-API series
// Tests real backend API responses (ECS:116.62.32.43:4000)

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

const API_BASE = 'http://116.62.32.43:4000/api/v1';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: API_BASE,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      queryParameters: {'locale': 'en-US'},
    ));
  });

  group('TC-API-HEALTH: Health check', () {
    test('TC-HEALTH-001: /health returns healthy', () async {
      final resp = await dio.get('/../../health');
      expect(resp.statusCode, 200);
      expect(resp.data['status'], 'healthy');
    });
  });

  group('TC-API-CONTENTS: Content endpoints', () {
    test('TC-CONT-001: EN contents total >= 300', () async {
      final resp = await dio.get('/contents', queryParameters: {'locale': 'en-US', 'page_size': '1'});
      expect(resp.statusCode, 200);
      expect(resp.data['success'], true);
      expect(resp.data['data']['total'], greaterThanOrEqualTo(300));
    });

    test('TC-CONT-002: ZH contents exist', () async {
      final resp = await dio.get('/contents', queryParameters: {'locale': 'zh-CN', 'page_size': '1'});
      expect(resp.statusCode, 200);
      expect(resp.data['data']['total'], greaterThan(0));
    });

    test('TC-CONT-003: Contents by type — all 10 types', () async {
      const types = ['food_therapy', 'acupressure', 'exercise', 'tea', 'sleep_tip', 'meditation', 'recipe', 'acupoint', 'tips', 'solar_term'];
      for (final type in types) {
        final resp = await dio.get('/contents', queryParameters: {'locale': 'en-US', 'type': type, 'page_size': '1'});
        expect(resp.statusCode, 200, reason: 'Failed for type: $type');
      }
    });

    test('TC-CONT-004: EN content items have title', () async {
      final resp = await dio.get('/contents', queryParameters: {'locale': 'en-US', 'page_size': '5'});
      final items = resp.data['data']['items'] as List;
      for (final item in items) {
        expect(item['title'], isNotNull);
        expect(item['title'], isNotEmpty);
      }
    });

    test('TC-CONT-005: Search works', () async {
      final resp = await dio.get('/contents/search', queryParameters: {'q': 'sleep', 'locale': 'en-US'});
      expect(resp.statusCode, 200);
    });
  });

  group('TC-API-QUIZ: Constitution', () {
    test('TC-QUIZ-001: EN questions >= 25', () async {
      final resp = await dio.get('/constitution/questions', queryParameters: {'locale': 'en-US'});
      expect(resp.statusCode, 200);
      expect(resp.data['data']['total'], greaterThanOrEqualTo(25));
    });

    test('TC-QUIZ-002: ZH questions >= 25', () async {
      final resp = await dio.get('/constitution/questions', queryParameters: {'locale': 'zh-CN'});
      expect(resp.statusCode, 200);
      expect(resp.data['data']['total'], greaterThanOrEqualTo(25));
    });

    test('TC-QUIZ-003: All 9 constitution types accessible', () async {
      const types = ['pinghe', 'qixu', 'yangxu', 'yinxu', 'tanshi', 'shire', 'xueyu', 'qiyu', 'tebing'];
      for (final type in types) {
        final resp = await dio.get('/constitution/$type');
        expect(resp.statusCode, 200, reason: 'Failed for: $type');
        expect(resp.data['data']['name'], isNotNull);
      }
    });

    test('TC-QUIZ-004: Invalid type returns 404', () async {
      try {
        await dio.get('/constitution/nonexistent');
        fail('Should have thrown');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
      }
    });
  });

  group('TC-API-SOLAR: Solar terms', () {
    test('TC-SOLAR-001: EN solar terms >= 24', () async {
      final resp = await dio.get('/solar-terms', queryParameters: {'locale': 'en-US'});
      expect(resp.statusCode, 200);
      expect(resp.data['data'].length, greaterThanOrEqualTo(24));
    });

    test('TC-SOLAR-002: ZH solar terms >= 24', () async {
      final resp = await dio.get('/solar-terms', queryParameters: {'locale': 'zh-CN'});
      expect(resp.statusCode, 200);
      expect(resp.data['data'].length, greaterThanOrEqualTo(24));
    });
  });

  group('TC-API-AUTH: Authentication', () {
    test('TC-AUTH-001: Guest login', () async {
      try {
        final resp = await dio.post('/auth/guest');
        expect(resp.statusCode, 200);
      } on DioException catch (e) {
        // 429 = rate limited, acceptable
        expect(e.response?.statusCode, anyOf(429, 200));
      }
    });
  });
}
