import '../entities/content_item.dart';

/// 内容库仓库抽象
abstract class ContentRepository {
  Future<List<ContentItem>> getContentByCategory(ContentCategory category,
      {int page = 0, int limit = 20});
  Future<ContentItem?> getContentById(String id);
  Future<List<ContentItem>> searchContent(String query);
  Future<List<ContentItem>> getContentBySolarTerm(String solarTerm);
}
