import 'package:flutter/foundation.dart';

/// 性能监控服务
/// 简化版 - 后续可集成 firebase_performance
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _traces = {};

  /// 初始化
  Future<void> init() async {
    if (kDebugMode) {
      print('[Performance] Service initialized');
    }
    // 后续可集成:
    // await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }

  /// 开始追踪
  void startTrace(String name) {
    _traces[name] = DateTime.now();
    if (kDebugMode) {
      print('[Performance] Start trace: $name');
    }
  }

  /// 结束追踪
  Future<void> stopTrace(String name) async {
    final startTime = _traces[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _traces.remove(name);
      
      if (kDebugMode) {
        print('[Performance] Trace $name: ${duration.inMilliseconds}ms');
      }
      
      // 后续可集成:
      // final trace = await FirebasePerformance.instance.newTrace(name);
      // await trace.start();
      // await trace.stop();
    }
  }

  /// 记录 HTTP 请求
  Future<void> logHttpRequest({
    required String url,
    required String method,
    required int responseCode,
    required int requestSize,
    required int responseSize,
    required int duration,
  }) async {
    if (kDebugMode) {
      print('[Performance] HTTP $method $url - $responseCode (${duration}ms)');
    }
  }

  /// 记录屏幕渲染时间
  void logScreenRender(String screenName, int durationMs) {
    if (kDebugMode) {
      print('[Performance] Screen $screenName rendered in ${durationMs}ms');
    }
  }
}

/// 网络性能追踪
class HttpTracer {
  final String url;
  final String method;
  final DateTime startTime;
  int? _responseCode;
  int? _requestSize;
  int? _responseSize;

  HttpTracer({required this.url, required this.method})
      : startTime = DateTime.now();

  void setResponseCode(int code) => _responseCode = code;
  void setRequestSize(int size) => _requestSize = size;
  void setResponseSize(int size) => _responseSize = size;

  Future<void> stop() async {
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    await PerformanceService().logHttpRequest(
      url: url,
      method: method,
      responseCode: _responseCode ?? 0,
      requestSize: _requestSize ?? 0,
      responseSize: _responseSize ?? 0,
      duration: duration,
    );
  }
}
