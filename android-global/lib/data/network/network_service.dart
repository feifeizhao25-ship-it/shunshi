import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络状态监听服务
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  
  StreamController<bool>? _streamController;
  
  /// 初始化网络监听
  void init() {
    _streamController = StreamController<bool>.broadcast();
    
    _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.isNotEmpty && 
          results.any((r) => r != ConnectivityResult.none);
      _streamController?.add(isConnected);
    });
  }
  
  /// 监听网络状态变化
  Stream<bool> get onNetworkChanged => _streamController?.stream ?? const Stream.empty();
  
  /// 检查当前网络状态
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && 
        results.any((r) => r != ConnectivityResult.none);
  }
  
  /// 获取网络类型
  Future<String> getNetworkType() async {
    final results = await _connectivity.checkConnectivity();
    
    if (results.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile Network';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'Wired Network';
    }
    return 'No Network';
  }
  
  void dispose() {
    _streamController?.close();
  }
}

/// Retry机制
class RetryHelper {
  /// 带Retry的请求
  static Future<T> retry<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
  }
}
