import '../entities/care_status.dart';
import '../entities/follow_up_plan.dart';
import '../../core/constants/app_constants.dart';

/// 退让机制用例
class ApplyPresencePolicy {
  /// 评估当前存在感级别
  PresenceLevel evaluate(PresenceRecord record) {
    // 规则1: 用户主动开启静默 → 立即生效
    if (record.silentModeActive) return PresenceLevel.hidden;

    // 规则2: 连续 N 次不回应 → 降频
    if (record.consecutiveIgnores >= AppConstants.presenceIgnoreThreshold) {
      return PresenceLevel.reduced;
    }

    // 规则3: 稳定期隐身（CareStatus 连续 N 天 stable）
    if (record.stableDays >= AppConstants.presenceStableDaysThreshold) {
      return PresenceLevel.hidden;
    }

    return PresenceLevel.normal;
  }
}
