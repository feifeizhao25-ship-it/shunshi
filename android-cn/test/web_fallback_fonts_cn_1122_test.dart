import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// 2026-11-22 顺时国内网页版实测：节气 emoji 显示成方框，控制台 Roboto/emoji 回退字体 404。 flutter_bootstrap.js points
/// fontFallbackBaseUrl at assets/fallback_fonts/, which is not shipped, so the engine's
/// Roboto download 404'd. The engine skips that download when the font manifest has Roboto.
void main() {
  test('pubspec bundles a Roboto family whose files exist', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('    - family: Roboto\n'));
    for (final w in ['Light', 'Regular', 'Medium', 'Bold']) {
      final path = 'assets/fonts/Roboto-$w.ttf';
      expect(pubspec, contains('- asset: $path'));
      expect(File(path).lengthSync(), greaterThan(100000), reason: path);
    }
    expect(File('assets/fonts/LICENSE-Roboto.txt').readAsStringSync(), contains('Apache License'));
  });

  test('bootstrap still serves fallbacks from this site, not a CDN', () {
    final js = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(js, contains('fontFallbackBaseUrl: "assets/fallback_fonts/"'));
    expect(RegExp(r'BaseUrl:\s*"https?:').hasMatch(js), isFalse);
  });

  test('every Noto Color Emoji shard the engine asks for is shipped under web/assets/fallback_fonts', () {
    // The test runner lives under <flutter>/bin/cache/...; walk up to find the engine's fallback table.
    File data = File('');
    for (var dir = File(Platform.resolvedExecutable).parent; dir.parent.path != dir.path; dir = dir.parent) {
      final f = File('${dir.path}/flutter_web_sdk/lib/_engine/engine/font_fallback_data.dart');
      if (f.existsSync()) { data = f; break; }
    }
    final expected = data.existsSync()
        ? RegExp(r'notocoloremoji/v\d+/[A-Za-z0-9_.-]+\.woff2').allMatches(data.readAsStringSync()).map((m) => m.group(0)!).toSet()
        : <String>{};
    final shipped = Directory('web/assets/fallback_fonts/notocoloremoji')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.woff2'))
        .map((f) => f.path.substring(f.path.indexOf('notocoloremoji/')))
        .toSet();
    expect(shipped.length, 12);
    // ignore: avoid_print
    print('engine fallback table: ${data.path} (${expected.length} emoji shards)');
    if (expected.isNotEmpty) expect(shipped, equals(expected), reason: 'Flutter upgrade changed emoji fallback files');
    expect(File('web/assets/fallback_fonts/notocoloremoji/LICENSE-OFL.txt').readAsStringSync(), contains('Open Font License'));
  });
}
