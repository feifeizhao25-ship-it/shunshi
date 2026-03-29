import 'package:flutter/foundation.dart';

/// 监控服务 - 简化版
/// 后续可集成 Sentry、Firebase Crashlytics 等
class MonitoringService {
  static bool _isInitialized = false;

  /// 初始化
  static Future<void> init() async {
    _isInitialized = true;
    if (kDebugMode) {
      print('[Monitoring] Initialized');
    }
    // 后续可集成 Sentry:
    // await SentryFlutter.init(...);
  }

  /// 设置用户
  static void setUser(String userId, {String? email}) {
    if (kDebugMode) {
      print('[Monitoring] Set user: $userId, email: $email');
    }
    // 后续可集成:
    // Sentry.configureScope((scope) {
    //   scope.user = SentryUser(id: userId, email: email);
    // });
  }

  /// 记录日志
  static void log(String message, {String? level}) {
    if (kDebugMode) {
      print('[Monitoring][${level ?? 'info'}] $message');
    }
    // 后续可集成:
    // Sentry.captureMessage(message, level: SentryLevel.info);
  }

  /// 记录错误
  static void captureError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[Monitoring] Error: $error');
      if (stackTrace != null) print(stackTrace);
    }
    // 后续可集成:
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// 记录 Flutter 错误
  static void recordFlutterError(FlutterErrorDetails details) {
    captureError(details.exception, details.stack);
  }
}

/// 性能监控
class PerformanceMonitor {
  static final Map<String, DateTime> _marks = {};

  /// 开始计时
  static void start(String label) {
    _marks[label] = DateTime.now();
  }

  /// 结束计时
  static void end(String label) {
    final start = _marks[label];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      MonitoringService.log('$label: ${duration.inMilliseconds}ms');
      _marks.remove(label);
    }
  }
}

/// 事件追踪
class Analytics {
  /// 追踪事件
  static void track(String eventName, [Map<String, dynamic>? params]) {
    MonitoringService.log('Event: $eventName, params: $params');
    // 后续可集成 Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: params);
  }

  /// 追踪页面
  static void trackPage(String pageName) {
    track('page_view', {'page': pageName});
  }

  /// 追踪用户行为
  static void trackAction(String action, String category) {
    track('user_action', {'action': action, 'category': category});
  }
}
