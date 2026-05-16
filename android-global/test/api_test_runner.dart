// Standalone API test runner — no Flutter compilation needed
// Run: dart run test/api_test_runner.dart

import 'dart:convert';
import 'dart:io';

const API = 'http://116.62.32.43:4000/api/v1';

Future<HttpClientResponse> get(String path, {Map<String, String>? params}) async {
  final client = HttpClient();
  var url = Uri.parse('$API$path');
  if (params != null) {
    url = url.replace(queryParameters: params);
  }
  final req = await client.getUrl(url);
  return await req.close();
}

Future<Map> getJson(String path, {Map<String, String>? params}) async {
  final resp = await get(path, params: params);
  final body = await resp.transform(utf8.decoder).join();
  return jsonDecode(body);
}

int passed = 0;
int failed = 0;

Future<void> test(String name, Future<void> Function() fn) async {
  try {
    await fn();
    passed++;
    print('  ✓ $name');
  } catch (e) {
    failed++;
    print('  ✗ $name: $e');
  }
}

void check(bool condition, String msg) {
  if (!condition) throw Exception(msg);
}

Future<void> main() async {
  print('SEASONS API Test Runner');
  print('=' * 50);

  // Health
  await test('TC-HEALTH-001: /health returns healthy', () async {
    final data = await getJson('/../../health');
    check(data['status'] == 'healthy', 'status not healthy');
  });

  // Contents EN
  await test('TC-CONT-001: EN contents total >= 300', () async {
    final data = await getJson('/contents', params: {'locale': 'en-US', 'page_size': '1'});
    check(data['data']['total'] >= 300, 'total < 300: ${data['data']['total']}');
  });

  // Contents ZH
  await test('TC-CONT-002: ZH contents exist', () async {
    final data = await getJson('/contents', params: {'locale': 'zh-CN', 'page_size': '1'});
    check(data['data']['total'] > 0, 'no zh contents');
  });

  // Content types
  await test('TC-CONT-003: All 10 content types work', () async {
    const types = ['food_therapy', 'acupressure', 'exercise', 'tea', 'sleep_tip', 'meditation', 'recipe', 'acupoint', 'tips', 'solar_term'];
    for (final type in types) {
      final resp = await get('/contents', params: {'locale': 'en-US', 'type': type, 'page_size': '1'});
      check(resp.statusCode == 200, '$type failed: ${resp.statusCode}');
    }
  });

  // EN items have title
  await test('TC-CONT-004: EN items have non-empty title', () async {
    final data = await getJson('/contents', params: {'locale': 'en-US', 'page_size': '5'});
    final items = data['data']['items'] as List;
    for (final item in items) {
      check(item['title'] != null && item['title'].toString().isNotEmpty, 'empty title');
    }
  });

  // Search
  await test('TC-CONT-005: Search works', () async {
    final resp = await get('/contents/search', params: {'q': 'sleep', 'locale': 'en-US'});
    check(resp.statusCode == 200, 'search failed: ${resp.statusCode}');
  });

  // Constitution EN
  await test('TC-QUIZ-001: EN questions >= 25', () async {
    final data = await getJson('/constitution/questions', params: {'locale': 'en-US'});
    check(data['data']['total'] >= 25, 'questions < 25');
  });

  // Constitution ZH
  await test('TC-QUIZ-002: ZH questions >= 25', () async {
    final data = await getJson('/constitution/questions', params: {'locale': 'zh-CN'});
    check(data['data']['total'] >= 25, 'questions < 25');
  });

  // 9 types
  await test('TC-QUIZ-003: All 9 constitution types', () async {
    const types = ['pinghe', 'qixu', 'yangxu', 'yinxu', 'tanshi', 'shire', 'xueyu', 'qiyu', 'tebing'];
    for (final type in types) {
      final resp = await get('/constitution/$type');
      check(resp.statusCode == 200, '$type failed: ${resp.statusCode}');
    }
  });

  // Invalid type
  await test('TC-QUIZ-004: Invalid type returns 404', () async {
    final resp = await get('/constitution/nonexistent');
    check(resp.statusCode == 404, 'expected 404: ${resp.statusCode}');
  });

  // Solar terms EN
  await test('TC-SOLAR-001: EN solar terms >= 24', () async {
    final data = await getJson('/solar-terms', params: {'locale': 'en-US'});
    check(data['data'].length >= 24, 'terms < 24');
  });

  // Solar terms ZH
  await test('TC-SOLAR-002: ZH solar terms >= 24', () async {
    final data = await getJson('/solar-terms', params: {'locale': 'zh-CN'});
    check(data['data'].length >= 24, 'terms < 24');
  });

  // Guest login (may be rate limited)
  await test('TC-AUTH-001: Guest login endpoint reachable', () async {
    final client = HttpClient();
    final req = await client.postUrl(Uri.parse('$API/auth/guest'));
    final resp = await req.close();
    check(resp.statusCode == 200 || resp.statusCode == 429, 'unexpected: ${resp.statusCode}');
  });

  // Acupoints
  await test('TC-ACU-001: Acupoint content exists', () async {
    final data = await getJson('/contents', params: {'locale': 'en-US', 'type': 'acupoint', 'page_size': '5'});
    check(data['data']['total'] >= 5, 'acupoints < 5');
  });

  // Contents by type counts
  await test('TC-CONT-006: Content distribution reasonable', () async {
    final foodResp = await getJson('/contents', params: {'locale': 'en-US', 'type': 'food_therapy', 'page_size': '1'});
    check(foodResp['data']['total'] >= 100, 'food_therapy < 100');
    final acuResp = await getJson('/contents', params: {'locale': 'en-US', 'type': 'acupressure', 'page_size': '1'});
    check(acuResp['data']['total'] >= 50, 'acupressure < 50');
    final exResp = await getJson('/contents', params: {'locale': 'en-US', 'type': 'exercise', 'page_size': '1'});
    check(exResp['data']['total'] >= 30, 'exercise < 30');
  });

  print('');
  print('=' * 50);
  print('Results: $passed passed, $failed failed');
  if (failed > 0) exit(1);
}
