// Follow-up 调度系统
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Follow-up 任务
class FollowUpTask {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final FollowUpStatus status;
  final FollowUpPriority priority;
  final String? relatedContentId;
  final int retryCount;
  
  const FollowUpTask({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.completedAt,
    this.status = FollowUpStatus.pending,
    this.priority = FollowUpPriority.normal,
    this.relatedContentId,
    this.retryCount = 0,
  });
  
  FollowUpTask copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    DateTime? completedAt,
    FollowUpStatus? status,
    FollowUpPriority? priority,
    String? relatedContentId,
    int? retryCount,
  }) {
    return FollowUpTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      relatedContentId: relatedContentId ?? this.relatedContentId,
      retryCount: retryCount ?? this.retryCount,
    );
  }
  
  /// 是否应该执行
  bool get shouldExecute {
    if (status != FollowUpStatus.pending) return false;
    return DateTime.now().isAfter(scheduledAt);
  }
  
  /// 是否已过期 (超过24小时)
  bool get isExpired {
    return DateTime.now().isAfter(scheduledAt.add(const Duration(hours: 24)));
  }
}

enum FollowUpStatus {
  pending,
  completed,
  skipped,
  expired,
}

enum FollowUpPriority {
  high,
  normal,
  low,
}

/// Follow-up 调度器
class FollowUpScheduler {
  final Map<String, FollowUpTask> _tasks = {};
  Timer? _timer;
  final List<Function(FollowUpTask)> _listeners = [];
  
  /// 调度一个 Follow-up 任务
  void schedule(FollowUpTask task) {
    _tasks[task.id] = task;
    _scheduleTimer();
  }
  
  /// 取消一个任务
  void cancel(String taskId) {
    _tasks.remove(taskId);
    _scheduleTimer();
  }
  
  /// 获取所有待执行的任务
  List<FollowUpTask> get pendingTasks {
    return _tasks.values
        .where((task) => task.status == FollowUpStatus.pending)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }
  
