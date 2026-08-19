import '../../data/models/follow_up_plan.dart';
import '../../domain/repositories/followup_repository.dart';
import 'local_notifications.dart';

/// 跟进计划调度器
/// - 保存 FollowUpPlan 到本地
/// - 到期时触发首页卡片
/// - 可选地安排本地通知
class FollowUpScheduler {
  final FollowUpRepository _repository;

  FollowUpScheduler({required FollowUpRepository repository})
      : _repository = repository;

  Future<void> schedule({
    required String userId,
    required FollowUpPlan plan,
    bool enableNotification = false,
  }) async {
    await _repository.saveFollowUp(plan, userId: userId);

    if (enableNotification) {
      final dueDate = plan.dueDate();
      // Only schedule if due in the future
      if (dueDate.isAfter(DateTime.now())) {
        await LocalNotifications.scheduleFollowUp(
          id: plan.intent.hashCode,
          title: '顺时想起你了',
          body: '上次聊到"${plan.intentLabel}"，现在还好吗？',
          scheduledDate: dueDate,
        );
      }
    }
  }

  /// 检查并返回到期的跟进计划
  Future<List<FollowUpPlan>> getDuePlans(String userId) async {
    final pending = await _repository.getPendingFollowUps(userId);
    return pending.where((p) => p.isDue).toList();
  }

  Future<void> markCompleted(String userId, String intentId) async {
    await _repository.markCompleted(userId, intentId);
    await LocalNotifications.cancel(intentId.hashCode);
  }
}
