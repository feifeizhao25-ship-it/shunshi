import '../../../core/solar_term/solar_term_table.dart';

/// 首页节气芯片和今日推荐用的日期。
///
/// 有注入的测试时钟时用那一天，否则用北京时间。卡片接口用同一个
/// `X-Shunshi-Test-Now`，所以芯片不要另取一台墙上的钟。
DateTime homeClockDay({DateTime? deviceNow, String? injectedTestNow}) {
  final raw = injectedTestNow?.trim() ?? '';
  if (raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final shanghai = parsed.toUtc().add(const Duration(hours: 8));
      return DateTime(shanghai.year, shanghai.month, shanghai.day);
    }
  }
  final now = deviceNow ?? beijingNow();
  return DateTime(now.year, now.month, now.day);
}

/// 正式包忽略地址栏。只有打开 `SHUNSHI_TEST_CLOCK` 的测试包才读 `test_now`。
DateTime homeClockDayFromApp() {
  const enabled = bool.fromEnvironment('SHUNSHI_TEST_CLOCK');
  final raw = enabled ? Uri.base.queryParameters['test_now'] : null;
  return homeClockDay(injectedTestNow: raw);
}
