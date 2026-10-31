import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every in-app link must land on a real page. The UI test found seven routes that showed
/// "Page not found" (/seasons /wellness-report /meditation /mood /tea /growth /journal).
void main() {
  final routerSource = File('lib/core/router/app_router.dart').readAsStringSync();
  final routed = RegExp(r"GoRoute\(\s*path:\s*'([^']+)'")
      .allMatches(routerSource)
      .map((m) => m.group(1)!)
      .toList();

  bool isRouted(String link) {
    final path = link.split('?').first;
    for (final pattern in routed) {
      final regex = RegExp('^${pattern.replaceAllMapped(RegExp(r':[A-Za-z]+'), (_) => '[^/]+')}\$');
      if (regex.hasMatch(path)) return true;
    }
    return false;
  }

  test('the seven previously missing routes exist', () {
    for (final path in ['/seasons', '/wellness-report', '/meditation', '/mood', '/tea', '/growth', '/journal']) {
      expect(isRouted(path), isTrue, reason: '$path must be routed');
    }
  });

  test('/membership no longer serves the old static CNY page', () {
    expect(routerSource.contains('MembershipCenterPage'), isFalse);
    expect(routerSource, contains("path: '/membership', redirect"));
  });

  test('every literal context.push/go target in lib/ is routed', () {
    final link = RegExp(r'''context\.(?:push|go|pushReplacement|pushNamed)\(\s*['"](/[A-Za-z0-9_\-/]*)['"]''');
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in link.allMatches(f.readAsStringSync())) {
        final target = m.group(1)!;
        if (!isRouted(target)) missing.add('$target (${f.path})');
      }
    }
    expect(missing, isEmpty, reason: 'links with no route: $missing');
  });
}
