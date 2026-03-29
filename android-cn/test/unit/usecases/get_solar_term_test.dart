// test/unit/usecases/get_solar_term_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shunshi/domain/entities/solar_term.dart';
import 'package:shunshi/domain/repositories/solar_term_repository.dart';
import 'package:shunshi/domain/usecases/get_solar_term_content.dart';
import '../../fixtures/api_responses.dart';

class MockSolarTermRepository extends Mock implements SolarTermRepository {}

void main() {
  late MockSolarTermRepository mockRepo;
  late GetCurrentSolarTermUseCase getCurrentUseCase;
  late GetSolarTermDetailUseCase getDetailUseCase;

  setUp(() {
    mockRepo = MockSolarTermRepository();
    getCurrentUseCase = GetCurrentSolarTermUseCase(mockRepo);
    getDetailUseCase = GetSolarTermDetailUseCase(mockRepo);
  });

  group('GetCurrentSolarTermUseCase', () {
    test('returns current solar term', () async {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      when(() => mockRepo.getCurrentSolarTerm())
          .thenAnswer((_) async => term);

      final result = await getCurrentUseCase();

      expect(result, isNotNull);
      expect(result!.isCurrent, isTrue);
      expect(result.name, '立春');
    });

    test('returns null when no current term', () async {
      when(() => mockRepo.getCurrentSolarTerm())
          .thenAnswer((_) async => null);

      final result = await getCurrentUseCase();
      expect(result, isNull);
    });
  });

  group('GetSolarTermDetailUseCase', () {
    test('fetches detail by name', () async {
      final term = SolarTerm.fromJson(ApiFixtures.solarTerm);
      when(() => mockRepo.getSolarTermDetail('立春'))
          .thenAnswer((_) async => term);

      final result = await getDetailUseCase('立春');

      expect(result?.wellnessPlan, isNotNull);
      verify(() => mockRepo.getSolarTermDetail('立春')).called(1);
    });
  });
}
