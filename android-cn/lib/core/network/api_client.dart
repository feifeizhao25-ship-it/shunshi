// ApiClient V2 — UX_API_SPEC §2 + §10.6 + §11
// 速度分级超时 / 401 静默 refresh 单飞 / 5xx 指数退避重试 / 请求去重 / 幂等 key
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

// ==================== Speed Level ====================

/// API 速度分级 (UX_API_SPEC §2.1)
enum SpeedLevel {
  s0, // < 100ms — 心跳、token校验、计数
  s1, // < 300ms — 列表分页、轻量详情
  s2, // < 600ms — 复杂详情、聚合数据
  s3, // < 1500ms — AI首字、复杂计算、搜索
  s4, // < 3s — 上传图片、导出PDF
  s5, // > 3s — 大文件、视频转码
}

/// 各级别超时配置 (UX_API_SPEC §2.4)
const _timeoutByLevel = {
  SpeedLevel.s0: Duration(seconds: 3),
  SpeedLevel.s1: Duration(seconds: 5),
  SpeedLevel.s2: Duration(seconds: 10),
  SpeedLevel.s3: Duration(seconds: 30),
  SpeedLevel.s4: Duration(seconds: 60),
  SpeedLevel.s5: Duration(seconds: 120),
};

/// 各级别 p95 目标 (ms)
const _p95TargetByLevel = {
  SpeedLevel.s0: 100,
  SpeedLevel.s1: 300,
  SpeedLevel.s2: 600,
  SpeedLevel.s3: 1500,
  SpeedLevel.s4: 3000,
  SpeedLevel.s5: 10000,
};

// ==================== Request Deduplication ====================

/// 请求去重器 — 同接口 1 秒内去重 (UX_API_SPEC §0.4 #6)
class _RequestDeduplicator {
  final Map<String, Completer<Response>> _pending = {};

  String _key(String method, String path, Map<String, dynamic>? params) {
    final paramStr =
        params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$method:$path:$paramStr';
  }

  /// 如果有相同的进行中请求，返回其 future；否则返回 null
  Future<Response>? getExisting(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) {
    final key = _key(method, path, params);
    final pending = _pending[key];
    if (pending != null && !pending.isCompleted) {
      return pending.future;
    }
    return null;
  }

  /// 注册一个进行中的请求
  Completer<Response> register(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) {
    final key = _key(method, path, params);
    final completer = Completer<Response>();
    _pending[key] = completer;
    return completer;
  }

  /// 完成后移除
  void complete(String method, String path, Map<String, dynamic>? params) {
    final key = _key(method, path, params);
    _pending.remove(key);
  }
}

// ==================== API Client ====================

class ApiClient {
  late final Dio _dio;
  final _deduplicator = _RequestDeduplicator();

  // 401 单飞: 多个并发 401 只 refresh 一次 (UX_API_SPEC §10.6)
  Completer<String>? _refreshCompleter;

  // 重试配置 (UX_API_SPEC §11.1)
  static const _maxRetry5xx = 2; // 5xx 最多重试 2 次
  static const _maxRetryTimeout = 1; // 超时最多重试 1 次

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  // ==================== Request Interceptor ====================

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. 自动加 token
    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 2. 根据速度级别设置超时 (UX_API_SPEC §2.4)
    final level = _extractLevel(options);
    final timeout = _timeoutByLevel[level]!;
    options.connectTimeout = timeout;
    options.receiveTimeout = timeout;
    options.sendTimeout = timeout;

    // 3. 写操作加幂等 key (UX_API_SPEC §11.4)
    final method = options.method.toUpperCase();
    if (['POST', 'PUT', 'DELETE'].contains(method)) {
      options.headers['Idempotency-Key'] = _generateIdempotencyKey();
    }

    // 4. 链路追踪 ID
    options.headers['X-Request-Id'] = _generateTraceId();

    // 5. 记录请求开始时间（用于性能追踪）
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    options.extra['level'] = level.name;

    if (kDebugMode) {
      print('→ ${options.method} ${options.path} [${level.name}]');
    }

