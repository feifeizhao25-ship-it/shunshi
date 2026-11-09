import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/theme/app_localizations.dart';
import 'package:seasons/presentation/pages/about/about_page.dart';
import 'package:seasons/presentation/pages/profile/about_page.dart' as profile_about;

void main() {
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
