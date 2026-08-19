/// Presence Policy Use Case
/// 连续 3 次用户未回复主动关怀 → presence_level=reduced
class ApplyPresencePolicy {
  static const int _threshold = 3;

  /// 判断是否需要降频
  PresencePolicyResult apply({
    required int consecutiveUnansweredCount,
    required String currentPresenceLevel,
  }) {
    if (consecutiveUnansweredCount >= _threshold &&
        currentPresenceLevel != 'reduced') {
      return PresencePolicyResult.reduce;
    }
    if (consecutiveUnansweredCount == 0 && currentPresenceLevel == 'reduced') {
      return PresencePolicyResult.restore;
    }
    return PresencePolicyResult.noChange;
  }
}

enum PresencePolicyResult {
  /// 降频：减少主动关怀频率
  reduce,

  /// 恢复正常频率
  restore,

  /// 无变化
  noChange,
}
