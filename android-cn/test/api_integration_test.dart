import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  const runLiveApiTests = bool.fromEnvironment('RUN_LIVE_API_TESTS');
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  group('ShunShi API Integration Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));
    });

    test('Health endpoint returns healthy', () async {
      final res = await dio.get('/health');
      expect(res.statusCode, 200);
      expect(res.data['status'], isNotNull);
    });

    test('Solar terms endpoint returns data', () async {
      final res = await dio.get('/api/v1/solar-terms/current');
      expect(res.statusCode, 200);
      expect(res.data['success'], true);
      expect(res.data['data']['name'], isNotNull);
    });

    test('Contents endpoint returns items', () async {
      final res = await dio.get('/api/v1/contents', queryParameters: {'limit': 5});
      expect(res.statusCode, 200);
      final items = res.data['data']['items'] as List;
      expect(items.length, greaterThan(0));
    });

    test('Register and login flow', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test_$timestamp@shunshi.app';
      
      // Register
      final regRes = await dio.post('/api/v1/auth/register', data: {
        'email': email,
        'password': 'Test1234!',
        'name': 'Test User',
      });
      expect(regRes.statusCode, 200);
      expect(regRes.data['success'], true);
      expect(regRes.data['data']['token'], isNotNull);

      // Login
      final loginRes = await dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': 'Test1234!',
      });
      expect(loginRes.statusCode, 200);
      expect(loginRes.data['success'], true);
    });

    test('Metrics endpoint returns prometheus data', () async {
      final res = await dio.get('/metrics');
      expect(res.statusCode, 200);
      expect(res.data, contains('python_gc_objects_collected_total'));
    });
  }, skip: runLiveApiTests ? false : 'Set RUN_LIVE_API_TESTS=true to test a deployed API');
}
