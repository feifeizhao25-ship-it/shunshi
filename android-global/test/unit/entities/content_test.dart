import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/content.dart';

void main() {
  group('Content', () {
    test('creates content with required fields', () {
      const content = Content(
        id: 'cnt_001',
        title: 'Morning Breathing Exercise',
        description: 'A gentle 5-minute breathing exercise to start your day.',
        type: ContentType.breathing,
      );

      expect(content.id, 'cnt_001');
      expect(content.title, 'Morning Breathing Exercise');
      expect(content.type, ContentType.breathing);
      expect(content.durationSeconds, isNull);
      expect(content.isPremium, false);
    });

    test('creates content with all optional fields', () {
      const content = Content(
        id: 'cnt_002',
        title: 'Sleep Story: Forest Rain',
        description: 'A calming audio story to help you drift off to sleep.',
        type: ContentType.story,
        audioUrl: 'https://cdn.example.com/forest-rain.mp3',
        imageUrl: 'https://cdn.example.com/forest-rain.jpg',
        durationSeconds: 1200,
        tags: ['sleep', 'relaxation', 'nature'],
        steps: ['Get comfortable', 'Close your eyes', 'Listen and breathe'],
        season: Season.autumn,
        isPremium: true,
      );

      expect(content.audioUrl, 'https://cdn.example.com/forest-rain.mp3');
      expect(content.durationSeconds, 1200);
      expect(content.tags, contains('sleep'));
      expect(content.steps.length, 3);
      expect(content.season, Season.autumn);
      expect(content.isPremium, true);
    });

    test('creates content without video', () {
      const content = Content(
        id: 'cnt_003',
        title: 'Tea Ritual Guide',
        description: 'Learn the art of mindful tea drinking.',
        type: ContentType.teaRitual,
      );

      expect(content.videoUrl, isNull);
    });
  });

  group('ContentType', () {
    test('has all expected types', () {
      expect(ContentType.values, contains(ContentType.breathing));
      expect(ContentType.values, contains(ContentType.stretch));
      expect(ContentType.values, contains(ContentType.teaRitual));
      expect(ContentType.values, contains(ContentType.sleep));
      expect(ContentType.values, contains(ContentType.reflection));
      expect(ContentType.values, contains(ContentType.meditation));
      expect(ContentType.values, contains(ContentType.story));
      expect(ContentType.values, contains(ContentType.food));
      expect(ContentType.values, contains(ContentType.acupressure));
    });
  });

  group('Season', () {
    test('has all four seasons plus all', () {
      expect(Season.values, contains(Season.spring));
      expect(Season.values, contains(Season.summer));
      expect(Season.values, contains(Season.autumn));
      expect(Season.values, contains(Season.winter));
      expect(Season.values, contains(Season.all));
    });
  });

  group('ContentCategory', () {
    test('creates a content category with contents', () {
      const contents = [
        Content(
          id: 'cnt_001',
          title: 'Box Breathing',
          description: 'A simple technique.',
          type: ContentType.breathing,
        ),
        Content(
          id: 'cnt_002',
          title: '4-7-8 Breathing',
          description: 'A calming technique.',
          type: ContentType.breathing,
        ),
      ];

      const category = ContentCategory(
        id: 'cat_breathing',
        name: 'Breathing Exercises',
        type: ContentType.breathing,
        contents: contents,
      );

      expect(category.name, 'Breathing Exercises');
      expect(category.contents.length, 2);
      expect(category.contents.first.type, ContentType.breathing);
    });

    test('creates an empty content category', () {
      const category = ContentCategory(
        id: 'cat_empty',
        name: 'Upcoming',
        type: ContentType.meditation,
      );

      expect(category.contents, isEmpty);
      expect(category.iconUrl, isNull);
    });
  });
}
