import 'package:flutter/material.dart';

import '../pages/error/error_page.dart';

/// Flutter Widget 树错误边界
///
/// 使用方式：
/// ```dart
/// AppErrorBoundary(
///   child: MyWidget(),
/// )
/// ```
///
/// 在 main.dart 中注册全局 Flutter 错误处理：
/// ```dart
/// FlutterError.onError = AppErrorBoundary.onFlutterError;
/// PlatformDispatcher.instance.onError = AppErrorBoundary.onPlatformError;
/// ```
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? fallbackBuilder;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  /// 注册到 FlutterError.onError — 捕获 Widget 构建期异常
  static void onFlutterError(FlutterErrorDetails details) {
    // 在 debug 模式下，仍然打印到控制台
    FlutterError.presentError(details);
    // 生产环境可在此上报到 Sentry / Firebase Crashlytics
  }

  /// 注册到 PlatformDispatcher.instance.onError — 捕获异步 Dart 异常
  static bool onPlatformError(Object error, StackTrace stack) {
    debugPrint('[AppErrorBoundary] Uncaught platform error: $error');
    debugPrint(stack.toString());
    // 返回 true 表示异常已处理，不再向上抛出
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
          ErrorPage(error: _error);
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

  /// 重置错误状态，可被外部调用以"重试"
  void reset() => setState(() {
        _error = null;
        _stack = null;
      });
}

/// 内部 Widget：捕获子树中的 build 阶段异常
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stack) onError;

  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // 将错误传递给边界
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(details.exception, details.stack ?? StackTrace.empty);
      });
      // 渲染一个空容器，避免红色死亡屏幕
      return const SizedBox.shrink();
    };
    return child;
  }
}
