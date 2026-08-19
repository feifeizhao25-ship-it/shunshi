/// CareStatus - 照护状态枚举
/// 默认不外显，仅内部用于触发策略
enum CareStatus {
  /// 用户状态稳定
  stable,

  /// 需要关注 - 触发主动关怀策略
  needsAttention,

  /// 升级处理 - 进入 SafeMode
  escalate,
}

extension CareStatusX on CareStatus {
  String get value {
    switch (this) {
      case CareStatus.stable:
        return 'stable';
      case CareStatus.needsAttention:
        return 'needs_attention';
      case CareStatus.escalate:
        return 'escalate';
    }
  }

  static CareStatus fromString(String value) {
    switch (value) {
      case 'needs_attention':
        return CareStatus.needsAttention;
      case 'escalate':
        return CareStatus.escalate;
      default:
        return CareStatus.stable;
    }
  }

  bool get isNormal => this == CareStatus.stable;
  bool get needsAction => this != CareStatus.stable;
}
