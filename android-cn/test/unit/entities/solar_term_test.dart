// test/unit/entities/solar_term_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('SolarTerm entity', () {
    test('fromJson creates solar term correctly', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);

      expect(term.name, '立春');
      expect(term.nameEn, 'Start of Spring');
      expect(term.emoji, '🌱');
      expect(term.season, 'spring');
      expect(term.isCurrent, isTrue);
    });

    test('wellness plan is parsed', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      expect(term.wellnessPlan, isNotNull);
      expect(term.wellnessPlan!['diet'], isA<List>());
      expect(term.wellnessPlan!['tea'], isA<List>());
    });

    test('copyWith isCurrent works', () {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      final updated = term.copyWith(isCurrent: false);
      expect(updated.isCurrent, isFalse);
      expect(updated.name, term.name);
    });

    test('defaults when fields are missing', () {
      final term = SolarTerm.fromJson({'name': '雨水', 'id': '2'});
      expect(term.emoji, '🌿');
      expect(term.season, 'spring');
      expect(term.isCurrent, isFalse);
    });
  });
}
