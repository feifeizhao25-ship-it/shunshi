// 推荐算法服务

/// 用户行为数据
class UserBehavior {
  final String userId;
  final List<String> viewedContentIds;
  final List<String> likedContentIds;
  final List<String> completedContentIds;
  final Map<String, int> categoryViews;
  final Map<String, int> tagViews;
  final List<String> searchQueries;
  
  const UserBehavior({
    required this.userId,
    this.viewedContentIds = const [],
    this.likedContentIds = const [],
    this.completedContentIds = const [],
    this.categoryViews = const {},
    this.tagViews = const {},
    this.searchQueries = const [],
  });
  
  /// 获取用户兴趣标签
  List<String> get interestTags {
    final sorted = tagViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }
  
  /// 获取用户偏好分类
  List<String> get preferredCategories {
    final sorted = categoryViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}

/// 内容项
class ContentItem {
  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final List<String> tags;
  final double popularity;
  final DateTime createdAt;
  final bool isPremium;
  
  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.tags = const [],
    this.popularity = 0.5,
    required this.createdAt,
    this.isPremium = false,
  });
}

/// 推荐结果
class Recommendation {
  final String contentId;
  final String title;
  final double score;
  final String reason;
  
  const Recommendation({
    required this.contentId,
    required this.title,
    required this.score,
    required this.reason,
  });
}

/// 推荐算法
class RecommendationEngine {
  /// 基于内容的推荐
  static List<Recommendation> contentBased(
    UserBehavior behavior,
    List<ContentItem> contents, {
    int limit = 10,
  }) {
    if (contents.isEmpty) return [];
    
    // 计算每个内容的得分
    final scores = <String, double>{};
    final reasons = <String, String>{};
    
    for (final content in contents) {
      double score = 0;
      String reason = '';
      
      // 1. 标签匹配 (权重: 0.4)
      final matchingTags = content.tags
          .where((tag) => behavior.interestTags.contains(tag))
          .length;
      if (matchingTags > 0) {
        score += matchingTags * 0.4;
        reason += '标签匹配 ';
      }
      
      // 2. 分类偏好 (权重: 0.3)
      if (behavior.preferredCategories.contains(content.category)) {
        score += 0.3;
        reason += '分类偏好 ';
      }
      
      // 3. 热门度 (权重: 0.2)
      score += content.popularity * 0.2;
      
      // 4. 去除已查看的
      if (!behavior.viewedContentIds.contains(content.id)) {
        scores[content.id] = score;
        reasons[content.id] = reason.isEmpty ? '推荐内容' : reason;
      }
    }
    
    // 排序并返回 top N
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) {
      final content = contents.firstWhere((c) => c.id == e.key);
      return Recommendation(
        contentId: e.key,
        title: content.title,
        score: e.value,
        reason: reasons[e.key] ?? '推荐内容',
      );
    }).toList();
  }
  
  /// 协同过滤推荐
  static List<Recommendation> collaborative(
    Map<String, UserBehavior> allUsers,
    String targetUserId,
    List<ContentItem> contents, {
    int limit = 10,
  }) {
    if (contents.isEmpty || allUsers.isEmpty) return [];
    
    // 找到相似用户 (简单实现: 基于标签重叠)
    final targetBehavior = allUsers[targetUserId];
    if (targetBehavior == null) {
      // 没有历史数据，返回热门推荐
      return popular(contents, limit: limit);
    }
    
    // 计算与每个用户的相似度
    final similarities = <String, double>{};
    
    for (final entry in allUsers.entries) {
      if (entry.key == targetUserId) continue;
      
      final similarity = _calculateSimilarity(targetBehavior, entry.value);
      similarities[entry.key] = similarity;
    }
    
    // 排序找到最相似的用户
    final sortedSimilarUsers = similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topSimilarUsers = sortedSimilarUsers.take(10).toList();
    
    // 收集相似用户喜欢但目标用户没看过的内容
    final recommendedIds = <String, double>{};
    
    for (final similarUser in topSimilarUsers) {
      final similarBehavior = allUsers[similarUser.key]!;
      
      for (final likedId in similarBehavior.likedContentIds) {
        if (!targetBehavior.viewedContentIds.contains(likedId)) {
          recommendedIds[likedId] = (recommendedIds[likedId] ?? 0) + similarUser.value;
        }
      }
    }
    
    // 排序并返回
    final sorted = recommendedIds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) {
      final content = contents.firstWhere(
        (c) => c.id == e.key,
        orElse: () => contents.first,
      );
      return Recommendation(
        contentId: e.key,
        title: content.title,
        score: e.value,
        reason: '相似用户也喜欢',
      );
    }).toList();
  }
  
  /// 热门推荐
  static List<Recommendation> popular(
    List<ContentItem> contents, {
    int limit = 10,
  }) {
    if (contents.isEmpty) return [];
    
    final sorted = contents.toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    
    return sorted.take(limit).map((content) => Recommendation(
      contentId: content.id,
      title: content.title,
      score: content.popularity,
      reason: '热门推荐',
    )).toList();
  }
  
  /// 混合推荐
  static List<Recommendation> hybrid(
    UserBehavior behavior,
    Map<String, UserBehavior> allUsers,
    List<ContentItem> contents, {
    int limit = 10,
    double contentWeight = 0.6,
    double collaborativeWeight = 0.4,
  }) {
    // 分别计算两种推荐
    final contentRecs = contentBased(behavior, contents, limit: limit * 2);
    final collabRecs = collaborative(allUsers, behavior.userId, contents, limit: limit * 2);
    
    // 合并得分
    final scores = <String, double>{};
    final reasons = <String, String>{};
    
    for (final rec in contentRecs) {
      scores[rec.contentId] = (scores[rec.contentId] ?? 0) + rec.score * contentWeight;
      reasons[rec.contentId] = rec.reason;
    }
    
    for (final rec in collabRecs) {
      scores[rec.contentId] = (scores[rec.contentId] ?? 0) + rec.score * collaborativeWeight;
      reasons[rec.contentId] = '${reasons[rec.contentId]} 相似用户推荐';
    }
    
    // 排序并返回
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) {
      final content = contents.firstWhere(
        (c) => c.id == e.key,
        orElse: () => contents.first,
      );
      return Recommendation(
        contentId: e.key,
        title: content.title,
        score: e.value,
        reason: reasons[e.key] ?? '推荐',
      );
    }).toList();
  }
  
  /// 计算用户相似度
  static double _calculateSimilarity(UserBehavior a, UserBehavior b) {
    // 基于标签重叠计算相似度
    final aTags = Set<String>.from(a.interestTags);
    final bTags = Set<String>.from(b.interestTags);
    
    if (aTags.isEmpty || bTags.isEmpty) return 0;
    
    final intersection = aTags.intersection(bTags).length;
    final union = aTags.union(bTags).length;
    
    return union > 0 ? intersection / union : 0;
  }
}