    handler.next(options);
  }

  // ==================== Response Interceptor ====================

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['startTime'] as int? ?? 0;
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final level = response.requestOptions.extra['level'] as String? ?? 's1';
    final p95 = _p95TargetByLevel[_parseLevel(level)] ?? 300;

    if (kDebugMode) {
      final warn = duration > p95 ? ' ⚠️ SLOW' : '';
      print(
        '← ${response.statusCode} ${response.requestOptions.path} ${duration}ms [$level]$warn',
      );
    }

    // 性能埋点钩子 — 外部可订阅
    _performanceCallback?.call(
      PerformanceEvent(
        endpoint: response.requestOptions.path,
        method: response.requestOptions.method,
        statusCode: response.statusCode ?? 0,
        durationMs: duration,
        level: level,
        cacheHit: false,
      ),
    );

    handler.next(response);
  }

  // ==================== Error Interceptor ====================

  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    final options = error.requestOptions;
    final retryCount = options.extra['retryCount'] as int? ?? 0;

    // §10.6: 401 → 静默 refresh + 重试原请求（单飞模式）
    if (error.response?.statusCode == 401) {
      final refreshed = await _silentRefresh();
      if (refreshed != null) {
        options.headers['Authorization'] = 'Bearer $refreshed';
        try {
          final response = await _dio.fetch(options);
          handler.resolve(response);
          return;
        } catch (_) {
          // refresh 后重试仍然失败 → 走正常错误处理
        }
      } else {
        // refresh 失败 → 清除认证 → 跳登录
        await tokenStorage.clearTokens();
        _authExpiredCallback?.call();
      }
    }

    // §11.1: 5xx → 自动重试 2 次，指数退避 + 抖动
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500 &&
        retryCount < _maxRetry5xx) {
      final delay = _retryDelay(retryCount);
      await Future.delayed(delay);
      options.extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        handler.next(
          e is DioException
              ? e
              : DioException(requestOptions: options, error: e),
        );
        return;
      }
    }

    // §11.1: 网络超时 → 重试 1 次
    if (_isTimeoutError(error) && retryCount < _maxRetryTimeout) {
      options.extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        handler.next(
          e is DioException
              ? e
              : DioException(requestOptions: options, error: e),
        );
        return;
      }
    }

    // §10.3: 429 → 不重试
    if (error.response?.statusCode == 429) {
      final body = error.response?.data;
      final retryAfter = body is Map ? body['retry_after_seconds'] ?? 60 : 60;
      error = DioException(
        requestOptions: options,
        response: error.response,
        error: 'RATE_LIMITED:$retryAfter',
        type: DioExceptionType.badResponse,
      );
    }

    if (kDebugMode) {
      print(
        '✗ ${options.method} ${options.path} ${error.message} (retry=$retryCount)',
      );
    }

    handler.next(error);
  }

  // ==================== 401 Silent Refresh (Single-Flight) ====================

  /// 静默刷新 token，多个并发 401 只触发一次 (UX_API_SPEC §10.6)
  Future<String?> _silentRefresh() async {
    // 如果已经有正在进行的 refresh，等待它
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      try {
        return _refreshCompleter!.future;
      } catch (_) {
        return null;
      }
    }

    _refreshCompleter = Completer<String>();

    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.completeError('No refresh token');
        return null;
      }

      // 用独立的 Dio 实例发 refresh，避免拦截器循环
      final dio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 3),
        ),
      );
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data is Map && data['access_token'] != null) {
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken =
            data['refresh_token'] as String? ?? refreshToken;

        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      }

      _refreshCompleter!.completeError('Invalid refresh response');
      return null;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      return null;
    } finally {
      // 延迟清理，让等待的并发请求拿到结果
      Future.delayed(const Duration(seconds: 1), () {
        _refreshCompleter = null;
      });
    }
  }

  // ==================== Public API ====================

  /// Accept both legacy `/api/v1/...` paths and concise `/...` paths while
  /// keeping API_BASE_URL an origin. This prevents missing or duplicated
  /// version prefixes across mobile and Web release builds.
  String _versionedPath(String path) {
    if (path == '/api/v1' || path.startsWith('/api/v1/')) return path;
    return '/api/v1${path.startsWith('/') ? path : '/$path'}';
  }

  /// GET 请求（带请求去重）
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    SpeedLevel level = SpeedLevel.s1,
  }) async {
    // 请求去重 (GET only)
    final existing = _deduplicator.getExisting('GET', path, queryParameters);
    if (existing != null) {
      return existing as Future<Response<T>>;
    }

    final completer = _deduplicator.register('GET', path, queryParameters);
    try {
      final opts = options ?? Options();
      opts.extra ??= {};
      opts.extra!['speedLevel'] = level;

      final response = await _dio.get<T>(
        _versionedPath(path),
        queryParameters: queryParameters,
        options: opts,
      );
      completer.complete(response);
      _deduplicator.complete('GET', path, queryParameters);
      return response;
    } catch (e) {
      _deduplicator.complete('GET', path, queryParameters);
      rethrow;
    }
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    SpeedLevel level = SpeedLevel.s1,
  }) async {
    final opts = options ?? Options();
    opts.extra ??= {};
    opts.extra!['speedLevel'] = level;
    return _dio.post<T>(
      _versionedPath(path),
      data: data,
      queryParameters: queryParameters,
      options: opts,
    );
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    SpeedLevel level = SpeedLevel.s1,
  }) async {
    final opts = options ?? Options();
    opts.extra ??= {};
    opts.extra!['speedLevel'] = level;
    return _dio.put<T>(
      _versionedPath(path),
      data: data,
      queryParameters: queryParameters,
      options: opts,
    );
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    SpeedLevel level = SpeedLevel.s1,
  }) async {
    final opts = options ?? Options();
    opts.extra ??= {};
    opts.extra!['speedLevel'] = level;
    return _dio.delete<T>(
      _versionedPath(path),
      data: data,
      queryParameters: queryParameters,
      options: opts,
    );
  }

  /// SSE 流式请求 (UX_API_SPEC §7)
  /// 返回原始 ResponseBody stream，由调用方处理 SSE event lines
  Future<ResponseBody> streamPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final opts = Options(
      responseType: ResponseType.stream,
      extra: {'speedLevel': SpeedLevel.s3},
      headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
    );
    final response = await _dio.post<ResponseBody>(
      _versionedPath(path),
      data: data,
      queryParameters: queryParameters,
      options: opts,
    );
    return response.data!;
  }

  /// 更新 auth token（登录后调用）
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// 清除 auth token（登出时调用）
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ==================== Callbacks ====================

  /// 认证过期回调 — 由 App 层注册跳转登录页
  static void Function()? _authExpiredCallback;
  static void setAuthExpiredCallback(void Function() callback) {
    _authExpiredCallback = callback;
  }

  /// 性能事件回调 — 由 App 层注册上报埋点
  static void Function(PerformanceEvent)? _performanceCallback;
  static void setPerformanceCallback(void Function(PerformanceEvent) callback) {
    _performanceCallback = callback;
  }

  // ==================== Helpers ====================

  SpeedLevel _extractLevel(RequestOptions options) {
    final levelStr = options.extra['speedLevel'];
    if (levelStr is SpeedLevel) return levelStr;
    return SpeedLevel.s1; // 默认 S1
  }

  SpeedLevel _parseLevel(String name) {
    return SpeedLevel.values.firstWhere(
      (l) => l.name == name,
      orElse: () => SpeedLevel.s1,
    );
  }

  bool _isTimeoutError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  /// 指数退避 + 抖动 (UX_API_SPEC §11.2)
  Duration _retryDelay(int attempt) {
    const baseMs = 1000;
    final exp = 1 << attempt; // 1, 2, 4...
    final jitter = 0.3 * DateTime.now().microsecond / 1000000; // 0-30%
    final delay = (baseMs * exp * (1 + jitter)).round();
    return Duration(milliseconds: delay.clamp(1000, 30000));
  }

  String _generateIdempotencyKey() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }

  String _generateTraceId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = DateTime.now().microsecond.toRadixString(36);
    return 'req_$ts$rand';
  }
}

// ==================== Performance Event ====================

class PerformanceEvent {
  final String endpoint;
  final String method;
  final int statusCode;
  final int durationMs;
  final String level;
  final bool cacheHit;

  const PerformanceEvent({
    required this.endpoint,
    required this.method,
    required this.statusCode,
    required this.durationMs,
    required this.level,
    required this.cacheHit,
  });

  @override
  String toString() =>
      '$method $endpoint → $statusCode ${durationMs}ms [$level] cache=$cacheHit';
}
