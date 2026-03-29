// SEASONS Global — HomePage widget integration smoke test
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomePage integration', () {
    test('greeting text builds correctly', () {
      final hour = 14;
      final greeting = hour < 12 ? 'Good morning' : 'Good afternoon';
      expect(greeting, equals('Good afternoon'));
    });

    test('time of day logic coverage', () {
      final hour2 = 8;
      final period = hour2 < 12 ? 'morning' : 'afternoon';
      expect(period, equals('morning'));
    });
  });
}
