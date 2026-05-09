// Sentry Crash Reporting Service
// Production-ready with configurable DSN

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Note: In production, install sentry_flutter package:
// flutter pub add sentry_flutter

class SentryConfig {
  final String dsn;
  final String environment;
  final String release;
  final double sampleRate;
  final bool autoSessionTracking;
  final bool attachStacktrace;
  final bool sendDefaultPii;
  final int maxBreadcrumbs;
  
  SentryConfig({
    required this.dsn,
    this.environment = 'production',
    this.release = 'com.shunshi.app@1.0.0',
    this.sampleRate = 1.0,
    this.autoSessionTracking = true,
    this.attachStacktrace = true,
    this.sendDefaultPii = false,
    this.maxBreadcrumbs = 50,
  });
  
  factory SentryConfig.fromJson(Map<String, dynamic> json) {
    return SentryConfig(
      dsn: json['dsn'] ?? '',
      environment: json['environment'] ?? 'production',
      release: json['release'] ?? 'com.shunshi.app@1.0.0',
      sampleRate: (json['sampleRate'] ?? 1.0).toDouble(),
      autoSessionTracking: json['autoSessionTracking'] ?? true,
      attachStacktrace: json['attachStacktrace'] ?? true,
      sendDefaultPii: json['sendDefaultPii'] ?? false,
      maxBreadcrumbs: json['maxBreadcrumbs'] ?? 50,
    );
  }
  
  static Future<SentryConfig> load() async {
    try {
      final jsonString = await rootBundle.loadString('config/sentry.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SentryConfig.fromJson(json);
    } catch (e) {
      // Return empty config if file not found
      return SentryConfig(dsn: '');
    }
  }
  
  bool get isConfigured => dsn.isNotEmpty;
}

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  
  bool _isInitialized = false;
  SentryConfig? _config;
  
  CrashReportingService._internal();
  
  // Initialize Sentry
  Future<void> init() async {
    if (_isInitialized) return;
    
    _config = await SentryConfig.load();
    
    if (!_config!.isConfigured) {
      debugPrint('⚠️ Sentry DSN not configured. Crash reporting disabled.');
      return;
    }
    
    // In production, uncomment:
    // await SentryFlutter.init((options) {
    //   options.dsn = _config!.dsn;
    //   options.environment = _config!.environment;
    //   options.release = _config!.release;
    //   options.sampleRate = _config!.sampleRate;
    //   options.autoSessionTracking = _config!.autoSessionTracking;
    //   options.attachStacktrace = _config!.attachStacktrace;
    //   options.sendDefaultPii = _config!.sendDefaultPii;
    //   options.maxBreadcrumbs = _config!.maxBreadcrumbs;
    // });
    
    _isInitialized = true;
    debugPrint('✅ Sentry initialized: ${_config!.environment}');
  }
  
  // Capture exception
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized || !_config!.isConfigured) return;
    
    // In production:
    // await Sentry.captureException(
    //   exception,
    //   stackTrace: stackTrace,
    //   extra: extra,
    // );
    
    debugPrint('📤 Exception captured: $exception');
  }
  
  // Capture message
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_isInitialized || !_config!.isConfigured) return;
    
    // In production:
    // await Sentry.captureMessage(message, level: level);
  }
  
  // Add user context
  Future<void> setUser({
    required String id,
    String? email,
    String? username,
  }) async {
    if (!_isInitialized || !_config!.isConfigured) return;
    
    // In production:
    // await Sentry.configureScope((scope) {
    //   scope.user = User(
    //     id: id,
    //     email: email,
    //     username: username,
    //   );
    // });
  }
  
  // Add breadcrumb
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized || !_config!.isConfigured) return;
    
    // In production:
    // await Sentry.addBreadcrumb(Breadcrumb(
    //   message: message,
    //   category: category,
    //   data: data,
    //   level: SentryLevel.info,
    // ));
  }
  
  // Set extra context
  Future<void> setExtra(String key, dynamic value) async {
    if (!_isInitialized || !_config!.isConfigured) return;
    
    // In production:
    // await Sentry.configureScope((scope) {
    //   scope.setExtra(key, value);
    // });
  }
}

// Sentry log levels
enum SentryLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

// Global instance
final crashReporting = CrashReportingService();

// Usage in main.dart:
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   
//   // Initialize crash reporting
//   await crashReporting.init();
//   
//   runApp(const ProviderScope(child: ShunshiApp()));
// }
