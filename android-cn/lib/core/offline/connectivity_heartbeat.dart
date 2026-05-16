// Connectivity Heartbeat — UX_API_SPEC §12.2
// 心跳检测 / 离线状态管理 / 同步队列增强
import 'dart:async';

// ==================== Offline Heartbeat (§12.2) ====================

/// 离线检测器 — 心跳 + 失败计数
class OfflineDetector {
  Timer? _heartbeatTimer;
  int _consecutiveFailures = 0;
  static const _offlineThreshold = 3; // 3 次失败 = 离线
  static const _heartbeatInterval = Duration(seconds: 60); // 60s 心跳

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onlineStatus => _statusController.stream;

  /// 开始心跳
  void startHeartbeat({
    required Future<bool> Function() healthCheck,
  }) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        final healthy = await healthCheck();
        if (healthy) {
          _onSuccess();
        } else {
          _onFailure();
        }
      } catch (_) {
        _onFailure();
      }
    });
  }

  /// 手动报告成功（任何 API 成功都算）
  void reportSuccess() {
    _onSuccess();
  }

  /// 手动报告失败
  void reportFailure() {
    _onFailure();
  }

  void _onSuccess() {
    _consecutiveFailures = 0;
    if (!_isOnline) {
      _isOnline = true;
      _statusController.add(true);
    }
  }

  void _onFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _offlineThreshold && _isOnline) {
      _isOnline = false;
      _statusController.add(false);
    }
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _statusController.close();
  }
}

// ==================== Enhanced Sync Queue (§12.3) ====================

/// 同步队列项
class SyncQueueItem {
  final String id;
  final String type; // 'favorite' | 'journal' | 'checkin'
  final String action; // 'create' | 'update' | 'delete'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  static const maxRetry = 5;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.action,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDead => retryCount >= maxRetry;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'action': action,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'retry_count': retryCount,
  };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
    id: map['id'] as String,
    type: map['type'] as String,
    action: map['action'] as String,
    data: map['data'] as Map<String, dynamic>,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    retryCount: map['retry_count'] as int? ?? 0,
  );
}

/// 增强同步队列
class EnhancedSyncQueue {
  final List<SyncQueueItem> _queue = [];
  final List<SyncQueueItem> _deadLetterQueue = [];

  List<SyncQueueItem> get pending => List.unmodifiable(_queue);
  List<SyncQueueItem> get deadLetters => List.unmodifiable(_deadLetterQueue);
  int get pendingCount => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  /// 入队
  void enqueue(SyncQueueItem item) {
    _queue.add(item);
  }

  /// 合并同一对象的多次操作 (§6.4)
  /// 只保留最终态
  void mergeDuplicates() {
    final grouped = <String, List<SyncQueueItem>>{};
    for (final item in _queue) {
      final key = '${item.type}_${item.data['id']}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    // create + delete → 互消，移除
    // 多次操作 → 只保留最后一次
    _queue.clear();
    for (final items in grouped.values) {
      if (items.length == 2) {
        final first = items.first;
        final last = items.last;
        // create → delete = 互消
        if (first.action == 'create' && last.action == 'delete') {
          continue;
        }
      }
      _queue.add(items.last);
    }
  }

  /// 标记重试
  void markRetry(String id) {
    final idx = _queue.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final item = _queue[idx];
    item.retryCount++;
    if (item.isDead) {
      _queue.removeAt(idx);
      _deadLetterQueue.add(item);
    }
  }

  /// 移除（同步成功）
  void remove(String id) {
    _queue.removeWhere((i) => i.id == id);
  }

  /// 清空死信队列
  void clearDeadLetters() {
    _deadLetterQueue.clear();
  }

  /// 清空所有
  void clearAll() {
    _queue.clear();
    _deadLetterQueue.clear();
  }
}

// ==================== Global Instances ====================

final offlineDetector = OfflineDetector();
