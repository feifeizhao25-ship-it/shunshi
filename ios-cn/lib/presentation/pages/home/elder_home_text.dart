import 'package:flutter/widgets.dart';

/// 老年人 / 大字模式：把首页文字放大。设置页的预览不再是唯一会变大的地方。
class ElderHomeScope extends StatelessWidget {
  const ElderHomeScope({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static TextScaler scaler(TextScaler base, {required bool enabled}) {
    if (!enabled) return base;
    final next = base.scale(1) * 1.25;
    return TextScaler.linear(next < 1.25 ? 1.25 : next);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      key: const Key('home-elder-scope'),
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler(MediaQuery.textScalerOf(context), enabled: enabled),
      ),
      child: child,
    );
  }
}
