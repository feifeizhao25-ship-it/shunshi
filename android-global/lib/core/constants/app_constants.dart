// App Constants
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'SEASONS';
  static const String appVersion = '1.0.0';
  
  // API - Auto-detect environment
  // Set SEASONS_API_URL env var or modify below for your deployment
  // Emulator uses 10.0.2.2 to reach host localhost
  // For real device, set SEASONS_API_URL or change below
  static const String baseUrl = String.fromEnvironment(
    'SEASONS_API_URL',
    defaultValue: 'http://shunshiapp.com',
  );
  static const String apiVersion = 'v1';
  
  // Subscription Tiers
  static const double freeTierPrice = 0;
  static const double premiumTierPrice = 49.0;
  static const double familyTierPrice = 79.0;
  
  // AI Models
  static const String defaultModel = 'qwen-turbo';
  static const String premiumModel = 'qwen-max';
  static const String analysisModel = 'deepseek-chat';
  
  // Cache
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 100;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
