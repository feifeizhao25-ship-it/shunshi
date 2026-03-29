import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_animations.dart';

/// Loading State — Seasons version
/// 3-dot breathing animation, not CircularProgressIndicator
class LoadingState extends StatefulWidget {
  final double size;
  final bool inline;
  final String? message;

  const LoadingState({
    super.key,
    this.size = 32.0,
    this.inline = false,
    this.message,
  });

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: SeasonsAnimations.breathing,
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
        ? SeasonsDarkColors.primary
        : SeasonsColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(context);
    return widget.inline
        ? _buildInline(dotColor)
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInline(dotColor),
                if (widget.message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _isDark(context)
                          ? SeasonsDarkColors.textSecondary
                          : SeasonsColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
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
