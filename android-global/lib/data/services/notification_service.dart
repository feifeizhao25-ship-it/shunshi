import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 推送通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 初始化时区
      tz_data.initializeTimeZones();

      // iOS 配置
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Android 配置
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const settings = InitializationSettings(
        iOS: iosSettings,
        android: androidSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
    } catch (e) {
      // 忽略初始化错误 (特别是在模拟器上)
      print('Notification init error: $e');
    }
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    // iOS 请求权限
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// 显示即时通知
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'shunshi_default',
      'Default',
      channelDescription: 'SEASONS default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      iOS: iosDetails,
      android: androidDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// 计划通知 (定时提醒)
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'shunshi_reminder',
      'Wellness Reminders',
      channelDescription: 'Scheduled wellness reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      iOS: iosDetails,
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 每日提醒
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果时间已过，安排到明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'shunshi_daily',
      'Daily Reminders',
      channelDescription: 'Daily wellness reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      iOS: iosDetails,
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 取消特定通知
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// 获取所有待发送通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 通知被点击
  void _onNotificationTapped(NotificationResponse response) {
    // 可以根据 payload 导航到对应页面
    // final payload = response.payload;
  }
}

/// 预定义提醒
class ReminderHelper {
  /// 晨起喝水提醒
  static Future<void> scheduleMorningWater() async {
    final service = NotificationService();
    await service.scheduleDailyReminder(
      id: 1,
      title: '🌅 Good morning! Time to hydrate',
      body: 'Drink a cup of warm water to energize your day',
      hour: 7,
      minute: 30,
      payload: 'water',
    );
  }

  /// 午间休息提醒
  static Future<void> scheduleNoonBreak() async {
    final service = NotificationService();
    await service.scheduleDailyReminder(
      id: 2,
      title: '☀️ Nap time',
      body: 'Take a short break to rest your eyes and protect your Liver',
      hour: 12,
      minute: 30,
      payload: 'break',
    );
  }

  /// 下午茶提醒
  static Future<void> scheduleAfternoonTea() async {
    final service = NotificationService();
    await service.scheduleDailyReminder(
      id: 3,
      title: '🍵 Afternoon tea time',
      body: 'Enjoy a wellness tea to ease your afternoon fatigue',
      hour: 15,
      minute: 0,
      payload: 'tea',
    );
  }

  /// 睡前泡脚提醒
  static Future<void> scheduleEveningFootBath() async {
    final service = NotificationService();
    await service.scheduleDailyReminder(
      id: 4,
      title: '🌙 Time for a foot soak',
      body: 'A 15-minute foot soak can improve your sleep quality',
      hour: 21,
      minute: 30,
      payload: 'footbath',
    );
  }

  /// 开启所有默认提醒
  static Future<void> enableDefaultReminders() async {
    await scheduleMorningWater();
    await scheduleNoonBreak();
    await scheduleAfternoonTea();
    await scheduleEveningFootBath();
  }

  /// 关闭所有默认提醒
  static Future<void> disableAllReminders() async {
    await NotificationService().cancelAll();
  }
}
