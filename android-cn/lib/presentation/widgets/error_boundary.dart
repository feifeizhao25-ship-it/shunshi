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

/// 构建失败时的平静卡片，代替红色错误屏。不依赖 Theme，避免卡片自己再抛错。
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
              '这一块暂时显示不出来。请返回后再试一次。',
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
