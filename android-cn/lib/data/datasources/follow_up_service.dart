// lib/data/datasources/follow_up_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';

/// Follow-up 跟进服务 - AI 主动关怀系统
class FollowUpService {
  static final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl.replaceAll('/api/v1', ''),
    connectTimeout: const Duration(seconds: 8),
  ));

  /// 创建跟进任务
  Future<FollowUpTask> createFollowUp({
    required String userId,
    required String conversationId,
    required int inDays,
    required String intent,
    String? customMessage,
  }) async {
    try {
      final res = await _dio.post('/api/v1/followup/create', data: {
        'user_id': userId,
        'conversation_id': conversationId,
        'trigger_in_days': inDays,
        'intent': intent,
        'custom_message': customMessage,
      });
      final d = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      return FollowUpTask.fromJson(d);
    } catch (_) {
      // Offline fallback: save locally
      final task = FollowUpTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        conversationId: conversationId,
        triggerAt: DateTime.now().add(Duration(days: inDays)),
        intent: intent,
        customMessage: customMessage,
      );
      final prefs = await SharedPreferences.getInstance();
      final tasks = prefs.getStringList('pending_followups') ?? [];
      tasks.add(task.toJson().toString());
      await prefs.setStringList('pending_followups', tasks);
      return task;
    }
  }

  /// 获取待触发的跟进任务
  Future<List<FollowUpTask>> getDueTasks({required String userId, int limit = 5}) async {
    try {
      final res = await _dio.get('/api/v1/followup/due', queryParameters: {
        'user_id': userId,
        'limit': limit,
      });
      final data = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (data is List) {
        return data.map((e) => FollowUpTask.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 触发跟进
  Future<void> triggerFollowUp(FollowUpTask task) async {
    try {
      await _dio.post('/api/v1/followup/trigger/${task.id}');
    } catch (_) {}
  }

  /// 取消跟进
  Future<void> cancelFollowUp(String taskId) async {
    try {
      await _dio.delete('/api/v1/followup/$taskId');
    } catch (_) {}
  }

  /// 退让机制
  Future<void> applyDeescalation(String userId) async {
    // Client-side: just track last active time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active_$userId', DateTime.now().toIso8601String());
  }
}

/// 跟进任务
class FollowUpTask {
  final String id;
  final String userId;
  final String conversationId;
  final DateTime triggerAt;
  final String intent;
  final String? customMessage;
  bool isTriggered;

  FollowUpTask({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.triggerAt,
    required this.intent,
    this.customMessage,
    this.isTriggered = false,
  });

  factory FollowUpTask.fromJson(Map<String, dynamic> json) => FollowUpTask(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    conversationId: json['conversation_id']?.toString() ?? '',
    triggerAt: json['trigger_at'] != null
        ? DateTime.tryParse(json['trigger_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
    intent: json['intent']?.toString() ?? 'check_in',
    customMessage: json['custom_message']?.toString(),
    isTriggered: json['is_triggered'] == true || json['status'] == 'triggered',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'conversation_id': conversationId,
    'trigger_at': triggerAt.toIso8601String(),
    'intent': intent,
    'custom_message': customMessage,
    'is_triggered': isTriggered,
  };
}
