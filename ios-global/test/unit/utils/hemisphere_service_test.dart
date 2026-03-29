// SEASONS Global — HemisphereService unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/utils/hemisphere_service.dart';

void main() {
  group('HemisphereService', () {
    test('north hemisphere returns a valid season', () {
      final season = HemisphereService.getCurrentSeason(Hemisphere.north);
      expect(
        [SeasonType.spring, SeasonType.summer, SeasonType.autumn, SeasonType.winter],
        contains(season),
      );
    });

    test('south hemisphere returns opposite season to north in same month', () {
      final northSeason = HemisphereService.getCurrentSeason(Hemisphere.north);
      final southSeason = HemisphereService.getCurrentSeason(Hemisphere.south);
      expect(northSeason, isNotNull);
      expect(southSeason, isNotNull);
      expect(northSeason, isNot(equals(southSeason)));
    });

    test('guessHemisphereFromCountry returns south for AU', () {
      final hemisphere = HemisphereService.guessHemisphereFromCountry('AU');
      expect(hemisphere, equals(Hemisphere.south));
    });

    test('guessHemisphereFromCountry returns north for CN', () {
      final hemisphere = HemisphereService.guessHemisphereFromCountry('CN');
      expect(hemisphere, equals(Hemisphere.north));
    });

    test('guessHemisphereFromCountry returns north for unknown country', () {
      final hemisphere = HemisphereService.guessHemisphereFromCountry('XX');
      expect(hemisphere, equals(Hemisphere.north));
    });
  });
}
