import 'package:flutter/foundation.dart';

/// 简单的本地分析服务
/// 可以后续对接 Firebase Analytics 或其他分析平台
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isEnabled = true;

  /// 初始化
  void init() {
    // 可以在这里初始化 Firebase Analytics
    // FirebaseAnalytics.instance;
  }

  /// 设置是否启用
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 记录页面浏览
  Future<void> logPageView(String pageName, {String? screenClass}) async {
    if (!_isEnabled) return;
    
    _log('page_view', {
      'page_name': pageName,
      'screen_class': screenClass ?? pageName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 记录用户事件
  Future<void> logEvent(String eventName, [Map<String, dynamic>? params]) async {
    if (!_isEnabled) return;

    _log(eventName, {
      ...?params,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 记录用户属性
  Future<void> setUserProperty(String name, String? value) async {
    if (!_isEnabled) return;

    _log('user_property', {
      'name': name,
      'value': value,
    });
  }

  /// 记录用户 ID
  Future<void> setUserId(String userId) async {
    if (!_isEnabled) return;

    _log('user_id', {
      'user_id': userId,
    });
  }

  /// 内部日志
  void _log(String event, Map<String, dynamic> data) {
    // 调试模式打印
    if (kDebugMode) {
      print('[Analytics] $event: $data');
    }
    // TODO: 后续可以接入 Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(name: event, parameters: data);
  }
}

/// 预定义事件
class AnalyticsEvents {
  // 用户行为
  static const String buttonClicked = 'button_clicked';
  static const String pageViewed = 'page_viewed';
  static const String searchPerformed = 'search_performed';

  // 对话相关
  static const String chatStarted = 'chat_started';
  static const String chatMessageSent = 'chat_message_sent';
  static const String chatEnded = 'chat_ended';

  // 养生功能
  static const String wellnessPageViewed = 'wellness_page_viewed';
  static const String solarTermViewed = 'solar_term_viewed';
  static const String foodRecommendViewed = 'food_recommend_viewed';
  static const String teaRecommendViewed = 'tea_recommend_viewed';
  static const String constitutionTestStarted = 'constitution_test_started';

  // 习惯打卡
  static const String habitCheckIn = 'habit_check_in';
  static const String habitUnchecked = 'habit_unchecked';

  // 家庭
  static const String familyMemberAdded = 'family_member_added';
  static const String careSent = 'care_sent';

  // 订阅
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionCancelled = 'subscription_cancelled';

  // 设置
  static const String settingsChanged = 'settings_changed';
  static const String themeChanged = 'theme_changed';
  static const String notificationToggled = 'notification_toggled';
}

/// 预定义参数
class AnalyticsParams {
  static const String pageName = 'page_name';
  static const String buttonName = 'button_name';
  static const String featureName = 'feature_name';
  static const String habitId = 'habit_id';
  static const String memberId = 'member_id';
  static const String subscriptionType = 'subscription_type';
  static const String themeMode = 'theme_mode';
  static const String notificationEnabled = 'notification_enabled';
}

/// 分析服务帮助类
class AnalyticsHelper {
  static final service = AnalyticsService();

  /// 记录页面浏览
  static Future<void> trackPage(String pageName, {String? screenClass}) async {
    await service.logPageView(pageName, screenClass: screenClass);
  }

  /// 记录按钮点击
  static Future<void> trackButton(String buttonName, {String? pageName}) async {
    await service.logEvent(AnalyticsEvents.buttonClicked, {
      AnalyticsParams.buttonName: buttonName,
      if (pageName != null) AnalyticsParams.pageName: pageName,
    });
  }

  /// 记录养生页面浏览
  static Future<void> trackWellnessPage(String featureName) async {
    await service.logEvent(AnalyticsEvents.wellnessPageViewed, {
      AnalyticsParams.featureName: featureName,
    });
  }

  /// 记录打卡
  static Future<void> trackCheckIn(String habitId) async {
    await service.logEvent(AnalyticsEvents.habitCheckIn, {
      AnalyticsParams.habitId: habitId,
    });
  }

  /// 记录订阅
  static Future<void> trackSubscription(String type) async {
    await service.logEvent(AnalyticsEvents.subscriptionStarted, {
      AnalyticsParams.subscriptionType: type,
    });
  }

  /// 记录主题切换
  static Future<void> trackThemeChange(String themeMode) async {
    await service.logEvent(AnalyticsEvents.themeChanged, {
      AnalyticsParams.themeMode: themeMode,
    });
  }
}
