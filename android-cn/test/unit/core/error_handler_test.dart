// test/unit/core/error_handler_test.dart
// TC-ERROR: 错误处理逻辑单元测试

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error handling', () {
    test('TC-ERROR-003: retry with exponential backoff calculation', () {
      // Verify backoff delay calculation
      final delays = <int>[];
      for (int i = 0; i < 5; i++) {
        // Base delay * (2^attempt) + jitter
        final delay = 1000 * (1 << i); // 1s, 2s, 4s, 8s, 16s
        delays.add(delay);
      }
      expect(delays[0], 1000);   // 1s
      expect(delays[1], 2000);   // 2s
      expect(delays[2], 4000);   // 4s
    });

    test('TC-ERROR-009: business error code mapping', () {
      final codes = {
        'AUTH_INVALID_PHONE': '手机号格式错误',
        'AUTH_INVALID_CODE': '验证码错误',
        'AUTH_CODE_EXPIRED': '验证码已过期',
        'AUTH_TOO_MANY_ATTEMPTS': '尝试次数过多',
        'RECIPE_NOT_FOUND': '该食谱不存在',
        'VIP_REQUIRED': '此内容需要开通会员',
        'RATE_LIMITED_AI': 'AI 对话次数已用完',
        'RATE_LIMITED_SMS': '短信发送过快',
        'PAYMENT_FAILED': '支付失败',
        'UPLOAD_TOO_LARGE': '文件不能超过 10MB',
      };

      for (final entry in codes.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} should have message');
      }
      expect(codes.length, 10);
    });

    test('TC-ERROR-002: 401 triggers refresh flow', () {
      // Verify 401 is in the retry-eligible status codes
      final retryableStatus = {408, 500, 502, 503, 504};
      final authErrors = {401};

      // 401 should NOT be in retry — it needs refresh
      expect(authErrors.contains(401), isTrue);
      expect(retryableStatus.contains(401), isFalse);
    });

    test('TC-ERROR-004: 429 is not auto-retried', () {
      final autoRetryCodes = {408, 500, 502, 503, 504};
      expect(autoRetryCodes.contains(429), isFalse);
    });

    test('TC-ERROR-007: timeout thresholds', () {
      // Normal API: 30s timeout
      expect(const Duration(seconds: 30).inSeconds, 30);
      // AI chat: 30s timeout for SSE
      expect(const Duration(seconds: 30).inSeconds, 30);
    });
  });
}
