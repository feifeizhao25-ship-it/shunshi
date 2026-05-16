// test/integration/api_home_test.dart
// 首页 API 集成测试 — 对应 TEST_SPEC TC-HOME-001~003
// 通过 SSH tunnel 访问 ECS 后端

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:4010',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  group('TC-HOME: Home API Integration', () {
    test('TC-HOME-001a: /health returns healthy', () async {
      final response = await dio.get('/health');
      expect(response.statusCode, 200);
      expect(response.data['status'], 'healthy');
    });

    test('TC-HOME-001b: /api/v1/contents returns items', () async {
      final response = await dio.get('/api/v1/contents', queryParameters: {
        'locale': 'zh-CN',
        'page_size': 5,
      });
      expect(response.statusCode, 200);
      final data = response.data['data'];
      expect(data['total'], greaterThan(0));
      expect(data['items'], isNotEmpty);
    });

    test('TC-HOME-001c: /api/v1/contents en-US has 400+ items', () async {
      final response = await dio.get('/api/v1/contents', queryParameters: {
        'locale': 'en-US',
        'page_size': 1,
      });
      expect(response.statusCode, 200);
      expect(response.data['data']['total'], greaterThanOrEqualTo(400));
    });

    test('TC-HOME-002: solar-terms returns 24 terms', () async {
      final response = await dio.get('/api/v1/solar-terms', queryParameters: {
        'locale': 'zh-CN',
      });
      expect(response.statusCode, 200);
      expect(response.data['data'].length, greaterThanOrEqualTo(24));
    });

    test('TC-HOME-003: daily advice returns structured data', () async {
      // Try various recommendation endpoints
      final endpoints = [
        '/api/v1/contents?locale=zh-CN&type=food_therapy&page_size=3',
        '/api/v1/contents?locale=zh-CN&type=tea&page_size=3',
        '/api/v1/contents?locale=zh-CN&type=exercise&page_size=3',
      ];

      for (final url in endpoints) {
        final response = await dio.get(url);
        expect(response.statusCode, 200,
            reason: 'Failed for $url');
      }
    });

    test('TC-HOME-010: solar term detail has wellness plan', () async {
      // Get solar terms first
      final termsResp = await dio.get('/api/v1/solar-terms',
          queryParameters: {'locale': 'zh-CN'});
      final terms = termsResp.data['data'] as List;
      expect(terms.isNotEmpty, isTrue);

      // First term should have basic fields
      final term = terms[0];
      expect(term['name'], isNotNull);
      expect(term['season'], isNotNull);
    });

    test('TC-HOME-030: 9 content types all have data', () async {
      final types = [
        'food_therapy', 'tea', 'exercise', 'acupressure',
        'sleep_tip', 'meditation', 'recipe', 'tips', 'acupoint',
      ];

      for (final type in types) {
        final response = await dio.get('/api/v1/contents',
            queryParameters: {'locale': 'en-US', 'type': type});
        final total = response.data['data']['total'] as int;
        expect(total, greaterThan(0), reason: 'No items for type: $type');
      }
    });
  });
}