/// 今日推荐
class TodayRecommendation {
  final String title;
  final String description;
  final String emoji;
  final List<String> suggestions;
  final DateTime date;
  
  const TodayRecommendation({
    required this.title,
    required this.description,
    required this.emoji,
    required this.suggestions,
    required this.date,
  });
  
  /// 生成今日推荐
  static TodayRecommendation generate(DateTime date) {
    final hour = date.hour;
    
    String title;
    String description;
    String emoji;
    List<String> suggestions;
    
    if (hour < 12) {
      title = '早安';
      description = '新的一天开始了';
      emoji = '🌅';
      suggestions = [
        '喝一杯温水',
        '适度运动',
        '营养早餐',
      ];
    } else if (hour < 14) {
      title = '午安';
      description = '注意休息';
      emoji = '☀️';
      suggestions = [
        '适当午休',
        '午餐不宜过饱',
        '短暂散步',
      ];
    } else if (hour < 18) {
      title = '下午好';
      description = '保持精力';
      emoji = '🌤️';
      suggestions = [
        '适量运动',
        '多喝水',
        '眼保健操',
      ];
    } else {
      title = '晚安';
      description = '准备休息';
      emoji = '🌙';
      suggestions = [
        '睡前泡脚',
        '避免使用手机',
        '深呼吸放松',
      ];
    }
    
    return TodayRecommendation(
      title: title,
      description: description,
      emoji: emoji,
      suggestions: suggestions,
      date: date,
    );
  }
}
