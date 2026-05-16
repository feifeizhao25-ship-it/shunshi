// lib/data/datasources/safe_mode_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';

/// SafeMode 安全模式 - 异常情绪检测与处理
class SafeModeService {
  static final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''),
    connectTimeout: const Duration(seconds: 8),
  ));

  /// 检查是否需要进入 SafeMode
  Future<SafeModeResult> checkSafeMode({
    required String userId,
    required String message,
    required Map<String, dynamic> emotionAnalysis,
  }) async {
    // 1. Local risk detection (fast, no API needed)
    final hasRiskSignals = _detectRiskSignals(message);
    final hasSelfHarmSignals = _detectSelfHarmSignals(message);

    if (hasSelfHarmSignals) {
      // 2. Call backend for LLM secondary verification
      try {
        final res = await _dio.post('/api/v1/safety/check', data: {
          'user_id': userId,
          'message': message,
        });
        final d = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
        final riskLevel = d['risk_level']?.toString() ?? 'critical';
        if (riskLevel == 'crisis' || riskLevel == 'critical') {
          return SafeModeResult(
            shouldEnter: true,
            level: SafeModeLevel.critical,
            message: _getCriticalMessage(),
            shouldAlertAuthorities: true,
          );
        }
      } catch (_) {
        // If API fails, trust local detection
        return SafeModeResult(
          shouldEnter: true,
          level: SafeModeLevel.critical,
          message: _getCriticalMessage(),
          shouldAlertAuthorities: true,
        );
      }
    }

    // 3. Check persistent low mood
    final hasPersistentLowMood = await _checkPersistentLowMood(userId);

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('safe_mode_level', level.value);
    await prefs.setString('safe_mode_entered', DateTime.now().toIso8601String());

    try {
      await _dio.post('/api/v1/safety/enter-safe-mode', data: {
        'user_id': userId,
        'level': level.value,
      });
    } catch (_) {}

    if (level == SafeModeLevel.critical) {
      try {
        await _dio.post('/api/v1/safety/alert-contacts', data: {'user_id': userId});
      } catch (_) {}
    }
  }

  /// 退出 SafeMode
  Future<void> exitSafeMode(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('safe_mode_level');
    await prefs.remove('safe_mode_entered');

    try {
      await _dio.post('/api/v1/safety/exit-safe-mode', data: {'user_id': userId});
    } catch (_) {}
  }

  /// Get current safe mode status
  Future<SafeModeLevel> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString('safe_mode_level');
    if (level == 'critical') return SafeModeLevel.critical;
    if (level == 'elevated') return SafeModeLevel.elevated;
    return SafeModeLevel.normal;
  }

  // Risk signal detection
  bool _detectRiskSignals(String message) {
    const riskKeywords = [
      '难过', '绝望', '崩溃', '坚持不了',
      '好累', '不想活了', '没意思',
      '失眠', '焦虑', '害怕',
    ];
    return riskKeywords.any((k) => message.contains(k));
  }

  bool _detectSelfHarmSignals(String message) {
    const dangerKeywords = [
      '自杀', '轻生', '自残', '结束生命',
      '不想活了', '死了就好', '跳楼', '割腕',
    ];
    return dangerKeywords.any((k) => message.contains(k));
  }

  Future<bool> _checkPersistentLowMood(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mood_history_$userId');
    if (raw == null) return false;
    // Check if last 3 entries are all negative
    try {
      final entries = raw.split(',');
      if (entries.length >= 3) {
        final last3 = entries.sublist(entries.length - 3);
        return last3.every((e) => int.tryParse(e) != null && int.parse(e) <= 2);
      }
    } catch (_) {}
    return false;
  }

  /// Record mood entry for tracking
  Future<void> recordMood(String userId, int moodScore) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mood_history_$userId') ?? '';
    final updated = raw.isEmpty ? '$moodScore' : '$raw,$moodScore';
    // Keep last 30 entries
    final parts = updated.split(',');
    if (parts.length > 30) {
      await prefs.setString('mood_history_$userId', parts.sublist(parts.length - 30).join(','));
    } else {
      await prefs.setString('mood_history_$userId', updated);
    }
  }

  String _getCriticalMessage() =>
    '我感受到你可能正在经历非常困难的时刻。你很重要，我希望你能得到帮助。\n\n24小时心理援助热线：400-161-9995';

  String _getElevatedMessage() =>
    '我在这里陪着你。如果你愿意，可以和我聊聊你的感受。';
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
