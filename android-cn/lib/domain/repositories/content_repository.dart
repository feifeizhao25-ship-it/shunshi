// lib/domain/repositories/content_repository.dart
// 养生内容仓储接口

import '../entities/content.dart';

abstract class ContentRepository {
  /// 获取内容列表
  Future<List<Content>> getContents({
    ContentType? type,
    String? season,
    String? solarTerm,
    int limit = 20,
    int offset = 0,
  });

  /// 获取内容详情
  Future<Content?> getContentById(String id);

  /// 搜索内容
  Future<List<Content>> searchContents(String query);

  /// 获取个性化推荐内容
  Future<List<Content>> getPersonalizedContents({
    required String userId,
    required String constitution,
    String? currentSolarTerm,
    int limit = 10,
  });
}
