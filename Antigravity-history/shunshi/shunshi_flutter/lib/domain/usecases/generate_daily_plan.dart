import '../entities/solar_term.dart';
import '../entities/user.dart';
import '../repositories/chat_repository.dart';
import '../../core/utils/logger.dart';

/// 生成每日计划用例
class GenerateDailyPlan {
  final ChatRepository _repository;

  GenerateDailyPlan(this._repository);

  Future<DailyPlan> execute({
    required UserContext userContext,
    required Map<String, String> promptVersions,
  }) async {
    try {
      final startTime = DateTime.now();
      final plan = await _repository.generateDailyPlan(
        userContext: userContext,
        promptVersions: promptVersions,
      );
      final latency = DateTime.now().difference(startTime).inMilliseconds;

      Logger.aiCall(
        requestType: 'daily_plan',
        model: 'unknown', // metadata not always available for plan
        promptVersions: promptVersions,
        totalTokens: 0,
        latencyMs: latency,
        safetyFlag: plan.safetyFlag.toJson(),
        userTier: userContext.isPremium ? 'premium' : 'free',
        schemaValid: true,
      );

      return plan;
    } catch (e) {
      Logger.warning('Daily plan generation failed, using fallback', error: e);
      return DailyPlan.fallback();
    }
  }
}
