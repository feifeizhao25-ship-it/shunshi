import 'package:dio/dio.dart';

/// Follow-up 跟进服务 - AI 主动关怀系统（对接后端 /api/v1/followup）
class FollowUpService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'http://116.62.32.43:4000',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 创建跟进任务 - POST /api/v1/followup/schedule
  Future<FollowUpTask> createFollowUp({
    required String userId,
    required String conversationId,
    required int inDays,
    required String intent,
    String? customMessage,
  }) async {
    try {
      final res = await _dio.post('/api/v1/followup/schedule', data: {
        'user_id': userId,
        'conversation_id': conversationId,
        'in_days': inDays,
        'intent': intent,
        'custom_message': customMessage,
      });
      if (res.data?['success'] == true) {
        return FollowUpTask.fromJson(res.data['data']);
      }
    } catch (_) {}
    // Fallback: local task
    return FollowUpTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      conversationId: conversationId,
      triggerAt: DateTime.now().add(Duration(days: inDays)),
      intent: intent,
      customMessage: customMessage,
    );
  }

  /// 智能调度跟进 - POST /api/v1/followup/schedule-smart
  Future<FollowUpTask?> scheduleSmart({
    required String userId,
    required String intent,
    String? conversationId,
  }) async {
    try {
      final res = await _dio.post('/api/v1/followup/schedule-smart', data: {
        'user_id': userId,
        'intent': intent,
        'conversation_id': conversationId,
      });
      if (res.data?['success'] == true) {
        return FollowUpTask.fromJson(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  /// 获取到期跟进列表 - GET /api/v1/followup/due
  Future<List<FollowUpTask>> getDueFollowUps(String userId) async {
    try {
      final res = await _dio.get('/api/v1/followup/due', queryParameters: {'user_id': userId});
      if (res.data?['success'] == true) {
        final List data = res.data['data'];
        return data.map((t) => FollowUpTask.fromJson(t)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取跟进列表 - GET /api/v1/followup/list
  Future<List<FollowUpTask>> getFollowUpList(String userId, {int limit = 20}) async {
    try {
      final res = await _dio.get('/api/v1/followup/list', queryParameters: {
        'user_id': userId, 'limit': limit,
      });
      if (res.data?['success'] == true) {
        final List data = res.data['data'];
        return data.map((t) => FollowUpTask.fromJson(t)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 打卡/完成跟进 - POST /api/v1/followup/check
  Future<bool> checkFollowUp(String followupId, {String? note}) async {
    try {
      final res = await _dio.post('/api/v1/followup/check', data: {
        'followup_id': followupId, 'note': note,
      });
      return res.data?['success'] == true;
    } catch (_) {}
    return false;
  }

  /// 每日快速打卡 - POST /api/v1/followup/quick/daily-checkin
  Future<bool> dailyCheckIn(String userId, {String? mood, int? sleepHours}) async {
    try {
      final res = await _dio.post('/api/v1/followup/quick/daily-checkin', data: {
        'user_id': userId, 'mood': mood, 'sleep_hours': sleepHours,
      });
      return res.data?['success'] == true;
    } catch (_) {}
    return false;
  }

  /// 取消跟进 - DELETE /api/v1/followup/{id}
  Future<bool> cancelFollowUp(String taskId) async {
    try {
      final res = await _dio.delete('/api/v1/followup/$taskId');
      return res.data?['success'] == true;
    } catch (_) {}
    return false;
  }

  /// 获取跟进统计 - GET /api/v1/followup/stats
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final res = await _dio.get('/api/v1/followup/stats', queryParameters: {'user_id': userId});
      if (res.data?['success'] == true) return res.data['data'];
    } catch (_) {}
    return {'total': 0, 'completed': 0, 'pending': 0};
  }

  /// 获取跟进类型 - GET /api/v1/followup/types
  Future<List<Map<String, dynamic>>> getTypes() async {
    try {
      final res = await _dio.get('/api/v1/followup/types');
      if (res.data?['success'] == true) return List<Map<String, dynamic>>.from(res.data['data']);
    } catch (_) {}
    return [
      {'key': 'check_in', 'label': 'Daily Check-in'},
      {'key': 'sleep_check', 'label': 'Sleep Check'},
      {'key': 'diet_check', 'label': 'Diet Check'},
      {'key': 'mood_check', 'label': 'Mood Check'},
      {'key': 'exercise_check', 'label': 'Exercise Check'},
    ];
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

  factory FollowUpTask.fromJson(Map<String, dynamic> json) {
    return FollowUpTask(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      triggerAt: json['trigger_at'] != null
          ? DateTime.tryParse(json['trigger_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      intent: json['intent'] ?? 'check_in',
      customMessage: json['custom_message'],
      isTriggered: json['is_triggered'] == true || json['status'] == 'triggered',
    );
  }
}
