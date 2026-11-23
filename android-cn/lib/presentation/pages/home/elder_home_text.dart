import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 长辈模式开关的当前值。首页以外（底部导航）也要跟着放大（问题 10）。
/// 第一次读取时从本地设置载入；设置页切换开关时直接改这里，不用重启。
class ElderModeState {
  ElderModeState._();

  static final ValueNotifier<bool> _enabled = ValueNotifier<bool>(false);
  static bool _loaded = false;

  /// 长辈模式下底部导航文字字号（平时 10）。
  static const double navLabelSize = 13;

  static ValueNotifier<bool> get enabled {
    if (!_loaded) {
      _loaded = true;
      _load();
    }
    return _enabled;
  }

  static void set(bool value) {
    _loaded = true;
    _enabled.value = value;
  }

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled.value = prefs.getBool('elder_mode') ?? false;
    } catch (_) {
      // 读不到设置就按普通模式显示。
    }
  }
}
