import '../../data/models/content_item.dart';
import '../../domain/repositories/content_repository.dart';

/// 内容库仓库实现（含 mock 数据，后端接入后替换 API 调用）
class ContentRepositoryImpl implements ContentRepository {
  @override
  Future<List<ContentItem>> getContentList({
    ContentType? type,
    int page = 0,
    int limit = 20,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    final all = _mockContent();
    final filtered = type != null
        ? all.where((c) => c.type == type).toList()
        : all;
    final start = page * limit;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, (start + limit).clamp(0, filtered.length));
  }

  @override
  Future<ContentItem?> getContentDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockContent().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ContentItem>> searchContent(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lower = query.toLowerCase();
    return _mockContent()
        .where((c) =>
            c.title.toLowerCase().contains(lower) ||
            (c.description?.toLowerCase().contains(lower) ?? false))
        .toList();
  }

  @override
  Future<List<ContentItem>> getDailyRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockContent().take(3).toList();
  }

  List<ContentItem> _mockContent() => [
        ContentItem(
          id: 'content_001',
          title: '惊蛰养肝：春日疏肝三式',
          subtitle: '顺应节气，调和肝气',
          description: '惊蛰节气时，阳气生发，肝气旺盛。通过简单的伸展动作疏肝解郁，让身体与自然同频共振。',
          type: ContentType.exercise,
          tags: ['惊蛰', '肝气', '运动'],
          readTimeMinutes: 5,
        ),
        ContentItem(
          id: 'content_002',
          title: '足三里穴位按摩',
          subtitle: '强健脾胃，增强免疫',
          description: '足三里是胃经的重要穴位，每天轻轻按摩可以帮助健脾和胃，提升整体精气神。',
          type: ContentType.acupoint,
          tags: ['穴位', '脾胃', '日常保健'],
          readTimeMinutes: 3,
        ),
        ContentItem(
          id: 'content_003',
          title: '春日养生粥：红枣枸杞粥',
          subtitle: '滋补气血，养颜润肤',
          description: '以红枣、枸杞、粳米为主料，熬制的养生粥，温和滋补，适合春季日常食用。',
          type: ContentType.recipe,
          tags: ['食谱', '春季', '气血'],
          readTimeMinutes: 4,
        ),
        ContentItem(
          id: 'content_004',
          title: '晨间五分钟冥想',
          subtitle: '清醒大脑，开启能量满满的一天',
          description: '每天清晨花五分钟进行呼吸与正念冥想，让身心平静下来，为一天的活动积累能量。',
          type: ContentType.meditation,
          isPremium: true,
          tags: ['冥想', '晨间', '正念'],
          readTimeMinutes: 5,
        ),
        ContentItem(
          id: 'content_005',
          title: '节气养生：春分饮食宜忌',
          subtitle: '了解春分的食养原则',
          description: '春分时节阴阳平衡，饮食上应注意减酸增甘，多食甘性食物，以养脾气。',
          type: ContentType.article,
          tags: ['春分', '饮食', '节气'],
          readTimeMinutes: 6,
        ),
        ContentItem(
          id: 'content_006',
          title: '经络拍打操：唤醒全身阳气',
          subtitle: '十分钟全身经络疏通',
          description: '通过规律的经络拍打动作，激活全身气血循环，尤其适合久坐人群在工间进行。',
          type: ContentType.video,
          isPremium: true,
          tags: ['经络', '拍打操', '阳气'],
          readTimeMinutes: 10,
        ),
      ];
}
