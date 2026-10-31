import 'dart:ui' as ui;

/// Headers that tell the backend which language and region this device is in.
///
/// The backend answers in English with local safety resources when it sees a non-Chinese
/// language or `X-App-Market: global`, and needs the region to pick the right crisis line.
/// Without them the international edition was answered in Chinese with Chinese hotlines.
class LocaleHeaders {
  const LocaleHeaders._();

  /// Test hook.
  static ui.Locale Function() deviceLocale = () => ui.PlatformDispatcher.instance.locale;

  static Map<String, String> get values {
    final l = deviceLocale();
    final tag = l.countryCode == null || l.countryCode!.isEmpty
        ? l.languageCode
        : '${l.languageCode}-${l.countryCode}';
    return {
      'Accept-Language': tag,
      'X-App-Market': 'global',
      if (l.countryCode != null && l.countryCode!.isNotEmpty) 'X-Region': l.countryCode!,
    };
  }
}
