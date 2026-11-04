import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('N-03: every asset directory/file declared in pubspec.yaml exists', () {
    final lines = File('pubspec.yaml').readAsLinesSync();
    var inAssets = false;
    final missing = <String>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line == '  assets:') {
        inAssets = true;
        continue;
      }
      if (inAssets && RegExp(r'^  [A-Za-z]').hasMatch(line)) inAssets = false;
      if (!inAssets) continue;
      final m = RegExp(r'^\s+-\s+(assets/\S+)\s*$').firstMatch(line);
      if (m != null && !(FileSystemEntity.isDirectorySync(m.group(1)!) || File(m.group(1)!).existsSync())) {
        missing.add(m.group(1)!);
      }
    }
    expect(missing, isEmpty);
  });
}
