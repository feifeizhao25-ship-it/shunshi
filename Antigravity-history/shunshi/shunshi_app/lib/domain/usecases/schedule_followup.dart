import '../../data/models/follow_up_plan.dart';
import '../repositories/followup_repository.dart';

class ScheduleFollowup {
  final FollowUpRepository _repository;

  ScheduleFollowup(this._repository);

  Future<void> call({
    required String userId,
    required FollowUpPlan plan,
  }) async {
    if (plan.inDays <= 0) return;
    await _repository.saveFollowUp(plan, userId: userId);
  }
}
