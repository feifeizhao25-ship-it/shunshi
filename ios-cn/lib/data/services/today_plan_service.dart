// 今日养生计划 API 服务
import 'package:dio/dio.dart';

/// 今日养生计划
class TodayPlan {
  final String id;
  final String date;
  final List<TodayInsight> insights;
  final List<FollowUpTask> tasks;
  final List<ContentRecommendation> recommendations;
  final SolarTermCard? solarTerm;
  
  const TodayPlan({
    required this.id,
    required this.date,
    required this.insights,
    required this.tasks,
    required this.recommendations,
    this.solarTerm,
  });
  
  factory TodayPlan.fromJson(Map<String, dynamic> json) => TodayPlan(
    id: json['id'] ?? '',
    date: json['date'] ?? '',
    insights: (json['insights'] as List<dynamic>?)
        ?.map((e) => TodayInsight.fromJson(e))
        .toList() ?? [],
    tasks: (json['tasks'] as List<dynamic>?)
        ?.map((e) => FollowUpTask.fromJson(e))
        .toList() ?? [],
    recommendations: (json['recommendations'] as List<dynamic>?)
        ?.map((e) => ContentRecommendation.fromJson(e))
        .toList() ?? [],
    solarTerm: json['solarTerm'] != null 
        ? SolarTermCard.fromJson(json['solarTerm']) 
        : null,
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'insights': insights.map((e) => e.toJson()).toList(),
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'recommendations': recommendations.map((e) => e.toJson()).toList(),
    'solarTerm': solarTerm?.toJson(),
  };
}

/// 今日洞察
class TodayInsight {
  final String id;
  final String title;
  final String content;
  final String icon;
  final InsightType type;
  
  const TodayInsight({
    required this.id,
    required this.title,
    required this.content,
    required this.icon,
    required this.type,
  });
  
  factory TodayInsight.fromJson(Map<String, dynamic> json) => TodayInsight(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    icon: json['icon'] ?? '💡',
    type: InsightType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => InsightType.general,
    ),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'icon': icon,
    'type': type.name,
  };
}

enum InsightType {
  health,
  emotional,
  lifestyle,
  solarTerm,
  general,
}

/// Follow-up 任务
class FollowUpTask {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? category;
  final String? timeSlot;
  
  const FollowUpTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.category,
    this.timeSlot,
  });
  
  factory FollowUpTask.fromJson(Map<String, dynamic> json) => FollowUpTask(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    status: TaskStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TaskStatus.pending,
    ),
    priority: TaskPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => TaskPriority.normal,
    ),
    category: json['category'],
    timeSlot: json['time_slot'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'category': category,
    'time_slot': timeSlot,
  };
}

enum TaskStatus {
  pending,
  completed,
  skipped,
}

enum TaskPriority {
  high,
  normal,
  low,
}

/// 内容推荐
class ContentRecommendation {
  final String id;
  final String title;
  final String? description;
  final ContentType type;
  final String? imageUrl;
  final String? actionUrl;
  
  const ContentRecommendation({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.imageUrl,
    this.actionUrl,
  });
  
  factory ContentRecommendation.fromJson(Map<String, dynamic> json) => ContentRecommendation(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    type: ContentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ContentType.article,
    ),
    imageUrl: json['imageUrl'],
    actionUrl: json['actionUrl'],
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'imageUrl': imageUrl,
    'actionUrl': actionUrl,
  };
}

enum ContentType {
  article,
  video,
  audio,
  recipe,
  exercise,
  tips,
}

/// 节气卡片
class SolarTermCard {
  final String name;
  final String emoji;
  final String description;
  final List<String> suggestions;
  final DateTime date;
  
  const SolarTermCard({
    required this.name,
    required this.emoji,
    required this.description,
    required this.suggestions,
    required this.date,
  });
  
  factory SolarTermCard.fromJson(Map<String, dynamic> json) => SolarTermCard(
    name: json['name'] ?? '',
    emoji: json['emoji'] ?? '🌱',
    description: json['description'] ?? '',
    suggestions: List<String>.from(json['suggestions'] ?? []),
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
  );
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'description': description,
    'suggestions': suggestions,
    'date': date.toIso8601String(),
  };
}

/// 今日计划 API 服务
class TodayPlanService {
  final Dio _dio;
  
  TodayPlanService(this._dio);
  
  /// 获取今日计划
  Future<TodayPlan> getTodayPlan() async {
    try {
      final response = await _dio.get('/api/v1/today-plan');
      return TodayPlan.fromJson(response.data);
    } catch (e) {
      // 返回默认计划
      return _getDefaultPlan();
    }
  }
  
  /// 更新任务状态
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _dio.patch(
      '/api/v1/today-plan/tasks/$taskId',
      data: {'status': status.name},
    );
  }
  
  /// 刷新今日计划
  Future<TodayPlan> refreshPlan() async {
    try {
      final response = await _dio.post('/api/v1/today-plan/refresh');
      return TodayPlan.fromJson(response.data);
    } catch (e) {
      return _getDefaultPlan();
    }
  }
  
  /// 获取默认计划
  TodayPlan _getDefaultPlan() {
    return TodayPlan(
      id: DateTime.now().toIso8601String(),
      date: DateTime.now().toIso8601String().split('T')[0],
      insights: [
        const TodayInsight(
          id: '1',
          title: '早安',
          content: '新的一天开始了，记得喝一杯温水',
          icon: '🌅',
          type: InsightType.general,
        ),
      ],
      tasks: [
        const FollowUpTask(
          id: '1',
          title: '喝一杯温水',
          description: '帮助身体排毒',
          status: TaskStatus.pending,
          priority: TaskPriority.normal,
          category: 'health',
        ),
      ],
      recommendations: [],
      solarTerm: SolarTermCard(
        name: '春分',
        emoji: '🌱',
        description: '阴阳平衡，昼夜相等',
        suggestions: ['适当运动', '调理脾胃'],
        date: DateTime.now(),
      ),
    );
  }
}
