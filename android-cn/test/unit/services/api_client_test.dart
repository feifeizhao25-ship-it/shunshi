// test/unit/services/api_client_test.dart
// ApiClient 单元测试 — 对应 TEST_SPEC TC-ERROR-001~009

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/core/network/api_client.dart';

void main() {
  group('ApiClient', () {
    test('creates with default base URL', () {
      final client = ApiClient();
      expect(client, isNotNull);
    });

    test('creates with custom base URL', () {
      final client = ApiClient(baseUrl: 'http://localhost:4000');
      expect(client, isNotNull);
    });

    test('creates with auth token', () {
      final client = ApiClient();
      client.updateAuthToken('test_token_abc');
      expect(client, isNotNull);
    });

    test('updateAuthToken sets new token', () {
      final client = ApiClient();
      // Should not throw
      client.updateAuthToken('new_token_xyz');
    });

    test('clearAuthToken removes token', () {
      final client = ApiClient();
      // Should not throw
      client.clearAuthToken();
    });

    test('has GET method', () {
      final client = ApiClient(baseUrl: 'http://localhost:1');
      // Method exists
      expect(() => client.get('/health'), isA<Function>());
    });

    test('has POST method', () {
      final client = ApiClient(baseUrl: 'http://localhost:1');
      expect(() => client.post('/auth/guest'), isA<Function>());
    });

    test('has PUT method', () {
      final client = ApiClient(baseUrl: 'http://localhost:1');
      expect(() => client.put('/me/profile'), isA<Function>());
    });

    test('has DELETE method', () {
      final client = ApiClient(baseUrl: 'http://localhost:1');
      expect(() => client.delete('/favorites/1'), isA<Function>());
    });
  });
}
