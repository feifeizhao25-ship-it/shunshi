import 'dart:developer' as dev;

/// 统一日志工具
class Logger {
  Logger._();

  static void debug(String message, {String? tag}) {
    dev.log('🔍 $message', name: tag ?? 'ShunShi');
  }

  static void info(String message, {String? tag}) {
    dev.log('ℹ️ $message', name: tag ?? 'ShunShi');
  }

  static void warning(String message, {String? tag, Object? error}) {
    dev.log('⚠️ $message', name: tag ?? 'ShunShi', error: error);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    dev.log('❌ $message', name: tag ?? 'ShunShi', error: error, stackTrace: stackTrace);
  }

  /// 记录 AI 调用日志（含审计字段）
  static void aiCall({
    required String requestType,
    required String model,
    required Map<String, String> promptVersions,
    required int totalTokens,
    required int latencyMs,
    required String safetyFlag,
    required String userTier,
    required bool schemaValid,
    bool fallbackUsed = false,
  }) {
    final log = {
      'request_type': requestType,
      'model': model,
      'prompt_version': promptVersions,
      'tokens': totalTokens,
      'latency_ms': latencyMs,
      'safety_flag': safetyFlag,
      'user_tier': userTier,
      'schema_valid': schemaValid,
      'fallback_used': fallbackUsed,
    };
    dev.log('📊 AI_CALL: $log', name: 'AIAudit');
  }
}
