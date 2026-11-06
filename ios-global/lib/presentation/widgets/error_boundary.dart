/// 全局错误处理 — 捕获 Flutter 框架未处理的异常
library;

import 'package:flutter/material.dart';

class AppErrorHandler {
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    ErrorWidget.builder = (details) => const CalmErrorCard();
  }
}

/// Calm card shown instead of the red error screen when a widget fails to build.
class CalmErrorCard extends StatelessWidget {
  const CalmErrorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        key: Key('calm-error-card'),
        color: Color(0xFFF6F1E8),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This part could not be shown. Go back, then try again.',
              key: Key('calm-error-message'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF3E3428), fontSize: 16, height: 1.5),
            ),
          ),
        ),
      ),
    );
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
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('The page failed to load', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _hasError = false),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return widget.child;
  }
}
