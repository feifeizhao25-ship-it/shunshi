/// 业务常量
class AppConstants {
  AppConstants._();

  static const String appName = '顺时';
  static const String appNameEn = 'ShunShi';

  // 订阅 Product IDs
  static const String monthlyPremiumId = 'shunshi_premium_monthly';
  static const String annualPremiumId = 'shunshi_premium_annual';

  // 退让机制阈值
  static const int presenceIgnoreThreshold = 3;
  static const int presenceStableDaysThreshold = 7;

  // 缓存
  static const Duration dailyPlanCacheDuration = Duration(hours: 12);
  static const Duration subscriptionRevalidateInterval = Duration(hours: 4);

  // 心理援助热线
  static const String crisisHotlineNational = '400-161-9995';
  static const String crisisHotlineBeijing = '010-82951332';

  // 限制
  static const int maxMessageLength = 2000;
  static const int maxFollowUpQuestions = 5;
}
