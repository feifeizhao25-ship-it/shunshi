// lib/data/datasources/follow_up_service.dart

/// Follow-up 跟进服务 - AI 主动关怀系统
class FollowUpService {
  /// 创建跟进任务
  Future<FollowUpTask> createFollowUp({
    required String userId,
    required String conversationId,
    required int inDays,
    required String intent,
    String? customMessage,
  }) async {
    final task = FollowUpTask(
      id: _generateId(),
      userId: userId,
      conversationId: conversationId,
      triggerAt: DateTime.now().add(Duration(days: inDays)),
      intent: intent,
      customMessage: customMessage,
    );

    // 存储到数据库
    await _saveTask(task);

    // 设置定时任务
    await _scheduleTask(task);

    return task;
  }

  /// 触发跟进
  Future<void> triggerFollowUp(FollowUpTask task) async {
    // 1. 检查用户状态
    final shouldTrigger = await _checkUserStatus(task.userId);
    if (!shouldTrigger) {
      return;
    }

    // 2. 生成跟进消息
    final message = await _generateFollowUpMessage(task);

    // 3. 发送通知
    await _sendNotification(task.userId, message);

    // 4. 标记为已触发
    await _markTriggered(task.id);
  }

  /// 退让机制 - 用户长期未回复时减少提醒
  Future<void> applyDeescalation(String userId) async {
    // 检查用户最后活跃时间
    final lastActive = await _getLastActiveTime(userId);
    final daysSinceActive = DateTime.now().difference(lastActive).inDays;

    if (daysSinceActive > 7) {
      // 7天未活跃，降低优先级
      await _reduceReminderFrequency(userId, level: 3);
    } else if (daysSinceActive > 3) {
      await _reduceReminderFrequency(userId, level: 2);
    } else if (daysSinceActive > 1) {
      await _reduceReminderFrequency(userId, level: 1);
    }
  }

  /// 取消跟进
  Future<void> cancelFollowUp(String taskId) async {
    await _cancelScheduledTask(taskId);
    await _deleteTask(taskId);
  }

  // 私有方法
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _saveTask(FollowUpTask task) async {
    // TODO: 保存到数据库
  }

  Future<void> _scheduleTask(FollowUpTask task) async {
    // TODO: 使用定时任务调度器
  }

  Future<bool> _checkUserStatus(String userId) async {
    // 检查用户是否希望接收跟进
    // 检查用户是否在 SafeMode
    return true;
  }

  Future<String> _generateFollowUpMessage(FollowUpTask task) async {
    final templates = {
      'check_in': '最近怎么样？记得照顾好自己～',
      'sleep_check': '昨晚睡得好吗？有什么我可以帮你的吗？',
      'diet_check': '今天饮食怎么样？记得按时吃饭～',
      'mood_check': '最近心情如何？有什么想聊的吗？',
      'exercise_check': '今天运动了吗？适度运动对身体好哦～',
    };

    return task.customMessage ?? templates[task.intent] ?? '最近怎么样？';
  }

  Future<void> _sendNotification(String userId, String message) async {
    // TODO: 发送推送通知
  }

  Future<void> _markTriggered(String taskId) async {
    // TODO: 更新数据库
  }

  Future<DateTime> _getLastActiveTime(String userId) async {
    // TODO: 从数据库获取
    return DateTime.now().subtract(const Duration(days: 1));
  }

  Future<void> _reduceReminderFrequency(String userId, {required int level}) async {
    // 降低提醒频率
  }

  Future<void> _cancelScheduledTask(String taskId) async {
    // TODO: 取消定时任务
  }

  Future<void> _deleteTask(String taskId) async {
    // TODO: 从数据库删除
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
}
