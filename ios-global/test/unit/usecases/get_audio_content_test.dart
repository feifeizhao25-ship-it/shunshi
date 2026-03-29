// SEASONS Global — GetPersonalizedContent (audio) use case unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/domain/entities/entities.dart';
import 'package:seasons/domain/repositories/content_repository.dart';
import 'package:seasons/domain/usecases/get_personalized_content.dart';

class MockContentRepository extends Mock implements ContentRepository {}

void main() {
  group('GetPersonalizedContent (audio)', () {
    late MockContentRepository mockContentRepository;
    late GetPersonalizedContent useCase;

    setUp(() {
      mockContentRepository = MockContentRepository();
      useCase = GetPersonalizedContent(mockContentRepository);
    });

    test('returns content list on success', () async {
      final testContent = Content(
        id: 'c1',
        title: 'Morning Breathe',
        type: ContentType.audio,
      );

      when(
        () => mockContentRepository.getPersonalizedContent('user1'),
      ).thenAnswer((_) async => [testContent]);

      final result = await useCase.call('user1');

      expect(result, isNotEmpty);
      expect(result.length, equals(1));
      expect(result[0].id, equals('c1'));
      expect(result[0].title, equals('Morning Breathe'));
      expect(result[0].type, equals(ContentType.audio));
      verify(
        () => mockContentRepository.getPersonalizedContent('user1'),
      ).called(1);
    });

    test('returns empty list when no content available', () async {
      when(
        () => mockContentRepository.getPersonalizedContent('user2'),
      ).thenAnswer((_) async => []);

      final result = await useCase.call('user2');

      expect(result, isEmpty);
      verify(
        () => mockContentRepository.getPersonalizedContent('user2'),
      ).called(1);
    });

    test('propagates error from repository', () async {
      when(
        () => mockContentRepository.getPersonalizedContent('user3'),
      ).thenThrow(Exception('Database error'));

      expect(
        () => useCase.call('user3'),
        throwsException,
      );
    });
  });
}
