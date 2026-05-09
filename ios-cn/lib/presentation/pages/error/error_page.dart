import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';
import '../../widgets/components/gentle_button.dart';

/// 全局错误页面 — 路由不存在 / 意外异常
///
/// 使用方式：
///   - go_router `errorBuilder` → `ErrorPage(error: state.error)`
///   - `AppErrorBoundary` 捕获 Widget 树异常时跳转此页
class ErrorPage extends StatelessWidget {
  final Object? error;
  final String? customMessage;

  const ErrorPage({
    super.key,
    this.error,
    this.customMessage,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _resolveMessage() {
    if (customMessage != null && customMessage!.isNotEmpty) {
      return customMessage!;
    }
    if (error is Exception || error is Error) {
      final msg = error.toString();
      if (msg.contains('404') || msg.toLowerCase().contains('not found')) {
        return '找不到这个页面';
      }
      if (msg.contains('network') || msg.contains('socket')) {
        return '网络连接不稳定，请稍后重试';
      }
    }
    return '页面遇到了一点小问题';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final bg = isDark ? ShunshiDarkColors.background : ShunshiColors.background;
    final textPrimary =
        isDark ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;
    final textSecondary =
        isDark ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;
    final errorColor = isDark ? ShunshiDarkColors.error : ShunshiColors.error;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 插图：温和的错误图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.spa_outlined,
                  size: 48,
                  color: errorColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: ShunshiSpacing.xl),

              // 标题
              Text(
                '稍作停顿',
                style: ShunshiTextStyles.heading.copyWith(color: textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ShunshiSpacing.md),

              // 说明
              Text(
                _resolveMessage(),
                style: ShunshiTextStyles.body.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ShunshiSpacing.sm),

              Text(
                '就像季节一样，每个问题都会过去。',
                style: ShunshiTextStyles.caption.copyWith(
                  color: textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: ShunshiSpacing.xxl),

              // 操作按钮
              SizedBox(
                width: double.infinity,
                child: GentleButton(
                  text: '返回主页',
                  isPrimary: true,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              const SizedBox(height: ShunshiSpacing.md),
              SizedBox(
                width: double.infinity,
                child: GentleButton(
                  text: '刷新页面',
                  isPrimary: false,
                  onPressed: () => context.go(
                    GoRouterState.of(context).uri.toString(),
                  ),
                ),
              ),

              // Debug 信息（仅在 debug 模式）
              if (error != null) ...[
                const SizedBox(height: ShunshiSpacing.xxl),
                _DebugErrorCard(error: error!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug 错误详情卡（release 模式自动隐藏）
class _DebugErrorCard extends StatefulWidget {
  final Object error;
  const _DebugErrorCard({required this.error});

  @override
  State<_DebugErrorCard> createState() => _DebugErrorCardState();
}

class _DebugErrorCardState extends State<_DebugErrorCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Only show in debug builds
    const isDebug = !bool.fromEnvironment('dart.vm.product');
    if (!isDebug) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ShunshiSpacing.md),
        decoration: BoxDecoration(
          color: (isDark ? ShunshiDarkColors.surfaceDim : ShunshiColors.surfaceDim),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark ? ShunshiDarkColors.border : ShunshiColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  size: 14,
                  color: isDark
                      ? ShunshiDarkColors.textHint
                      : ShunshiColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Debug 信息 (点击${_expanded ? '收起' : '展开'})',
                  style: ShunshiTextStyles.caption.copyWith(
                    color:
                        isDark ? ShunshiDarkColors.textHint : ShunshiColors.textHint,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: ShunshiSpacing.sm),
              SelectableText(
                widget.error.toString(),
                style: ShunshiTextStyles.caption.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: isDark
                      ? ShunshiDarkColors.textSecondary
                      : ShunshiColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
