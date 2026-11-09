// S29：国际版（SEASONS）对外显示的应用名只能是 SEASONS，不能带国内品牌 ShunShi / 顺时。
// 覆盖 no_chinese_ui_test 扫不到的地方：MaterialApp.title（任务切换器 / 浏览器标签）、
// 本地化文案表里的品牌值，以及 Android 启动器名称。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MaterialApp title is SEASONS', () {
    final src = File('lib/main.dart').readAsStringSync();
    final m = RegExp(r"title:\s*'([^']*)'").firstMatch(src);
    expect(m, isNotNull);
    expect(m!.group(1), 'SEASONS');
  });

  test('no user-visible string literal carries the ShunShi brand', () {
    final literal = RegExp(r"'[^'\n]*\bShunShi\b[^'\n]*'");
    final hits = <String>[];
    for (final path in [
      'lib/main.dart',
      'lib/core/theme/app_localizations.dart',
      'lib/presentation/pages/profile/about_page.dart',
      'lib/presentation/pages/about/about_page.dart',
    ]) {
      final f = File(path);
      if (!f.existsSync()) continue;
      var n = 0;
      for (final line in f.readAsLinesSync()) {
        n++;
        if (line.trimLeft().startsWith('//')) continue;
        if (literal.hasMatch(line)) hits.add('$path:$n: ${line.trim()}');
      }
    }
    expect(hits, isEmpty, reason: 'International UI must say SEASONS');
  });

  test('Android launcher label is SEASONS, not 顺时', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final label = RegExp(r'android:label="([^"]*)"').firstMatch(manifest)!.group(1);
    expect(label, 'SEASONS');
  });
}
