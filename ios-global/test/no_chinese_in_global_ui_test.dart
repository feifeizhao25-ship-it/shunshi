import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The international edition is English-only. Code in lib/ must not carry Chinese string
/// literals; the only exceptions are the generated solar-term table and its English map,
/// whose Chinese strings are data keys that are never displayed.
void main() {
  test('lib/ has no Chinese string literals outside the solar-term key tables', () {
    const allowed = {
      'lib/core/solar_term/solar_term_table.dart',
      'lib/core/solar_term/solar_term_en.dart',
    };
    final cjk = RegExp(r'[\u3400-\u9fff]');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || allowed.contains(path)) continue;
      var n = 0;
      for (final line in f.readAsLinesSync()) {
        final code = line.replaceFirst(RegExp(r'(?<!:)//.*$'), '');
        if (cjk.hasMatch(code)) n++;
      }
      if (n > 0) offenders.add('$path ($n lines)');
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
