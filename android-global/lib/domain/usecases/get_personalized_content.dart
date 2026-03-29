// lib/domain/usecases/get_personalized_content.dart
import '../entities/content.dart';
import '../repositories/content_repository.dart';

class GetPersonalizedContentUseCase {
  final ContentRepository _repository;
  GetPersonalizedContentUseCase(this._repository);

  Future<List<Content>> call({
    required String userId,
    required String hemisphere,
    String? currentSeason,
    int limit = 10,
  }) {
    return _repository.getPersonalizedContents(
      userId: userId,
      hemisphere: hemisphere,
      currentSeason: currentSeason,
      limit: limit,
    );
  }
}
