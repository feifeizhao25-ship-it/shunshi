import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'SEASONS',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'next': 'Next',
      'skip': 'Skip',
      'get_started': 'Get Started',
      'nav_home': 'Home',
      'nav_seasons': 'Seasons',
      'nav_library': 'Library',
      'nav_profile': 'Profile',
      'home_greeting_morning': 'Good Morning',
      'home_greeting_afternoon': 'Good Afternoon',
      'home_greeting_evening': 'Good Evening',
      'home_daily_insight': "Today's Insight",
      'home_suggestions': 'Gentle Suggestions',
      'home_chat_entry': 'Chat with Companion',
      'home_quick_questions': 'Quick Questions',
      'chat_placeholder': 'Share your thoughts...',
      'chat_companion': 'Companion',
      'seasons_title': 'Seasons',
      'seasons_subtitle': 'Live with the rhythm of nature',
      'seasons_spring': 'Spring',
      'seasons_summer': 'Summer',
      'seasons_autumn': 'Autumn',
      'seasons_winter': 'Winter',
      'library_title': 'Library',
      'library_subtitle': 'Curated wellness content',
      'reflection_title': 'Reflection',
      'reflection_how_feeling': 'How are you feeling today?',
      'reflection_save': 'Save Reflection',
      'profile_title': 'Profile',
      'subscribe_title': 'Choose Your Plan',
      'onboarding_welcome': 'Welcome to SEASONS',
      'onboarding_subtitle': 'Your seasonal wellness companion',
      'body_type_title': 'Body Type',
      'wellness_title': 'Wellness',
      'settings_title': 'Settings',
      'subscription_title': 'Subscription',
    },
    'ja': {
      'app_title': 'SEASONS',
      'loading': '読み込み中...',
      'error': 'エラーが発生しました',
      'retry': '再試行',
      'cancel': 'キャンセル',
      'confirm': '確認',
      'save': '保存',
      'delete': '削除',
      'edit': '編集',
      'next': '次へ',
      'skip': 'スキップ',
      'get_started': '始める',
      'nav_home': 'ホーム',
      'nav_seasons': '季節',
      'nav_library': 'ライブラリ',
      'nav_profile': 'プロフィール',
      'home_greeting_morning': 'おはようございます',
      'home_greeting_afternoon': 'こんにちは',
      'home_greeting_evening': 'こんばんは',
      'home_daily_insight': '今日のインサイト',
      'home_suggestions': 'おすすめ',
      'home_chat_entry': 'チャット',
      'home_quick_questions': 'クイック質問',
      'chat_placeholder': '考えを共有する...',
      'chat_companion': 'コンパニオン',
      'seasons_title': '季節',
      'seasons_subtitle': '自然のリズムで暮らす',
      'seasons_spring': '春',
      'seasons_summer': '夏',
      'seasons_autumn': '秋',
      'seasons_winter': '冬',
      'library_title': 'ライブラリ',
      'library_subtitle': 'ウェルネスコンテンツ',
      'reflection_title': '振り返り',
      'reflection_how_feeling': '今日の気分はどうですか？',
      'reflection_save': '振り返りを保存',
      'profile_title': 'プロフィール',
      'subscribe_title': 'プランを選択',
      'onboarding_welcome': 'SEASONSへようこそ',
      'onboarding_subtitle': '季節のウェルネスコンパニオン',
      'body_type_title': '体質',
      'wellness_title': 'ウェルネス',
      'settings_title': '設定',
      'subscription_title': 'サブスクリプション',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String t(String key, {Map<String, String>? params}) {
    String text = get(key);
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
