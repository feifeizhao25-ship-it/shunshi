// 2026-11-21 测试：正文字体名写成 'NotoSansSC'，pubspec 里打包的是 'NotoSansCJK'，
// 正文全部落到默认字体；两个组件还写了不存在的 'sans' / 'serif'。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/design_system/theme.dart';

Set<String> _declaredFamilies() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  return RegExp(r'^\s*-\s*family:\s*(\S+)\s*$', multiLine: true)
      .allMatches(pubspec)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  test('the typography families are the ones bundled in pubspec.yaml', () {
    final declared = _declaredFamilies();
    expect(declared, contains(ShunShiTypography.serifFamily));
    expect(declared, contains(ShunShiTypography.sansFamily));
    for (final f in ShunShiTypography.fontFallback) {
      expect(declared, contains(f), reason: 'fallback $f is not bundled');
    }
  });

  test('no widget names a font family that is not bundled', () {
    final declared = _declaredFamilies();
    final bad = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final src = file.readAsStringSync();
      for (final m in RegExp(r'''fontFamily:\s*['"]([^'"]+)['"]''').allMatches(src)) {
        if (!declared.contains(m.group(1))) bad.add('${file.path}: ${m.group(1)}');
      }
    }
    expect(bad, isEmpty);
  });

  test('text styles and both themes carry the bundled fallback list', () {
    expect(ShunShiTypography.bodyMedium.fontFamily, 'NotoSansCJK');
    expect(ShunShiTypography.bodyMedium.fontFamilyFallback, ShunShiTypography.fontFallback);
    expect(ShunShiTypography.displayLarge.fontFamilyFallback, ShunShiTypography.fontFallback);
    expect(ShunShiTheme.lightTheme.textTheme.bodyMedium?.fontFamilyFallback, ShunShiTypography.fontFallback);
    expect(ShunShiTheme.darkTheme.textTheme.bodyMedium?.fontFamilyFallback, ShunShiTypography.fontFallback);
  });
}
