import 'app_config.dart';

/// Centralized API configuration for SEASONS.
/// Tries multiple endpoints with fallback.
class ApiConfig {
  ApiConfig._();

  /// Base URLs in priority order.
  /// 1. The configured API base
  /// 2. Android emulator localhost
  static const List<String> baseUrls = [
    AppConfig.apiBaseUrl, // configured API base (--dart-define=API_BASE_URL=...)
    'http://10.0.2.2:4010', // Android emulator
  ];

  /// Current active base URL (cached after first successful connection)
  static String? _activeUrl;

  /// Get the active base URL. Tests connectivity and caches result.
  static String get baseUrl {
    if (_activeUrl != null) return _activeUrl!;
    // Return first URL, let Dio handle timeout
    // The actual detection happens in first API call
    return baseUrls[0];
  }

  /// Mark a URL as working
  static void markWorking(String url) {
    _activeUrl = url;
  }

  /// Reset (force re-detection)
  static void reset() {
    _activeUrl = null;
  }
}
