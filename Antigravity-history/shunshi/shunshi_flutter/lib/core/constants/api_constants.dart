/// API 路径常量
class ApiConstants {
  ApiConstants._();

  // AI Router
  static const String chatSend = '/chat/send';
  static const String dailyPlanGenerate = '/dailyPlan/generate';
  static const String userEntitlement = '/user/entitlement';
  static const String receiptVerify = '/subscription/verify';
  static const String featureFlagsEndpoint = '/config/feature-flags';

  // Supabase
  static const String authSignIn = '/auth/v1/token';
  static const String authSignUp = '/auth/v1/signup';
  static const String userProfile = '/rest/v1/profiles';
  static const String solarTerms = '/rest/v1/solar_terms';
  static const String wellnessContent = '/rest/v1/wellness_content';
  static const String chatSessions = '/rest/v1/chat_sessions';
  static const String chatMessages = '/rest/v1/chat_messages';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(seconds: 15);
  static const Duration dailyPlanTimeout = Duration(seconds: 10);
}
