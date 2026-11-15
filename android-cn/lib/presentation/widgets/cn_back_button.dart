import 'package:flutter/material.dart';

/// 页面里手写的返回键。
///
/// AppBar 自动生成的返回按钮会读 [MaterialLocalizations.backButtonTooltip]。
/// 自定义 leading 不会，读屏和 axe 会把它当成没有名字的按钮。
/// 这个控件始终带上中文 tooltip。
class CnBackButton extends StatelessWidget {
  const CnBackButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.padding,
    this.constraints,
    this.tooltip = '返回',
  }) : assert(tooltip != '', '返回按钮需要可读的 tooltip');

  final VoidCallback? onPressed;
  final Widget icon;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      padding: padding,
      constraints: constraints,
    );
  }
}
