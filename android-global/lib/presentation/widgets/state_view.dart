/// 全局错误处理 + 加载态组件
library;

import 'package:flutter/material.dart';
import '../../design_system/theme.dart';

/// 通用错误页面
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ShunShiColors.textTertiary),
            const SizedBox(height: 16),
            Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: ShunShiColors.primary),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 通用加载骨架屏
class LoadingSkeleton extends StatelessWidget {
  final int itemCount;
  const LoadingSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        itemBuilder: (_, __) => _buildItem(),
      ),
    );
  }

  Widget _buildItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        Container(height: 16, width: 200, decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Container(height: 12, width: 140, decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(4))),
      ]),
    );
  }
}

/// 简易 Shimmer 动画
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slide = _controller.value * 2 - 1;
            return LinearGradient(
              colors: [
                const Color(0xFFE8E8E8),
                const Color(0xFFF5F5F5),
                const Color(0xFFE8E8E8),
              ],
              stops: [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// 状态封装 widget：loading / error / data
class StateView<T> extends StatelessWidget {
  final bool loading;
  final String? error;
  final T? data;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;

  const StateView({
    super.key,
    required this.loading,
    this.error,
    this.data,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return ErrorView(message: error!, onRetry: onRetry);
    }
    if (data == null) {
      return const ErrorView(message: 'No data');
    }
    return builder(data as T);
  }
}
