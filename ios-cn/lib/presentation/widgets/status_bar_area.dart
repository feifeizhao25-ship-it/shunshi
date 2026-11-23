import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 顶部状态栏：浅色主题用深色图标、深色主题用浅色图标，并把内容挡在状态栏下面。
/// 「我的」「养生」页以前没设，白色图标压在浅底上看不见，往下滑内容还会顶进状态栏（问题 44）。
class StatusBarArea extends StatelessWidget {
  const StatusBarArea({super.key, required this.child});

  final Widget child;

  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Android 看 statusBarIconBrightness，iOS 看 statusBarBrightness，两者含义相反。
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleFor(Theme.of(context).brightness),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
