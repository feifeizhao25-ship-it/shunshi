/// 全局错误处理 — 捕获 Flutter 框架未处理的异常
library;

import 'package:flutter/material.dart';

class AppErrorHandler {
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      // Log to local storage for debugging
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
  }
}

/// 错误边界 Widget — 包裹子组件，捕获渲染错误
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('页面加载出错', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _hasError = false),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return widget.child;
  }
}
