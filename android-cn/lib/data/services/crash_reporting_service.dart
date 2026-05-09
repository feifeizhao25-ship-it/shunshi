// Sentry Crash Reporting Service
// Integrated with existing architecture

import 'package:flutter/material.dart';

// Note: In production, install sentry_flutter package:
// sentry_flutter: ^8.0.0

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  
  bool _isInitialized = false;
  
  CrashReportingService._internal();
  
  // Initialize Sentry
  // Call this in main() before runApp()
  Future<void> init({
    required String dsn,
    String environment = 'production',
    double sampleRate = 1.0,
  }) async {
    if (_isInitialized) return;
    
    // In production, use:
    // await SentryFlutter.init((options) {
    //   options.dsn = dsn;
    //   options.environment = environment;
    //   options.sampleRate = sampleRate;
    //   options.attachStacktrace = true;
    //   options.sendDefaultPii = false;
    //   options.maxBreadcrumbs = 50;
    // });
    
    _isInitialized = true;
    print('✅ Crash reporting initialized (DSN: $dsn)');
  }
  
  // Capture exception
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Crash reporting not initialized');
      return;
    }
    
    // In production:
    // await Sentry.captureException(
    //   exception,
    //   stackTrace: stackTrace,
    //   extra: extra,
    // );
    
    print('📤 Exception captured: $exception');
  }
  
  // Capture message
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_isInitialized) return;
    
    // In production:
    // await Sentry.captureMessage(message, level: level);
  }
  
  // Add user context
  Future<void> setUser({
    required String id,
    String? email,
    String? username,
  }) async {
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

// Error widget for graceful error handling
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      fallback: fallback,
      child: child,
    );
  }
}

class ErrorWidget extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  
  const ErrorWidget({
    super.key,
    required this.child,
    this.fallback,
  });
  
  @override
  State<ErrorWidget> createState() => _ErrorWidgetState();
}

class _ErrorWidgetState extends State<ErrorWidget> {
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }
  
  void _setupErrorHandling() {
    // Set up Flutter error handling
    FlutterError.onError = (details) {
      _handleError(details.exception, details.stack);
    };
  }
  
  void _handleError(dynamic error, StackTrace? stackTrace) {
    // Capture to crash reporting
    crashReporting.captureException(
      error,
      stackTrace: stackTrace,
      extra: {'widget': widget.child.toString()},
    );
    
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _DefaultErrorWidget(
        message: _errorMessage,
        onRetry: () {
          setState(() => _hasError = false);
        },
      );
    }
    
    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  
  const _DefaultErrorWidget({this.message, this.onRetry});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '出现了一些问题',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
