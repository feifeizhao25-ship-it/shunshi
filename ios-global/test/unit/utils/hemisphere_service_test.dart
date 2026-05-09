import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/utils/hemisphere_service.dart';

void main() {
  group('HemisphereService', () {
    test('returns correct season for northern hemisphere in January', () {
      final season = HemisphereService.getCurrentSeason(
        hemisphere: Hemisphere.north,
        date: DateTime(2025, 1, 15),
      );
      expect(season, SeasonType.winter);
    });

    test('returns correct season for southern hemisphere in January', () {
      final season = HemisphereService.getCurrentSeason(
        hemisphere: Hemisphere.south,
        date: DateTime(2025, 1, 15),
      );
      expect(season, SeasonType.summer);
    });

    test('returns spring for northern April', () {
      final season = HemisphereService.getCurrentSeason(
        hemisphere: Hemisphere.north,
        date: DateTime(2025, 4, 15),
      );
      expect(season, SeasonType.spring);
    });

    test('returns autumn for southern April', () {
      final season = HemisphereService.getCurrentSeason(
        hemisphere: Hemisphere.south,
        date: DateTime(2025, 4, 15),
      );
      expect(season, SeasonType.autumn);
    });
  });
}
