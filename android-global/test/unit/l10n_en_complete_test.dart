import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/theme/app_localizations.dart';

// The English UI must never show raw keys such as login_google_1.
void main() {
  test('every key used with .t() resolves to English text', () {
    final l = AppLocalizations(const Locale('en'));
    final re = RegExp(r"\.t\('([a-z0-9_]+)'");
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in re.allMatches(f.readAsStringSync())) {
        final k = m.group(1)!;
        if (l.t(k) == k) missing.add(k);
      }
    }
    expect(missing, isEmpty, reason: missing.join(', '));
  });
}