  /// 获取今日任务
  List<FollowUpTask> get todayTasks {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _tasks.values.where((task) {
      return task.scheduledAt.isAfter(startOfDay) && 
             task.scheduledAt.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }
  
  /// 执行任务
  Future<void> execute(String taskId) async {
    final task = _tasks[taskId];
    if (task == null || !task.shouldExecute) return;
    
    // 通知监听器
    for (final listener in _listeners) {
      listener(task);
    }
  }
  
  /// 完成任务
  void complete(String taskId) {
    final task = _tasks[taskId];
    if (task != null) {
      _tasks[taskId] = task.copyWith(
        status: FollowUpStatus.completed,
        completedAt: DateTime.now(),
      );
    }
  }
  
  /// 跳过任务
  void skip(String taskId) {
    final task = _tasks[taskId];
    if (task != null) {
      _tasks[taskId] = task.copyWith(
        status: FollowUpStatus.skipped,
      );
    }
  }
  
  /// 添加监听器
  void addListener(Function(FollowUpTask) listener) {
    _listeners.add(listener);
  }
  
  /// 移除监听器
  void removeListener(Function(FollowUpTask) listener) {
    _listeners.remove(listener);
  }
  
  /// 启动定时器
  void _scheduleTimer() {
    _timer?.cancel();
    
    if (_tasks.isEmpty) return;
    
    // 找到下一个要执行的任务
    final nextTask = pendingTasks.isNotEmpty 
        ? pendingTasks.first 
        : null;
    
    if (nextTask == null) return;
    
    // 计算延迟
    final delay = nextTask.scheduledAt.difference(DateTime.now());
    if (delay.isNegative) {
      // 立即执行
      execute(nextTask.id);
    } else {
      // 延迟执行
      _timer = Timer(delay, () => execute(nextTask.id));
    }
  }
  
  /// 清理过期任务
  void cleanup() {
    final expiredTasks = _tasks.values.where((task) => task.isExpired);
    for (final task in expiredTasks) {
      _tasks[task.id] = task.copyWith(status: FollowUpStatus.expired);
    }
  }
  
  /// 停止调度器
  void dispose() {
    _timer?.cancel();
    _listeners.clear();
  }
}

/// 全局 Follow-up 调度器
final followUpSchedulerProvider = Provider<FollowUpScheduler>((ref) {
  final scheduler = FollowUpScheduler();
  ref.onDispose(() => scheduler.dispose());
  return scheduler;
});

/// Follow-up 任务 Provider
final followUpTasksProvider = StateNotifierProvider<FollowUpTasksNotifier, List<FollowUpTask>>((ref) {
  return FollowUpTasksNotifier(ref.read(followUpSchedulerProvider));
});

class FollowUpTasksNotifier extends StateNotifier<List<FollowUpTask>> {
  final FollowUpScheduler _scheduler;
  
  FollowUpTasksNotifier(this._scheduler) : super([]) {
    _scheduler.addListener(_onTaskExecute);
  }
  
  void _onTaskExecute(FollowUpTask task) {
    // 触发通知
    // TODO: 发送推送通知
    state = [...state, task];
  }
  
  /// 添加任务
  void addTask(FollowUpTask task) {
    _scheduler.schedule(task);
    state = [...state, task];
  }
  
  /// 创建新任务
  void create({
    required String userId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    FollowUpPriority priority = FollowUpPriority.normal,
    String? relatedContentId,
  }) {
    final task = FollowUpTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      priority: priority,
      relatedContentId: relatedContentId,
    );
    
    addTask(task);
  }
  
  /// 完成任务
  void complete(String taskId) {
    _scheduler.complete(taskId);
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: FollowUpStatus.completed,
          completedAt: DateTime.now(),
        );
      }
      return task;
    }).toList();
  }
  
  /// 跳过任务
  void skip(String taskId) {
    _scheduler.skip(taskId);
    state = state.map((task) {
      if (task.id == taskId) {
        return task.copyWith(status: FollowUpStatus.skipped);
      }
      return task;
    }).toList();
  }
  
  /// 删除任务
  void delete(String taskId) {
    _scheduler.cancel(taskId);
    state = state.where((task) => task.id != taskId).toList();
  }
  
  /// 获取待办任务
  List<FollowUpTask> get pendingTasks {
    return state.where((task) => task.status == FollowUpStatus.pending).toList();
  }
  
  /// 获取今日任务
  List<FollowUpTask> get todayTasks {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return state.where((task) {
      return task.scheduledAt.isAfter(startOfDay) && 
             task.scheduledAt.isBefore(endOfDay);
    }).toList();
  }
  
  @override
  void dispose() {
    _scheduler.removeListener(_onTaskExecute);
    super.dispose();
  }
}

/// Follow-up 提醒服务
class FollowUpReminderService {
  final FollowUpScheduler _scheduler;
  
  FollowUpReminderService(this._scheduler);
  
  /// 调度提醒
  Future<void> scheduleReminder({
    required String taskId,
    required String userId,
    required String title,
    required DateTime scheduledAt,
    int? minutesBefore,
  }) async {
    // 计算提醒时间
    final reminderTime = minutesBefore != null
        ? scheduledAt.subtract(Duration(minutes: minutesBefore))
        : scheduledAt;
    
    // 如果提醒时间已过，立即发送
    if (reminderTime.isBefore(DateTime.now())) {
      await _sendReminder(taskId, userId, title);
      return;
    }
    
    // 调度延迟提醒
    final delay = reminderTime.difference(DateTime.now());
    Timer(delay, () => _sendReminder(taskId, userId, title));
  }
  
  Future<void> _sendReminder(String taskId, String userId, String title) async {
    // TODO: 调用推送服务发送通知
    print('Sending reminder for task: $taskId - $title');
  }
}
