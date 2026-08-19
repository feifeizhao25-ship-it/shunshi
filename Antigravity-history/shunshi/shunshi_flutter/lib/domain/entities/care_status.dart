/// ──────────────────────────────────────────────────
/// CareStatus — 被照顾状态（万亿级结构核心）
/// 不做打分，不强外显
/// ──────────────────────────────────────────────────
enum CareStatus {
  stable,
  needsAttention,
  escalate;

  factory CareStatus.fromString(String? value) {
    switch (value) {
      case 'needs_attention':
        return CareStatus.needsAttention;
      case 'escalate':
        return CareStatus.escalate;
      case 'stable':
      default:
        return CareStatus.stable;
    }
  }

  String toJson() {
    switch (this) {
      case CareStatus.stable:
        return 'stable';
      case CareStatus.needsAttention:
        return 'needs_attention';
      case CareStatus.escalate:
        return 'escalate';
    }
  }
}

/// PresenceLevel — 存在感级别（退让机制）
enum PresenceLevel {
  normal,
  reduced,
  hidden;

  factory PresenceLevel.fromString(String? value) {
    switch (value) {
      case 'reduced':
        return PresenceLevel.reduced;
      case 'hidden':
        return PresenceLevel.hidden;
      case 'normal':
      default:
        return PresenceLevel.normal;
    }
  }

  String toJson() => name;
}

/// SafetyFlag — 安全标记
enum SafetyFlag {
  green,
  yellow,
  red;

  factory SafetyFlag.fromString(String? value) {
    switch (value) {
      case 'yellow':
        return SafetyFlag.yellow;
      case 'red':
        return SafetyFlag.red;
      case 'green':
      default:
        return SafetyFlag.green;
    }
  }

  String toJson() => name;

  bool get isSafe => this == SafetyFlag.green;
  bool get requiresSafeMode => this == SafetyFlag.red;
}
