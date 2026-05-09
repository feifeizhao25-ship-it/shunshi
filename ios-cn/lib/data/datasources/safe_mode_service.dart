// lib/data/datasources/safe_mode_service.dart

/// SafeMode 安全模式 - 异常情绪检测与处理
class SafeModeService {
  /// 检查是否需要进入 SafeMode
  Future<SafeModeResult> checkSafeMode({
    required String userId,
    required String message,
    required Map<String, dynamic> emotionAnalysis,
  }) async {
    // 1. 检测异常情绪信号
    final hasRiskSignals = _detectRiskSignals(message);

    // 2. 检测情绪持续低落
    final hasPersistentLowMood = await _checkPersistentLowMood(userId);

    // 3. 检测自伤/自杀倾向
    final hasSelfHarmSignals = _detectSelfHarmSignals(message);

    if (hasSelfHarmSignals) {
      return SafeModeResult(
        shouldEnter: true,
        level: SafeModeLevel.critical,
        message: _getCriticalMessage(),
        shouldAlertAuthorities: true,
      );
    }

    if (hasRiskSignals || hasPersistentLowMood) {
      return SafeModeResult(
        shouldEnter: true,
        level: SafeModeLevel.elevated,
        message: _getElevatedMessage(),
        shouldAlertAuthorities: false,
      );
    }

    return SafeModeResult(shouldEnter: false);
  }

  /// 进入 SafeMode
  Future<void> enterSafeMode({
    required String userId,
    required SafeModeLevel level,
  }) async {
    // 1. 记录状态
    await _recordSafeModeEntry(userId, level);

    // 2. 调整 AI 响应策略
    await _adjustAIBehavior(userId, level);

    // 3. 如果是严重级别，通知相关人员
    if (level == SafeModeLevel.critical) {
      await _notifyEmergencyContacts(userId);
    }
  }

  /// 退出 SafeMode
  Future<void> exitSafeMode(String userId) async {
    await _recordSafeModeExit(userId);
    await _resetAIBehavior(userId);
  }

  // 风险信号检测
  bool _detectRiskSignals(String message) {
    final riskKeywords = [
      '难过', '绝望', '崩溃', '坚持不了',
      '好累', '不想活了', '没意思',
      '失眠', '焦虑', '害怕',
    ];

    final lowerMessage = message.toLowerCase();
    return riskKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  // 自伤/自杀倾向检测
  bool _detectSelfHarmSignals(String message) {
    final dangerKeywords = [
      '自杀', '轻生', '自残', '结束生命',
      '不想活了', '死了就好了',
    ];

    final lowerMessage = message.toLowerCase();
    return dangerKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  // 检查持续低落
  Future<bool> _checkPersistentLowMood(String userId) async {
    // TODO: 检查最近7天的情绪数据
    // 如果连续多天负面情绪 > 阈值，返回 true
    return false;
  }

  String _getCriticalMessage() {
    return '我感受到你可能正在经历非常困难的时刻。你很重要，我希望你能得到帮助。';
  }

  String _getElevatedMessage() {
    return '我在这里陪着你。如果你愿意，可以和我聊聊你的感受。';
  }

  Future<void> _recordSafeModeEntry(String userId, SafeModeLevel level) async {
    // TODO: 记录到数据库
  }

  Future<void> _adjustAIBehavior(String userId, SafeModeLevel level) async {
    // TODO: 调整 AI 的响应策略
    // - 更温柔的回应
    // - 更多的共情
    // - 避免触发性的内容
  }

  Future<void> _notifyEmergencyContacts(String userId) async {
    // TODO: 通知紧急联系人
    // 严重情况下可能需要通知专业机构
  }

  Future<void> _recordSafeModeExit(String userId) async {
    // TODO: 记录退出
  }

  Future<void> _resetAIBehavior(String userId) async {
    // TODO: 重置 AI 行为
  }
}

/// SafeMode 结果
class SafeModeResult {
  final bool shouldEnter;
  final SafeModeLevel? level;
  final String? message;
  final bool shouldAlertAuthorities;

  SafeModeResult({
    required this.shouldEnter,
    this.level,
    this.message,
    this.shouldAlertAuthorities = false,
  });
}

/// SafeMode 级别
enum SafeModeLevel {
  normal('normal', '正常'),
  elevated('elevated', '关注'),
  critical('critical', '紧急');

  final String value;
  final String description;

  const SafeModeLevel(this.value, this.description);
}
