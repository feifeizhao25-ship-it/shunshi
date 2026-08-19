import '../../data/models/follow_up_plan.dart';

abstract class FollowUpRepository {
  Future<void> saveFollowUp(FollowUpPlan plan, {required String userId});
  Future<List<FollowUpPlan>> getPendingFollowUps(String userId);
  Future<void> markCompleted(String userId, String intentId);
  Future<void> clearAll(String userId);
}
