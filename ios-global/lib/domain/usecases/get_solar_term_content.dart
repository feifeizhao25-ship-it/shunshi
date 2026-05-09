// lib/domain/usecases/get_solar_term_content.dart
import '../entities/solar_term.dart';
import '../repositories/solar_term_repository.dart';

class GetCurrentSolarTermUseCase {
  final SolarTermRepository _repository;
  GetCurrentSolarTermUseCase(this._repository);

  Future<SolarTerm?> call() => _repository.getCurrentSolarTerm();
}

class GetSolarTermDetailUseCase {
  final SolarTermRepository _repository;
  GetSolarTermDetailUseCase(this._repository);

  Future<SolarTerm?> call(String termName) =>
      _repository.getSolarTermDetail(termName);
}
