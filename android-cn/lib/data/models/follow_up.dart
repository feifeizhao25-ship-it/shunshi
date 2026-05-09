// Follow-up 系统模型和服务
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Follow-up 类型
enum FollowUpType {
  /// 养生建议
  wellness,
  
  /// 情绪陪伴
  emotional,
  
  /// 生活方式
  lifestyle,
  
  /// 内容推荐
  content,
  
  /// 家庭关怀
  family,
}

/// Follow-up 状态
enum FollowUpStatus {
  /// 待执行
  pending,
  
  /// 已完成
  completed,
  
  /// 已跳过
  skipped,
  
  /// 已过期
  expired,
}

/// Follow-up 模型
class FollowUp {
  final String id;
  final String title;
  final String? description;
  final FollowUpType type;
  final FollowUpStatus status;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  
  const FollowUp({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    this.scheduledAt,
    this.completedAt,
    required this.createdAt,
    this.metadata,
  });
  
  factory FollowUp.create({
    required String title,
    String? description,
    required FollowUpType type,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) {
    return FollowUp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      status: FollowUpStatus.pending,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }
  
  FollowUp copyWith({
    String? id,
    String? title,
    String? description,
    FollowUpType? type,
    FollowUpStatus? status,
    DateTime? scheduledAt,
    DateTime? completedAt,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return FollowUp(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// 是否可以执行
  bool get canExecute {
    if (status != FollowUpStatus.pending) return false;
    if (scheduledAt == null) return true;
    return DateTime.now().isAfter(scheduledAt!);
  }
  
  /// 是否已过期
  bool get isExpired {
    if (scheduledAt == null) return false;
    return DateTime.now().isAfter(scheduledAt!.add(const Duration(days: 1)));
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };
  
  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: FollowUpType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => FollowUpType.wellness,
    ),
    status: FollowUpStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => FollowUpStatus.pending,
    ),
    scheduledAt: json['scheduledAt'] != null 
        ? DateTime.parse(json['scheduledAt']) 
        : null,
    completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt']) 
        : null,
    createdAt: DateTime.parse(json['createdAt']),
    metadata: json['metadata'],
  );
}

/// Follow-up Provider
final followUpProvider = StateNotifierProvider<FollowUpNotifier, List<FollowUp>>((ref) {
  return FollowUpNotifier();
});

class FollowUpNotifier extends StateNotifier<List<FollowUp>> {
  FollowUpNotifier() : super([]);
  
  /// 添加 Follow-up
  void add(FollowUp followUp) {
    state = [...state, followUp];
  }
  
  /// 创建新的 Follow-up
  void create({
    required String title,
    String? description,
    required FollowUpType type,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) {
    final followUp = FollowUp.create(
      title: title,
      description: description,
      type: type,
      scheduledAt: scheduledAt,
      metadata: metadata,
    );
    add(followUp);
  }
  
  /// 标记为完成
  void complete(String id) {
    state = state.map((f) {
      if (f.id == id) {
        return f.copyWith(
          status: FollowUpStatus.completed,
          completedAt: DateTime.now(),
        );
      }
      return f;
    }).toList();
  }
  
  /// 跳过
  void skip(String id) {
    state = state.map((f) {
      if (f.id == id) {
        return f.copyWith(status: FollowUpStatus.skipped);
      }
      return f;
    }).toList();
  }
  
  /// 删除
  void remove(String id) {
    state = state.where((f) => f.id != id).toList();
  }
  
  /// 获取待执行的 Follow-ups
  List<FollowUp> get pending {
    return state.where((f) => 
      f.status == FollowUpStatus.pending && 
      (f.scheduledAt == null || DateTime.now().isAfter(f.scheduledAt!))
    ).toList();
  }
  
  /// 获取今天的 Follow-ups
  List<FollowUp> get today {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return state.where((f) {
      if (f.createdAt.isBefore(endOfDay)) {
        if (f.scheduledAt == null) return true;
        return f.scheduledAt!.isAfter(startOfDay) && f.scheduledAt!.isBefore(endOfDay);
      }
      return false;
    }).toList();
  }
  
  /// 清理过期的 Follow-ups
  void cleanExpired() {
    state = state.where((f) => !f.isExpired).toList();
  }
  
  /// 从 JSON 加载
  void loadFromJson(List<dynamic> jsonList) {
    state = jsonList.map((json) => FollowUp.fromJson(json)).toList();
  }
  
  /// 导出为 JSON
  List<Map<String, dynamic>> toJson() {
    return state.map((f) => f.toJson()).toList();
  }
}

/// Follow-up 类型显示名称
extension FollowUpTypeExtension on FollowUpType {
  String get displayName {
    switch (this) {
      case FollowUpType.wellness:
        return '养生建议';
      case FollowUpType.emotional:
        return '情绪陪伴';
      case FollowUpType.lifestyle:
        return '生活方式';
      case FollowUpType.content:
        return '内容推荐';
      case FollowUpType.family:
        return '家庭关怀';
    }
  }
  
  String get icon {
    switch (this) {
      case FollowUpType.wellness:
        return '🌿';
      case FollowUpType.emotional:
        return '💚';
      case FollowUpType.lifestyle:
        return '🏃';
      case FollowUpType.content:
        return '📚';
      case FollowUpType.family:
        return '👨‍👩‍👧';
    }
  }
}
