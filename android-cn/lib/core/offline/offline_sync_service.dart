// Offline Sync Service
// Handles syncing queued requests when network is available

import 'dart:async';
import 'package:dio/dio.dart';
import '../network/network_service.dart';
import '../storage/local_storage.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  
  final _dio = Dio();
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  StreamController<SyncStatus>? _statusController;
  Stream<SyncStatus>? _statusStream;
  
  OfflineSyncService._internal();
  
  Stream<SyncStatus> get statusStream {
    _statusController ??= StreamController<SyncStatus>.broadcast();
    _statusStream ??= _statusController!.stream;
    return _statusStream!;
  }
  
  // Start listening for network recovery
  void startAutoSync() {
    // Listen to network status changes
    networkService.statusStream.listen((status) async {
      if (status == NetworkStatus.online) {
        await syncPendingRequests();
      }
    });
    
    // Periodic sync check (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (await networkService.isOnline()) {
        await syncPendingRequests();
      }
    });
  }
  
  // Stop auto sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sync all pending requests
  Future<SyncResult> syncPendingRequests() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }
    
    _isSyncing = true;
    _statusController?.add(SyncStatus.syncing);
    
    final queue = await localStorage.getOfflineQueue();
    if (queue.isEmpty) {
      _isSyncing = false;
      _statusController?.add(SyncStatus.idle);
      return SyncResult(
        success: true,
        message: 'No pending requests',
        syncedCount: 0,
      );
    }
    
    int successCount = 0;
    int failCount = 0;
    final failedRequests = <Map<String, dynamic>>[];
    
    for (final request in queue) {
      try {
        final method = request['method'] as String;
        final path = request['path'] as String;
        final data = request['data'];
        final requestId = request['requestId'] as String;
        
        Response response;
        
        switch (method) {
          case 'POST':
            response = await _dio.post(path, data: data);
            break;
          case 'PUT':
            response = await _dio.put(path, data: data);
            break;
          case 'DELETE':
            response = await _dio.delete(path, data: data);
            break;
          default:
            continue;
        }
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount++;
          await localStorage.removeFromOfflineQueue(requestId);
        } else {
          failCount++;
          failedRequests.add(request);
        }
      } catch (e) {
        failCount++;
        failedRequests.add(request);
      }
    }
    
    _isSyncing = false;
    
    if (failCount > 0) {
      _statusController?.add(SyncStatus.error);
    } else {
      _statusController?.add(SyncStatus.completed);
    }
    
    return SyncResult(
      success: failCount == 0,
      message: failCount == 0 
          ? 'All requests synced' 
          : '$failCount requests failed',
      syncedCount: successCount,
      failedCount: failCount,
    );
  }
  
  // Get pending request count
  Future<int> getPendingCount() async {
    final queue = await localStorage.getOfflineQueue();
    return queue.length;
  }
  
  // Clear all pending requests (use with caution)
  Future<void> clearPendingRequests() async {
    await localStorage.clearOfflineQueue();
    _statusController?.add(SyncStatus.idle);
  }
  
  void dispose() {
    _syncTimer?.cancel();
    _statusController?.close();
  }
}

// ==================== Sync Status ====================

enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  
  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}

// Global instance
final offlineSyncService = OfflineSyncService();
