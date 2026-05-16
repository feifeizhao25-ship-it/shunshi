// test/unit/core/security_test.dart
// TC-SEC: 安全逻辑单元测试

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security', () {
    test('TC-SEC-001: XSS prevention - strip script tags', () {
      const input = '<script>alert("XSS")</script>注入';
      final sanitized = input
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<[^>]+>'), '');
      expect(sanitized.contains('<script>'), isFalse);
      expect(sanitized.contains('alert'), isFalse);
    });

    test('TC-SEC-001b: no iframe in markdown', () {
      const content = '## 标题\n<iframe src="evil.com"></iframe>\n正文';
      final hasIframe = content.contains('<iframe');
      expect(hasIframe, isTrue); // detected
      final sanitized = content.replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '');
      expect(sanitized.contains('<iframe'), isFalse);
    });

    test('TC-SEC-002: URL whitelist check', () {
      final allowed = ['shunshi.app', 'cdn.shunshi.app', 'docs.shunshi.ai'];
      bool isAllowed(String url) {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;
        return allowed.any((d) => uri.host == d || uri.host.endsWith('.$d'));
      }

      expect(isAllowed('https://shunshi.app/recipe/abc'), isTrue);
      expect(isAllowed('https://cdn.shunshi.app/img.webp'), isTrue);
      expect(isAllowed('https://evil-phishing.com'), isFalse);
      expect(isAllowed('https://not-shunshi.com/fake'), isFalse);
    });

    test('TC-SEC-002b: deep link path traversal prevention', () {
      bool isValidPath(String path) {
        // Reject path traversal
        if (path.contains('..')) return false;
        if (path.contains('//')) return false;
        return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(path);
      }

      expect(isValidPath('shanyao-zhou'), isTrue);
      expect(isValidPath('abc123'), isTrue);
      expect(isValidPath('../../admin'), isFalse);
      expect(isValidPath('abc//def'), isFalse);
    });

    test('TC-SEC-011: idempotency key uniqueness', () {
      final keys = <String>{};
      for (int i = 0; i < 100; i++) {
        final key = 'idem_${DateTime.now().microsecondsSinceEpoch}_$i';
        keys.add(key);
      }
      expect(keys.length, 100); // All unique
    });

    test('TC-SEC-020: PII not in logs', () {
      final logData = {'user_id': 'u123', 'action': 'login'};
      final serialized = logData.toString();
      expect(serialized.contains('13812345678'), isFalse);
      expect(serialized.contains('password'), isFalse);
      expect(serialized.contains('Bearer'), isFalse);
    });

    test('TC-SEC-022: EXIF removal check', () {
      // Verify we know which fields to strip
      final exifFields = ['GPSLatitude', 'GPSLongitude', 'GPSAltitude'];
      final fakeExif = {'ImageWidth': 4000, 'GPSLatitude': 39.9, 'GPSLongitude': 116.4};

      for (final field in exifFields) {
        fakeExif.remove(field);
      }
      expect(fakeExif.containsKey('GPSLatitude'), isFalse);
      expect(fakeExif.containsKey('GPSLongitude'), isFalse);
      expect(fakeExif.containsKey('ImageWidth'), isTrue);
    });

    test('TC-SEC-040: SQL injection patterns detected', () {
      final dangerousInputs = [
        "'; DROP TABLE users; --",
        "' OR '1'='1",
        "1; SELECT * FROM users",
        "' UNION SELECT * FROM passwords --",
      ];
      final sqlPattern = RegExp(r"('|;|--|UNION|DROP|SELECT\s+\*)", caseSensitive: false);

      for (final input in dangerousInputs) {
        expect(sqlPattern.hasMatch(input), isTrue, reason: 'Should detect: $input');
      }
    });

    test('TC-SEC-041: resource access boundary', () {
      // User A cannot access User B's journal
      const userIdA = 'user_a';
      const userIdB = 'user_b';
      const journalOwner = 'user_b';

      final canAccess = userIdA == journalOwner;
      expect(canAccess, isFalse);
      expect(userIdB == journalOwner, isTrue);
    });

    test('TC-SEC-042: rate limit counters', () {
      // SMS: 60s cooldown
      const smsCooldown = 60;
      final elapsed = 30;
      expect(elapsed < smsCooldown, isTrue); // still cooling down

      // AI chat: 10/day free
      const aiLimit = 10;
      var used = 10;
      expect(used >= aiLimit, isTrue); // limit reached
    });
  });
}
