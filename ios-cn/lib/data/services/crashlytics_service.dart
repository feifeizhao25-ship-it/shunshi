import 'package:flutter/foundation.dart';

/// 崩溃收集服务
/// 简化版 - 后续可集成 firebase_crashlytics
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  bool _isEnabled = true;

  /// 初始化
  Future<void> init() async {
    if (kDebugMode) {
      print('[Crashlytics] Service initialized');
    }
  }

  /// 启用/禁用
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 记录错误
  void recordError(dynamic error, [StackTrace? stackTrace]) {
    if (!_isEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final errorInfo = {
      'timestamp': timestamp,
      'error': error.toString(),
      'stackTrace': stackTrace?.toString() ?? 'No stack trace',
    };

    if (kDebugMode) {
      print('[Crashlytics] Error recorded: $errorInfo');
    }
  }

  /// 记录致命错误
  void recordFatalError(dynamic error, [StackTrace? stackTrace]) {
    if (!_isEnabled) return;
    recordError(error, stackTrace);
  }

  /// 添加自定义键
  void setCustomKey(String key, String value) {
    if (kDebugMode) {
      print('[Crashlytics] Custom key: $key = $value');
    }
  }

  /// 设置用户 ID
  void setUserId(String userId) {
    if (kDebugMode) {
      print('[Crashlytics] User ID: $userId');
    }
  }

  /// 记录日志
  void log(String message) {
    if (kDebugMode) {
      print('[Crashlytics] Log: $message');
    }
  }
}

/// 全局错误处理
class GlobalErrorHandler {
  static void init() {
    // Flutter 异步错误
    FlutterError.onError = (details) {
      CrashlyticsService().recordError(details.exception, details.stack);
    };
    
    // Dart 异步错误 - 使用 runZoned
    // Note: In production, use proper error handling
  }
}
