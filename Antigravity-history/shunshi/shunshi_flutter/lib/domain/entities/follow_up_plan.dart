import 'care_status.dart';

/// ──────────────────────────────────────────────────
/// FollowUpPlan — 跟进计划
/// ──────────────────────────────────────────────────
class FollowUpPlan {
  final String id;
  final int inDays;
  final String intent;
  final String topic;
  final DateTime scheduledAt;
  final bool isDismissed;
  final DateTime createdAt;

  const FollowUpPlan({
    required this.id,
    required this.inDays,
    required this.intent,
    required this.topic,
    required this.scheduledAt,
    this.isDismissed = false,
    required this.createdAt,
  });

  FollowUpPlan copyWith({bool? isDismissed}) => FollowUpPlan(
        id: id,
        inDays: inDays,
        intent: intent,
        topic: topic,
        scheduledAt: scheduledAt,
        isDismissed: isDismissed ?? this.isDismissed,
        createdAt: createdAt,
      );

  factory FollowUpPlan.fromJson(Map<String, dynamic> json) => FollowUpPlan(
        id: json['id'] as String? ?? '',
        inDays: json['in_days'] as int? ?? 1,
        intent: json['intent'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? '') ??
            DateTime.now(),
        isDismissed: json['is_dismissed'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'in_days': inDays,
        'intent': intent,
        'topic': topic,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_dismissed': isDismissed,
        'created_at': createdAt.toIso8601String(),
      };
}

/// ──────────────────────────────────────────────────
/// LifePhaseSummary — 阶段记忆（摘要型，非原始记录）
/// 可清空、可关闭
/// ──────────────────────────────────────────────────
class LifePhaseSummary {
  final String userId;
  final String summary;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> keyTopics;
  final CareStatus overallStatus;
  final DateTime updatedAt;

  const LifePhaseSummary({
    required this.userId,
    required this.summary,
    required this.periodStart,
    required this.periodEnd,
    this.keyTopics = const [],
    this.overallStatus = CareStatus.stable,
    required this.updatedAt,
  });

  factory LifePhaseSummary.fromJson(Map<String, dynamic> json) =>
      LifePhaseSummary(
        userId: json['user_id'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        periodStart:
            DateTime.tryParse(json['period_start'] as String? ?? '') ??
                DateTime.now(),
        periodEnd: DateTime.tryParse(json['period_end'] as String? ?? '') ??
            DateTime.now(),
        keyTopics: (json['key_topics'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        overallStatus:
            CareStatus.fromString(json['overall_status'] as String?),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'summary': summary,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'key_topics': keyTopics,
        'overall_status': overallStatus.toJson(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// ──────────────────────────────────────────────────
/// PresenceRecord — 退让机制的本地状态
/// ──────────────────────────────────────────────────
class PresenceRecord {
  final int consecutiveIgnores;
  final int stableDays;
  final bool silentModeActive;
  final DateTime? lastResponseTime;

  const PresenceRecord({
    this.consecutiveIgnores = 0,
    this.stableDays = 0,
    this.silentModeActive = false,
    this.lastResponseTime,
  });

  factory PresenceRecord.fromJson(Map<String, dynamic> json) =>
      PresenceRecord(
        consecutiveIgnores: json['consecutive_ignores'] as int? ?? 0,
        stableDays: json['stable_days'] as int? ?? 0,
        silentModeActive: json['silent_mode_active'] as bool? ?? false,
        lastResponseTime: json['last_response_time'] != null
            ? DateTime.tryParse(json['last_response_time'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'consecutive_ignores': consecutiveIgnores,
        'stable_days': stableDays,
        'silent_mode_active': silentModeActive,
        'last_response_time': lastResponseTime?.toIso8601String(),
      };
}
