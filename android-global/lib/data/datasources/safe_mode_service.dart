import 'package:dio/dio.dart';

/// SafeMode 安全模式 - 异常情绪检测与处理（对接后端 /api/v1/mental-wellness）
class SafeModeService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 检查是否需要进入 SafeMode
  Future<SafeModeResult> checkSafeMode({
    required String userId,
    required String message,
    required Map<String, dynamic> emotionAnalysis,
  }) async {
    // 1. 检测异常情绪信号
    final hasRiskSignals = _detectRiskSignals(message);

    // 2. 检测情绪持续低落 - 调用后端
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

  /// 进入 SafeMode - POST /api/v1/mental-wellness/check-in
  Future<void> enterSafeMode({
    required String userId,
    required SafeModeLevel level,
  }) async {
    try {
      // 记录情绪打卡
      await _dio.post('/api/v1/mental-wellness/check-in', data: {
        'user_id': userId,
        'mood_score': level == SafeModeLevel.critical ? 1 : 3,
        'emotion': level.value,
        'safe_mode': true,
        'note': 'Auto safe-mode entry: ${level.value}',
      });
    } catch (_) {}

    // 如果是严重级别，通知相关人员
    if (level == SafeModeLevel.critical) {
      await _notifyEmergencyContacts(userId);
    }
  }

  /// 退出 SafeMode
  Future<void> exitSafeMode(String userId) async {
    try {
      await _dio.post('/api/v1/mental-wellness/check-in', data: {
        'user_id': userId,
        'mood_score': 5,
        'emotion': 'calm',
        'safe_mode': false,
        'note': 'Safe-mode exit',
      });
    } catch (_) {}
  }

  /// 获取危机资源 - GET /api/v1/mental-wellness/crisis-resources
  Future<List<Map<String, dynamic>>> getCrisisResources() async {
    try {
      final res = await _dio.get('/api/v1/mental-wellness/crisis-resources');
      if (res.data?['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
    } catch (_) {}
    return [
      {'name': '全国24小时心理援助热线', 'phone': '400-161-9995', 'type': 'hotline'},
      {'name': '北京心理危机研究与干预中心', 'phone': '010-82951332', 'type': 'hotline'},
      {'name': 'LifeLine International', 'type': 'resource'},
    ];
  }

  /// 获取冥想引导 - GET /api/v1/mental-wellness/meditation-guides
  Future<List<Map<String, dynamic>>> getMeditationGuides({String? emotion}) async {
    try {
      final res = await _dio.get('/api/v1/mental-wellness/meditation-guides',
        queryParameters: emotion != null ? {'emotion': emotion} : null);
      if (res.data?['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
    } catch (_) {}
    return [];
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

  // 检查持续低落 - 调用后端情绪数据
  Future<bool> _checkPersistentLowMood(String userId) async {
    try {
      final res = await _dio.get('/api/v1/mental-wellness/check-in',
        queryParameters: {'user_id': userId, 'days': 7});
      if (res.data?['success'] == true) {
        final List data = res.data['data'];
        if (data.length >= 3) {
          final lowMoodDays = data.where((d) =>
            (d['mood_score'] is int && d['mood_score'] <= 3) ||
            (d['mood_score'] is double && d['mood_score'] <= 3.0)
          ).length;
          return lowMoodDays >= 3;
        }
      }
    } catch (_) {}
    return false;
  }

  String _getCriticalMessage() {
    return '我感受到你可能正在经历非常困难的时刻。你很重要，我希望你能得到帮助。';
  }

  String _getElevatedMessage() {
    return '我在这里陪着你。如果你愿意，可以和我聊聊你的感受。';
  }

  Future<void> _notifyEmergencyContacts(String userId) async {
    try {
      await _dio.post('/api/v1/notifications/send', data: {
        'user_id': userId,
        'type': 'emergency',
        'message': '用户触发安全模式，请关注',
      });
    } catch (_) {}
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
