import 'package:flutter/material.dart';

/// Localization strings for SEASONS
/// Supports: English (en), Chinese (zh), Japanese (ja), Spanish (es), French (fr), German (de)

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'SEASONS',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'done': 'Done',
      'next': 'Next',
      'skip': 'Skip',
      'get_started': 'Get Started',
      
      // Navigation
      'nav_home': 'Home',
      'nav_seasons': 'Seasons',
      'nav_library': 'Library',
      'nav_profile': 'Profile',
      
      // Home
      'home_greeting_morning': 'Good morning',
      'home_greeting_afternoon': 'Good afternoon',
      'home_greeting_evening': 'Good evening',
      'home_daily_insight': 'Daily Insight',
      'home_suggestions': 'Gentle Suggestions',
      'home_chat_entry': 'Talk to your companion',
      'home_quick_questions': 'Quick Questions',
      
      // Chat
      'chat_placeholder': 'Share your thoughts...',
      'chat_companion': 'Companion',
      
      // Seasons
      'seasons_title': 'Seasons',
      'seasons_subtitle': 'Live in rhythm with nature',
      'seasons_spring': 'Spring',
      'seasons_summer': 'Summer',
      'seasons_autumn': 'Autumn',
      'seasons_winter': 'Winter',
      'seasons_food': 'Food Suggestions',
      'seasons_stretch': 'Stretch Routines',
      'seasons_sleep': 'Sleep Rituals',
      
      // Library
      'library_title': 'Library',
      'library_subtitle': 'Your collection of calm',
      'library_all': 'All',
      'library_breathing': 'Breathing',
      'library_stretch': 'Stretch',
      'library_tea': 'Tea',
      'library_sleep': 'Sleep',
      'library_reflection': 'Reflection',
      'library_meditation': 'Meditation',
      'library_story': 'Story',
      
      // Reflection
      'reflection_title': 'Reflection',
      'reflection_how_feeling': 'How are you feeling today?',
      'reflection_mood': 'Mood',
      'reflection_energy': 'Energy Level',
      'reflection_sleep': 'Sleep Quality',
      'reflection_notes': 'Notes (optional)',
      'reflection_notes_hint': "What's on your mind?",
      'reflection_save': 'Save Reflection',
      'reflection_streak': 'day streak!',
      'reflection_weekly': 'Your Week',
      'reflection_history': 'Recent Reflections',
      
      // Moods
      'mood_calm': 'Calm',
      'mood_happy': 'Happy',
      'mood_energetic': 'Energetic',
      'mood_tired': 'Tired',
      'mood_anxious': 'Anxious',
      'mood_sad': 'Sad',
      'mood_grateful': 'Grateful',
      'mood_hopeful': 'Hopeful',
      
      // Energy
      'energy_low': 'Low',
      'energy_medium': 'Medium',
      'energy_high': 'High',
      
      // Sleep
      'sleep_poor': 'Poor',
      'sleep_fair': 'Fair',
      'sleep_good': 'Good',
      'sleep_excellent': 'Great',
      
      // Profile
      'profile_title': 'Profile',
      'profile_subscription': 'Subscription',
      'profile_free': 'Free Plan',
      'profile_premium': 'Premium',
      'profile_family': 'Family',
      'profile_upgrade': 'Upgrade',
      'profile_settings': 'Settings',
      'profile_notifications': 'Notifications',
      'profile_privacy': 'Privacy',
      'profile_help': 'Help & Support',
      'profile_about': 'About',
      'profile_sign_out': 'Sign Out',
      
      // Subscription
      'subscribe_title': 'Choose Your Plan',
      'subscribe_unlock': 'Unlock Full Experience',
      'subscribe_forever': 'forever',
      'subscribe_per_year': 'per year',
      'subscribe_restore': 'Restore Purchases',
      'subscribe_terms': 'Subscriptions auto-renew unless cancelled.',
      
      // Onboarding
      'onboarding_1_title': 'Your AI Companion',
      'onboarding_1_desc': 'A gentle presence ready to listen, reflect, and support you on your journey to calm.',
      'onboarding_2_title': 'Seasonal Living',
      'onboarding_2_desc': 'Align your daily routines with the natural rhythms of each season for balance and wellbeing.',
      'onboarding_3_title': 'Calm Content',
      'onboarding_3_desc': 'Access breathing exercises, guided stretches, sleep rituals, and peaceful meditations.',
      
      // Errors
      'error_network': 'Please check your internet connection',
      'error_server': 'Server error. Please try again later',
      'error_unknown': 'Something unexpected happened',
    },
    'zh': {
      'app_name': '顺时',
      'loading': '加载中...',
      'error': '出错了',
      'retry': '重试',
      'cancel': '取消',
      'save': '保存',
      'delete': '删除',
      'edit': '编辑',
      'done': '完成',
      'next': '下一步',
      'skip': '跳过',
      'get_started': '开始',
      'nav_home': '首页',
      'nav_seasons': '节气',
      'nav_library': '内容库',
      'nav_profile': '我的',
      'home_greeting_morning': '早上好',
      'home_greeting_afternoon': '下午好',
      'home_greeting_evening': '晚上好',
      'home_daily_insight': '今日洞察',
      'home_suggestions': '温柔建议',
      'home_chat_entry': '与伴侣对话',
      'home_quick_questions': '快速问题',
      'chat_placeholder': '分享你的想法...',
      'chat_companion': '伴侣',
      'seasons_title': '节气',
      'seasons_subtitle': '随自然节奏生活',
      'seasons_spring': '春',
      'seasons_summer': '夏',
      'seasons_autumn': '秋',
      'seasons_winter': '冬',
      'library_title': '内容库',
      'library_subtitle': '平静内容集合',
      'reflection_title': '反思',
      'reflection_how_feeling': '今天感觉如何？',
      'reflection_save': '保存反思',
      'profile_title': '我的',
      'profile_sign_out': '退出登录',
      'subscribe_title': '选择方案',
    },
    'ja': {
      'app_name': 'シーズンズ',
      'loading': '読み込み中...',
      'error': 'エラーが発生しました',
      'retry': '再試行',
      'cancel': 'キャンセル',
      'save': '保存',
      'next': '次へ',
      'skip': 'スキップ',
      'get_started': '始める',
      'nav_home': 'ホーム',
      'nav_seasons': '季節',
      'nav_library': 'ライブラリ',
      'nav_profile': 'プロフィール',
    },
    'es': {
      'app_name': 'SEASONS',
      'loading': 'Cargando...',
      'error': 'Algo salió mal',
      'retry': 'Reintentar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'next': 'Siguiente',
      'skip': 'Omitir',
      'get_started': 'Comenzar',
      'nav_home': 'Inicio',
      'nav_seasons': 'Estaciones',
      'nav_library': 'Biblioteca',
      'nav_profile': 'Perfil',
    },
    'fr': {
      'app_name': 'SAISONS',
      'loading': 'Chargement...',
      'error': 'Une erreur est survenue',
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'save': 'Sauvegarder',
      'next': 'Suivant',
      'skip': 'Passer',
      'get_started': 'Commencer',
      'nav_home': 'Accueil',
      'nav_seasons': 'Saisons',
      'nav_library': 'Bibliothèque',
      'nav_profile': 'Profil',
    },
    'de': {
      'app_name': 'JAHRESZEITEN',
      'loading': 'Laden...',
      'error': 'Etwas ist schief gelaufen',
      'retry': 'Wiederholen',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'next': 'Weiter',
      'skip': 'Überspringen',
      'get_started': 'Loslegen',
      'nav_home': 'Start',
      'nav_seasons': 'Jahreszeiten',
      'nav_library': 'Bibliothek',
      'nav_profile': 'Profil',
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
  
  // Convenience getters
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get next => translate('next');
  String get skip => translate('skip');
  String get getStarted => translate('get_started');
  
  // Navigation
  String get navHome => translate('nav_home');
  String get navSeasons => translate('nav_seasons');
  String get navLibrary => translate('nav_library');
  String get navProfile => translate('nav_profile');
  
  // Home
  String getHomeGreeting(int hour) {
    if (hour < 12) return translate('home_greeting_morning');
    if (hour < 17) return translate('home_greeting_afternoon');
    return translate('home_greeting_evening');
  }
  
  String get homeDailyInsight => translate('home_daily_insight');
  String get homeSuggestions => translate('home_suggestions');
  String get homeChatEntry => translate('home_chat_entry');
  
  // Chat
  String get chatPlaceholder => translate('chat_placeholder');
  String get chatCompanion => translate('chat_companion');
  
  // Seasons
  String get seasonsTitle => translate('seasons_title');
  
  // Library
  String get libraryTitle => translate('library_title');
  String get librarySubtitle => translate('library_subtitle');
  
  // Reflection
  String get reflectionTitle => translate('reflection_title');
  String get reflectionSave => translate('reflection_save');
  
  // Profile
  String get profileTitle => translate('profile_title');
  String get profileSignOut => translate('profile_sign_out');
  
  // Subscription
  String get subscribeTitle => translate('subscribe_title');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'ja', 'es', 'fr', 'de'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
