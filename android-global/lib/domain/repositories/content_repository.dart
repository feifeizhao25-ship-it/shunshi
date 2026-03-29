// lib/domain/repositories/content_repository.dart
import '../entities/content.dart';

abstract class ContentRepository {
  Future<List<Content>> getContents({
    String? type,
    String? season,
    String? hemisphere,
    int limit = 20,
    int offset = 0,
  });
  Future<Content?> getContentById(String id);
  Future<List<Content>> searchContents(String query);
  Future<List<Content>> getPersonalizedContents({
    required String userId,
    required String hemisphere,
    String? currentSeason,
    int limit = 10,
  });
}
