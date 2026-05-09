// test/unit/entities/content_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/domain/entities/content.dart';
import '../../fixtures/api_responses.dart';

void main() {
  group('Content entity', () {
    test('fromJson creates content correctly', () {
      final c = Content.fromJson(ApiFixtures.content);

      expect(c.id, 'content_001');
      expect(c.title, contains('立春'));
      expect(c.season, Season.spring);
      expect(c.solarTerm, '立春');
      expect(c.difficulty, Difficulty.easy);
      expect(c.durationMinutes, 15);
    });

    test('tags are parsed as list', () {
      final c = Content.fromJson(ApiFixtures.content);
      expect(c.tags, isA<List<String>>());
      expect(c.tags, contains('立春'));
    });

    test('copyWith preserves immutability', () {
      final c = Content.fromJson(ApiFixtures.content);
      final updated = c.copyWith(title: '新标题');
      expect(updated.title, '新标题');
      expect(updated.id, c.id);
      expect(updated.difficulty, c.difficulty);
    });

    test('unknown type defaults correctly', () {
      final json = Map<String, dynamic>.from(ApiFixtures.content);
      json['type'] = 'unknown_type_xyz';
      final c = Content.fromJson(json);
      expect(c.type, ContentType.unknown);
    });
  });
}
