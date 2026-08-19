import '../../data/models/content_item.dart';

abstract class ContentRepository {
  /// 获取内容列表
  Future<List<ContentItem>> getContentList({
    ContentType? type,
    int page = 0,
    int limit = 20,
  });

  /// 获取内容详情
  Future<ContentItem?> getContentDetail(String id);

  /// 搜索内容
  Future<List<ContentItem>> searchContent(String query);

  /// 获取今日推荐内容
  Future<List<ContentItem>> getDailyRecommendations();
}
