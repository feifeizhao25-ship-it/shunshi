import '../entities/ai_response.dart';
import '../entities/follow_up_plan.dart';

/// 调度跟进计划用例
class ScheduleFollowUp {
  /// 从 AI 响应中提取跟进计划
  FollowUpPlan? extractFromResponse(AIResponse response) {
    final followUp = response.followUp;
    if (followUp == null) return null;

    return FollowUpPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      inDays: followUp.inDays,
      intent: followUp.intent,
      topic: followUp.topic,
      scheduledAt: followUp.scheduledAt,
      createdAt: DateTime.now(),
    );
  }
}
