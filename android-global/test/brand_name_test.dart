// S29 plus the later about scrub: the international name is SEASONS,
// and the about screens do not pitch a constitution quiz.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/theme/app_localizations.dart';
import 'package:seasons/presentation/pages/about/about_page.dart';
import 'package:seasons/presentation/pages/profile/about_page.dart' as profile_about;

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

  testWidgets('about screens are SEASONS and do not pitch a constitution quiz', (tester) async {
    Future<void> check(Widget page) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en')],
        home: page,
      ));
      await tester.pumpAndSettle();
      final text = tester.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join('\n');
      expect(text.contains('ShunShi'), isFalse, reason: text);
      expect(text.contains('顺时'), isFalse);
      expect(text.toLowerCase().contains('body type'), isFalse, reason: text);
      expect(text.toLowerCase().contains('constitution'), isFalse, reason: text);
      expect(text.contains('SEASONS'), isTrue);
    }

    await check(const AboutPage());
    await check(const profile_about.AboutPage());
  });
}
