// lib/domain/usecases/save_reflection.dart
import '../entities/reflection.dart';
import '../repositories/reflection_repository.dart';

class SaveReflectionUseCase {
  final ReflectionRepository _repository;
  SaveReflectionUseCase(this._repository);

  Future<Reflection> call(Reflection reflection) =>
      _repository.saveReflection(reflection);
}

class GetReflectionsUseCase {
  final ReflectionRepository _repository;
  GetReflectionsUseCase(this._repository);

  Future<List<Reflection>> call({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) {
    return _repository.getReflections(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}
