// OptimisticUpdateMixin — UX_API_SPEC §6 乐观更新
// 收藏/点赞/关注的乐观更新 + 失败回滚 + 去抖 + 离线队列
import 'dart:async';
import '../cache/cache_service.dart';

// ==================== Optimistic Action ====================

/// 乐观操作记录 — 用于回滚
class OptimisticAction<T> {
  final String id;
  final T previousState;
  final T newState;
  final String cacheKey;
  final DateTime timestamp;

  OptimisticAction({
    required this.id,
    required this.previousState,
    required this.newState,
    required this.cacheKey,
  }) : timestamp = DateTime.now();
}

// ==================== Optimistic Update Manager ====================

/// 乐观更新管理器 — 统一管理所有乐观操作
class OptimisticUpdateManager {
  static final OptimisticUpdateManager _instance = OptimisticUpdateManager._();
  factory OptimisticUpdateManager() => _instance;
  OptimisticUpdateManager._();

  // 进行中的操作 (id → action)
  final Map<String, OptimisticAction> _pendingActions = {};

  // 去抖定时器 (key → timer)
  final Map<String, Timer> _debounceTimers = {};

  // 离线待同步队列
  final List<Map<String, dynamic>> _offlineQueue = [];

  // 回调
  final StreamController<OptimisticEvent> _eventController =
      StreamController<OptimisticEvent>.broadcast();
  Stream<OptimisticEvent> get events => _eventController.stream;

  /// 执行乐观更新
  /// 1. 保存旧值（用于回滚）
  /// 2. 立即更新缓存
  /// 3. 发出事件
  /// 4. 调用 serverAction
  /// 5. 失败 → 回滚
  Future<T> execute<T>({
    required String id,
    required String cacheKey,
    required CacheConfig cacheConfig,
    required T Function(T current) updateFn,
    required Future<T> Function() serverAction,
    T Function()? getInitial,
    Duration debounce = const Duration(milliseconds: 200),
  }) async {
    // 获取当前值
    final cached = cacheService.get<T>(cacheKey, config: cacheConfig);
    final currentValue = cached?.data ?? (getInitial != null ? getInitial() : null) as T;

    // 乐观更新
    final newValue = updateFn(currentValue);

    // 保存旧值用于回滚
    _pendingActions[id] = OptimisticAction<T>(
      id: id,
      previousState: currentValue,
      newState: newValue,
      cacheKey: cacheKey,
    );

    // 立即更新缓存
    await cacheService.set<T>(cacheKey, newValue, config: cacheConfig);

    // 发出乐观更新事件
    _emit(OptimisticEvent(
      type: OptimisticEventType.optimistic,
      id: id,
      key: cacheKey,
    ));

    // 调用服务端
    try {
      final result = await serverAction();
      // 成功 → 移除 pending
      _pendingActions.remove(id);
      _emit(OptimisticEvent(
        type: OptimisticEventType.confirmed,
        id: id,
        key: cacheKey,
      ));
      return result;
    } catch (e) {
      // 失败 → 回滚
      await _rollback<T>(id, cacheConfig);
      _emit(OptimisticEvent(
        type: OptimisticEventType.rolledBack,
        id: id,
        key: cacheKey,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// 去抖执行 — 快速多次点击只执行最后一次
  void debounceExecute<T>({
    required String id,
    required String cacheKey,
    required CacheConfig cacheConfig,
    required T Function(T current) updateFn,
    required Future<T> Function() serverAction,
    T Function()? getInitial,
    Duration debounce = const Duration(milliseconds: 200),
  }) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(debounce, () {
      _debounceTimers.remove(id);
      execute<T>(
        id: id,
        cacheKey: cacheKey,
        cacheConfig: cacheConfig,
        updateFn: updateFn,
        serverAction: serverAction,
        getInitial: getInitial,
      );
    });
  }

  /// 回滚
  Future<void> _rollback<T>(String id, CacheConfig config) async {
    final action = _pendingActions.remove(id) as OptimisticAction<T>?;
    if (action == null) return;
    await cacheService.set<T>(action.cacheKey, action.previousState, config: config);
  }

  /// 离线时排队
  void queueOffline({
    required String type,
    required String action,
    required Map<String, dynamic> data,
  }) {
    _offlineQueue.add({
      'type': type,
      'action': action,
      'data': data,
      'queued_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
    _emit(OptimisticEvent(
      type: OptimisticEventType.queuedOffline,
      id: type,
      key: type,
    ));
  }

  /// 合并同一对象的多次操作 — 只保留最终态 (§6.4)
  void mergeOfflineQueue() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _offlineQueue) {
      final key = '${item['type']}_${item['data']['id']}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    _offlineQueue.clear();
    for (final entries in grouped.values) {
      // 只保留最后一次操作
      _offlineQueue.add(entries.last);
    }
  }

  /// 获取离线队列
  List<Map<String, dynamic>> get offlineQueue => List.unmodifiable(_offlineQueue);

  /// 清空离线队列
  void clearOfflineQueue() {
    _offlineQueue.clear();
  }

  void _emit(OptimisticEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _eventController.close();
  }
}

// ==================== Event ====================

enum OptimisticEventType { optimistic, confirmed, rolledBack, queuedOffline }

class OptimisticEvent {
  final OptimisticEventType type;
  final String id;
  final String key;
  final String? error;

  const OptimisticEvent({
    required this.type,
    required this.id,
    required this.key,
    this.error,
  });

  @override
  String toString() => 'OptimisticEvent($type, id=$id, key=$key${error != null ? ', error=$error' : ''})';
}

// ==================== Global Instance ====================

final optimisticManager = OptimisticUpdateManager();
