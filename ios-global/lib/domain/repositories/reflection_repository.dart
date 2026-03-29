// lib/domain/repositories/reflection_repository.dart
import '../entities/reflection.dart';

abstract class ReflectionRepository {
  Future<Reflection> saveReflection(Reflection reflection);
  Future<List<Reflection>> getReflections({
    required String userId,
    int limit = 30,
    int offset = 0,
  });
  Future<Reflection?> getReflectionByDate(String userId, DateTime date);
  Future<void> deleteReflection(String id);
}
