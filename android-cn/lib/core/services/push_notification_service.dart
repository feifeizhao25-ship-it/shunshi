import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

/// 推送通知服务
///
/// 支持:
/// - FCM (Firebase Cloud Messaging) - Android
/// - APNs (Apple Push Notification Service) - iOS
/// - 本地通知
///
/// 接入步骤:
/// 1. Android: 在 Firebase Console 注册应用，下载 google-services.json
/// 2. iOS: 在 Apple Developer 配置 Push Notification 证书
/// 3. 添加依赖: firebase_messaging, flutter_local_notifications
/// 4. 调用 [initialize] 初始化
/// 5. 调用 [registerDevice] 注册设备 Token
///
/// TODO: 接入真实推送 SDK 前，使用模拟模式
class PushNotificationService {
  /// 消息流控制器
  final _messageController = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get onMessage => _messageController.stream;

  bool _initialized = false;
  String? _deviceToken;

  /// 初始化推送服务
  Future<void> initialize() async {
    if (_initialized) return;

    // TODO: 接入 firebase_messaging
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission();
    // _deviceToken = await messaging.getToken();

    // TODO: 配置前台消息监听
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   _handleMessage(message);
    // });

    // TODO: 配置后台/终止状态消息处理
    // FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // TODO: 初始化 flutter_local_notifications

    _initialized = true;
  }

  /// 注册设备到后端
  Future<bool> registerDevice(String userId) async {
    if (_deviceToken == null || _deviceToken!.isEmpty) {
      print('[Push] 设备 Token 未获取');
      return false;
    }

    try {
      final dio = ApiClient().dio;
      final response = await dio.post('/notifications/register-token', data: {
        'user_id': userId,
        'device_token': _deviceToken,
        'platform': AppConfig.appVariant.startsWith('ios') ? 'ios' : 'android',
        'device_type': 'mobile',
      });
      return response.data['success'] == true;
    } catch (e) {
      print('[Push] 注册设备失败: $e');
      return false;
    }
  }

  /// 注销设备
  Future<bool> unregisterDevice(String userId) async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.delete('/notifications/devices/unregister', data: {
        'user_id': userId,
        'device_token': _deviceToken,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('[Push] 注销设备失败: $e');
      return false;
    }
  }

  /// 显示本地通知
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // TODO: 接入 flutter_local_notifications
    // await _localNotificationsPlugin.show(
    //   id,
    //   title,
    //   body,
    //   notificationDetails,
    //   payload: payload,
    // );
    print('[Push] 本地通知: $title - $body');
  }

  /// 处理收到的消息
  void _handleMessage(dynamic message) {
    // 解析消息
    final pushMessage = PushMessage(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data ?? {},
      type: message.data?['type'] ?? 'general',
    );

    _messageController.add(pushMessage);

    // 根据消息类型处理
    switch (pushMessage.type) {
      case 'follow_up':
        _handleFollowUp(pushMessage);
        break;
      case 'safety_alert':
        _handleSafetyAlert(pushMessage);
        break;
      case 'daily_plan':
        _handleDailyPlan(pushMessage);
        break;
      default:
        showLocalNotification(title: pushMessage.title, body: pushMessage.body);
    }
  }

  void _handleFollowUp(PushMessage msg) {
    showLocalNotification(
      title: msg.title,
      body: msg.body,
      payload: jsonEncode({'route': '/chat', 'context': msg.data}),
    );
  }

  void _handleSafetyAlert(PushMessage msg) {
    showLocalNotification(
      title: '⚠️ ${msg.title}',
      body: msg.body,
      payload: jsonEncode({'route': '/safety', 'priority': 'high'}),
    );
  }

  void _handleDailyPlan(PushMessage msg) {
    showLocalNotification(
      title: msg.title,
      body: msg.body,
      payload: jsonEncode({'route': '/home'}),
    );
  }

  /// 获取未读推送数量
  Future<int> getUnreadCount(String userId) async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/notifications/unread-count?user_id=$userId');
      return response.data['data']?['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// 标记已读
  Future<bool> markAsRead(String notificationId) async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.post('/notifications/$notificationId/read');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _messageController.close();
  }
}

/// 推送消息模型
class PushMessage {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String type;

  PushMessage({
    required this.title,
    required this.body,
    required this.data,
    required this.type,
  });
}

/// 全局实例
final pushNotificationService = PushNotificationService();
