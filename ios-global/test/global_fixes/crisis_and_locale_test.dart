import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/network/locale_headers.dart';
import 'package:seasons/core/safety/crisis_resources.dart';

void main() {
  group('crisis resources', () {
    test('US shows 988 and never a Chinese number', () {
      final text = CrisisResources.lines('US').join(' ');
      expect(text, contains('988'));
      expect(text, contains('911'));
      expect(text, isNot(contains('12356')));
    });

    test('UK and Ireland show Samaritans 116 123', () {
      expect(CrisisResources.lines('GB').join(' '), contains('116 123'));
      expect(CrisisResources.lines('IE').join(' '), contains('116 123'));
    });

    test('unknown or missing region uses the directory, not a guessed number', () {
      for (final code in [null, '', 'SE', 'AE', 'JP']) {
        final text = CrisisResources.lines(code).join(' ');
        expect(text, contains('findahelpline.com'), reason: '$code');
        expect(text, contains('your local emergency number'));
        expect(RegExp(r'\d{3}').hasMatch(text), isFalse, reason: 'no digits for $code: $text');
      }
    });

    test('every entry has an https source and no CJK', () {
      for (final r in CrisisResources.byRegion.values) {
        expect(r.sourceUrl, startsWith('https://'));
        expect(RegExp(r'[\u4e00-\u9fff]').hasMatch('${r.name}${r.contact}'), isFalse);
      }
    });
  });

  group('locale headers', () {
    tearDown(() => LocaleHeaders.deviceLocale = () => ui.PlatformDispatcher.instance.locale);

    test('send language, market and region', () {
      LocaleHeaders.deviceLocale = () => const ui.Locale('en', 'GB');
      expect(LocaleHeaders.values, {
        'Accept-Language': 'en-GB',
        'X-App-Market': 'global',
        'X-Region': 'GB',
      });
    });

    test('omit region when the device has none', () {
      LocaleHeaders.deviceLocale = () => const ui.Locale('en');
      expect(LocaleHeaders.values, {'Accept-Language': 'en', 'X-App-Market': 'global'});
    });
  });
}
