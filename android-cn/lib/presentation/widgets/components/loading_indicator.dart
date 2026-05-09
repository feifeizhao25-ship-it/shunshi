import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_animations.dart';

/// 加载指示器 — 呼吸圆点，不是spinner
class LoadingIndicator extends StatefulWidget {
  final double size;
  final bool inline;

  const LoadingIndicator({
    super.key,
    this.size = 32.0,
    this.inline = false,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ShunshiAnimations.breathing,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _dotColor(BuildContext context) {
    return _isDark(context)
        ? ShunshiDarkColors.primary
        : ShunshiColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(context);
    final built = _buildInline(dotColor);
    return widget.inline ? built : Center(child: built);
  }

  Widget _buildInline(Color dotColor) {
    final dotSize = widget.size / 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: dotSize * 0.5),
          child: _AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase = (_controller.value + index * 0.33) % 1.0;
              final scale = _easeOutCubic(phase) * 0.5 + 0.5;

              return Container(
                width: dotSize * 2,
                height: dotSize * 2,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: scale),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  double _easeOutCubic(double t) {
    return 1 - (1 - t) * (1 - t) * (1 - t);
  }
}

class _AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _AnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
