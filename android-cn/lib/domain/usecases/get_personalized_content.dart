// lib/domain/usecases/get_personalized_content.dart
import '../entities/content.dart';
import '../repositories/content_repository.dart';

class GetPersonalizedContentUseCase {
  final ContentRepository _repository;
  GetPersonalizedContentUseCase(this._repository);

  Future<List<Content>> call({
    required String userId,
    required String constitution,
    String? currentSolarTerm,
    int limit = 10,
  }) {
    return _repository.getPersonalizedContents(
      userId: userId,
      constitution: constitution,
      currentSolarTerm: currentSolarTerm,
      limit: limit,
    );
  }
}
