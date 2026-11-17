import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `API_BASE_URL` 既可能是 `https://host`，也可能是 `https://host/api/v1`。
/// 直接拿 `AppConfig.apiBaseUrl` 去拼 `/api/v1/...` 会在第二种写法下变成
/// `/api/v1/api/v1/...`（2026-11-15 复测：退出登录 404）。
/// lib 里每一处使用都必须先归一化。
void main() {
  test('every AppConfig.apiBaseUrl use in lib/ is normalized first', () {
    const allowed = <String>[
      'normalizeApiBaseUrl(',
      'resolveVersionedApiUrl(',
      "replaceAll('/api/v1', '')",
      'replaceFirst(RegExp(',
      '_root(',
      '= AppConfig.apiBaseUrl]', // 可选参数默认值，函数体内归一化（logoutClient）
      'String baseUrl = AppConfig.apiBaseUrl,', // 命名参数默认值，构造函数初始化列表里归一化（SubscriptionService）
    ];
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('core/config/app_config.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('AppConfig.apiBaseUrl')) continue;
        if (line.trimLeft().startsWith('//')) continue;
        if (allowed.any(line.contains)) continue;
        // 调用被格式化成多行时，归一化函数名在上一行：resolveVersionedApiUrl(\n AppConfig.apiBaseUrl,
        final prev = i > 0 ? lines[i - 1] : '';
        if (allowed.any(prev.contains)) continue;
        offenders.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
