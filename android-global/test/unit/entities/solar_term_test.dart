// test/unit/entities/solar_term_test.dart
// Global SEASONS SolarTerm entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/solar_term.dart';

void main() {
  group('SolarTerm entity', () {
    test('creates with required fields', () {
      final term = SolarTerm(
        id: 'solar_001',
        name: 'Start of Spring',
        nameEn: 'Start of Spring',
        emoji: '🌱',
        season: 'spring',
        date: 'Feb 3-5',
        description: 'Beginning of spring',
        isCurrent: true,
      );

      expect(term.id, 'solar_001');
      expect(term.name, 'Start of Spring');
      expect(term.season, 'spring');
      expect(term.isCurrent, isTrue);
    });
  });
}
