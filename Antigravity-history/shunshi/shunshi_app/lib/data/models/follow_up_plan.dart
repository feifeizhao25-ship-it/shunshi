import 'package:json_annotation/json_annotation.dart';

part 'follow_up_plan.g.dart';

@JsonSerializable()
class FollowUpPlan {
  @JsonKey(name: 'in_days')
  final int inDays;
  final String intent;
  final DateTime? scheduledAt;
  final bool completed;

  const FollowUpPlan({
    required this.inDays,
    required this.intent,
    this.scheduledAt,
    this.completed = false,
  });

  FollowUpPlan copyWith({
    int? inDays,
    String? intent,
    DateTime? scheduledAt,
    bool? completed,
  }) {
    return FollowUpPlan(
      inDays: inDays ?? this.inDays,
      intent: intent ?? this.intent,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completed: completed ?? this.completed,
    );
  }

  /// 根据创建时间计算到期时间
  DateTime dueDate([DateTime? from]) {
    final base = from ?? DateTime.now();
    return base.add(Duration(days: inDays));
  }

  bool get isDue => DateTime.now().isAfter(dueDate());

  String get intentLabel {
    switch (intent) {
      case 'sleep_check':
        return '睡眠状况';
      case 'emotion_check':
        return '情绪状态';
      case 'exercise_check':
        return '运动情况';
      case 'diet_check':
        return '饮食规律';
      case 'general_check':
        return '日常问候';
      default:
        return '跟进了解';
    }
  }

  factory FollowUpPlan.fromJson(Map<String, dynamic> json) =>
      _$FollowUpPlanFromJson(json);
  Map<String, dynamic> toJson() => _$FollowUpPlanToJson(this);
}
