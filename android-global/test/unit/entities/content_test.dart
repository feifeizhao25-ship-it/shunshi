// test/unit/entities/content_test.dart
// Global SEASONS Content entity tests

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/content.dart';

void main() {
  group('Content entity', () {
    test('creates with required fields', () {
      final content = Content(
        id: 'content_001',
        title: 'Spring Meditation',
        description: 'A calming spring meditation',
        type: ContentType.meditation,
      );

      expect(content.id, 'content_001');
      expect(content.title, 'Spring Meditation');
      expect(content.type, ContentType.meditation);
    });

    test('ContentType has all expected values', () {
      expect(ContentType.values.length, 9);
      expect(ContentType.values, containsAll([
        ContentType.breathing,
        ContentType.stretch,
        ContentType.teaRitual,
        ContentType.sleep,
        ContentType.reflection,
        ContentType.meditation,
        ContentType.story,
        ContentType.food,
        ContentType.acupressure,
      ]));
    });

    test('Season has all expected values', () {
      expect(Season.values.length, 5);
      expect(Season.values, containsAll([
        Season.spring,
        Season.summer,
        Season.autumn,
        Season.winter,
        Season.all,
      ]));
    });

    test('different content types', () {
      final types = [
        ContentType.breathing,
        ContentType.stretch,
        ContentType.teaRitual,
        ContentType.food,
        ContentType.meditation,
      ];

      for (final type in types) {
        final content = Content(
          id: 'test_${type.name}',
          title: 'Test ${type.name}',
          description: 'desc',
          type: type,
        );
        expect(content.type, type);
      }
    });
  });
}
