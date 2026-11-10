/// 国内版用来显示时辰的钟。
///
/// 正式包用设备时间。只有编译时打开 `SHUNSHI_TEST_CLOCK` 的测试包，
/// 才从页面地址的 `test_now` 读取上海墙钟。这个开关不是运行时配置，
/// 商店包不能被任意用户改时钟。
DateTime domesticNow() {
  const enabled = bool.fromEnvironment('SHUNSHI_TEST_CLOCK');
  if (!enabled) return DateTime.now();
  final raw = Uri.base.queryParameters['test_now'];
  if (raw == null || raw.isEmpty) return DateTime.now();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return DateTime.now();
  final shanghai = parsed.toUtc().add(const Duration(hours: 8));
  return DateTime(
    shanghai.year,
    shanghai.month,
    shanghai.day,
    shanghai.hour,
    shanghai.minute,
    shanghai.second,
  );
}
