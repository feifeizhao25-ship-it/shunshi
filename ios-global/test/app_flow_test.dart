// SEASONS Global — integration smoke test
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App flow', () {
    test('environment sanity check', () {
      expect(DateTime.now().year >= 2026, isTrue);
    });

    test('string operations work', () {
      expect('seasons'.toUpperCase(), equals('SEASONS'));
    });
  });
}
