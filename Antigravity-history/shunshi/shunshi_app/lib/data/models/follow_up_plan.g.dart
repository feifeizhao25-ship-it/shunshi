// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'follow_up_plan.dart';

FollowUpPlan _$FollowUpPlanFromJson(Map<String, dynamic> json) => FollowUpPlan(
      inDays: json['in_days'] as int,
      intent: json['intent'] as String,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$FollowUpPlanToJson(FollowUpPlan instance) =>
    <String, dynamic>{
      'in_days': instance.inDays,
      'intent': instance.intent,
      'scheduled_at': instance.scheduledAt?.toIso8601String(),
      'completed': instance.completed,
    };
