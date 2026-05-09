import 'package:flutter/foundation.dart';

/// Notification Service for SEASONS
/// Handles local and push notifications

enum NotificationType {
  dailyInsight,
  reminder,
  reflection,
  suggestion,
  subscription,
  system,
}

class NotificationPayload {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  
  NotificationPayload({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    if (data != null) 'data': data,
  };
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  bool _enabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _dndEnabled = false;
  
  final List<NotificationPayload> _pendingNotifications = [];
  
  // ===================
  // Configuration
  // ===================
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }
  
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }
  
  void setDndEnabled(bool enabled) {
    _dndEnabled = enabled;
  }
  
  bool get isEnabled => _enabled;
  bool get isSoundEnabled => _soundEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;
  
  // ===================
  // Permission
  // ===================
  
  Future<bool> requestPermission() async {
    // In production, request from OS
    // For now, return true
    if (kDebugMode) {
      print('[Notification] Requesting permission...');
    }
    return true;
  }
  
  Future<bool> hasPermission() async {
    // Check with OS
    return true;
  }
  
  // ===================
  // Local Notifications
  // ===================
  
  Future<void> showNotification(NotificationPayload payload) async {
    if (!_enabled) return;
    
    // Check DND
    if (_dndEnabled && _isDndTime(payload.type)) {
      if (kDebugMode) {
        print('[Notification] Skipped due to DND: ${payload.title}');
      }
      return;
    }
    
    // Store notification
    _pendingNotifications.add(payload);
    
    if (kDebugMode) {
      print('[Notification] Showing: ${payload.title} - ${payload.body}');
    }
    
    // In production, show with flutter_local_notifications
    // await _flutterLocalNotificationsPlugin.show(
    //   payload.id.hashCode,
    //   payload.title,
    //   payload.body,
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'seasons_channel',
    //       'SEASONS Notifications',
    //       channelDescription: 'Notifications from SEASONS',
    //       importance: Importance.high,
    //     ),
    //   ),
    // );
  }
  
  Future<void> showDailyInsight(String insight) async {
    await showNotification(NotificationPayload(
      id: 'daily_insight_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.dailyInsight,
      title: 'Your Daily Insight',
      body: insight,
    ));
  }
  
  Future<void> showReflectionReminder() async {
    await showNotification(NotificationPayload(
      id: 'reflection_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reflection,
      title: 'Time for Reflection',
      body: 'How are you feeling today? Take a moment to check in with yourself.',
    ));
  }
  
  Future<void> showSuggestionReminder(String suggestion) async {
    await showNotification(NotificationPayload(
      id: 'suggestion_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.suggestion,
      title: 'Gentle Reminder',
      body: suggestion,
    ));
  }
  
  Future<void> showSubscriptionExpiring(String tier, int daysLeft) async {
    await showNotification(NotificationPayload(
      id: 'subscription_expiring_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.subscription,
      title: 'Subscription Expiring',
      body: 'Your $tier subscription expires in $daysLeft days. Renew to keep your calm companion!',
    ));
  }
  
  // ===================
  // Scheduled Notifications
  // ===================
  
  Future<void> scheduleNotification({
    required NotificationPayload payload,
    required DateTime scheduledTime,
  }) async {
    if (!_enabled) return;
    
    if (kDebugMode) {
      print('[Notification] Scheduled: ${payload.title} at $scheduledTime');
    }
    
    // In production, schedule with flutter_local_notifications
  }
  
  Future<void> scheduleDailyInsight({required int hour, required int minute}) async {
    // Schedule daily insight notification
    if (kDebugMode) {
      print('[Notification] Daily insight scheduled for $hour:$minute');
    }
  }
  
  Future<void> scheduleReflectionReminder({required int hour, required int minute}) async {
    // Schedule daily reflection reminder
    if (kDebugMode) {
      print('[Notification] Reflection reminder scheduled for $hour:$minute');
    }
  }
  
  Future<void> cancelScheduledNotification(String notificationId) async {
    if (kDebugMode) {
      print('[Notification] Cancelled: $notificationId');
    }
  }
  
  Future<void> cancelAllScheduledNotifications() async {
    if (kDebugMode) {
      print('[Notification] All scheduled notifications cancelled');
    }
  }
  
  // ===================
  // Push Notifications
  // ===================
  
  Future<void> registerDevice(String token) async {
    if (kDebugMode) {
      print('[Notification] Device registered: $token');
    }
    // In production, send token to backend
  }
  
  Future<void> unregisterDevice() async {
    if (kDebugMode) {
      print('[Notification] Device unregistered');
    }
    // In production, remove token from backend
  }
  
  void handlePushNotification(Map<String, dynamic> data) {
    // Handle incoming push notification
    if (kDebugMode) {
      print('[Notification] Push received: $data');
    }
    
    final type = NotificationType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => NotificationType.system,
    );
    
    showNotification(NotificationPayload(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: data['title'] ?? 'SEASONS',
      body: data['body'] ?? '',
      data: data,
    ));
  }
  
  // ===================
  // Helper
  // ===================
  
  bool _isDndTime(NotificationType type) {
    // Allow important notifications through DND
    return type != NotificationType.subscription && 
           type != NotificationType.system;
  }
  
  List<NotificationPayload> getPendingNotifications() => 
      List.unmodifiable(_pendingNotifications);
  
  void clearPendingNotifications() => _pendingNotifications.clear();
  
  // ===================
  // Analytics
  // ===================
  
  void trackNotificationSent(NotificationPayload payload) {
    if (kDebugMode) {
      print('[Analytics] Notification sent: ${payload.type.name}');
    }
  }
  
  void trackNotificationTapped(NotificationPayload payload) {
    if (kDebugMode) {
      print('[Analytics] Notification tapped: ${payload.type.name}');
    }
  }
  
  void trackNotificationDismissed(NotificationPayload payload) {
    if (kDebugMode) {
      print('[Analytics] Notification dismissed: ${payload.type.name}');
    }
  }
}

/// Notification provider helper
class NotificationProvider {
  final NotificationService service;
  
  NotificationProvider({NotificationService? service})
      : service = service ?? NotificationService();
  
  Future<bool> requestPermission() => service.requestPermission();
  
  Future<void> showDailyInsight(String insight) => service.showDailyInsight(insight);
  
  Future<void> showReflectionReminder() => service.showReflectionReminder();
  
  Future<void> scheduleDailyInsight({required int hour, required int minute}) =>
      service.scheduleDailyInsight(hour: hour, minute: minute);
}
