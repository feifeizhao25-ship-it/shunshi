import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/network/locale_headers.dart';
import 'package:seasons/core/services/ai_safety.dart';

/// 2026-11-21 UI test: an en-AE user's crisis message on /chat got the generic US/UK/AU card.
/// The router sends /chat and /assistant to ChatPage (lib/presentation/pages/chat_page.dart);
/// the region fix in #159 only touched chat/seasons_chat_page.dart, which no route opens.
void main() {
  final original = LocaleHeaders.deviceLocale;
  tearDown(() => LocaleHeaders.deviceLocale = original);

  test('the live /chat route is ChatPage, so that is the page that must pass the region', () {
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(router, contains("path: '/chat', pageBuilder: (context, state) => NoTransitionPage(child: ChatPage("));
    expect(router, isNot(contains('SeasonsChatPage(')));
  });

  test('ChatPage passes English + the device region to getCrisisResponse', () {
    final src = File('lib/presentation/pages/chat_page.dart').readAsStringSync();
    expect(src, isNot(contains('getCrisisResponse(riskLevel)')));
    expect(src, contains('isEnglish: true, countryCode: LocaleHeaders.deviceLocale().countryCode'));
  });

  test('en-AE device gets the UAE line, not the generic US/UK/AU text', () {
    LocaleHeaders.deviceLocale = () => const ui.Locale('en', 'AE');
    final text = AISafetyService.getCrisisResponse(RiskLevel.crisis,
        isEnglish: true, countryCode: LocaleHeaders.deviceLocale().countryCode);
    expect(text, contains('800-HOPE'));
    expect(text, isNot(contains('13 11 14')));
  });

  test('a region we have not verified gets the directory, never a guessed number', () {
    LocaleHeaders.deviceLocale = () => const ui.Locale('ja', 'JP');
    final text = AISafetyService.getCrisisResponse(RiskLevel.crisis,
        isEnglish: true, countryCode: LocaleHeaders.deviceLocale().countryCode);
    expect(text, contains('findahelpline.com'));
    expect(text, isNot(contains('12356')));
  });
}
