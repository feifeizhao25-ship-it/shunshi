import 'package:flutter/material.dart';

import '../pages/error/error_page.dart';

/// Widget-tree error boundary for SEASONS global app
///
/// Usage:
/// ```dart
/// AppErrorBoundary(child: MyWidget())
/// ```
///
/// Register global handlers in main():
/// ```dart
/// FlutterError.onError = AppErrorBoundary.onFlutterError;
/// ```
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? fallbackBuilder;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  static void onFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Production: forward to Sentry / Firebase Crashlytics here
  }

  static bool onPlatformError(Object error, StackTrace stack) {
    debugPrint('[AppErrorBoundary] Uncaught error: $error');
    debugPrint(stack.toString());
    return true;
  }

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackBuilder?.call(_error!, _stack) ??
          ErrorPage(error: _error is Exception ? _error as Exception : null);
    }
    return _ErrorCatcher(
      onError: (error, stack) {
        setState(() {
          _error = error;
          _stack = stack;
        });
      },
      child: widget.child,
    );
  }

  void reset() => setState(() {
        _error = null;
        _stack = null;
      });
}

class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stack) onError;

  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(details.exception, details.stack ?? StackTrace.empty);
      });
      return const SizedBox.shrink();
    };
    return child;
  }
}
