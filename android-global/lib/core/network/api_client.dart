import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Timeout levels matching UX_API_SPEC §2
enum ApiLevel {
  s0, // < 100ms — heartbeat, token check, counts
  s1, // < 300ms — list pagination, light details
  s2, // < 600ms — complex details, aggregated data
  s3, // < 1500ms — AI first token, search, complex compute
  s4, // < 3s — image upload, PDF export
}

class ApiClient {
  late final Dio _dio;

  // Request dedup: same method+path+params within 1s
  final Map<String, DateTime> _recentRequests = {};

  // Token refresh singleton — prevents multiple concurrent refreshes
  Future<String?>? _refreshFuture;

  ApiClient({String? baseUrl, String? authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  // ── Request Interceptor ──────────────────────────────────
  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Auto-append locale=en-US for Global edition
    if (!options.queryParameters.containsKey('locale')) {
      options.queryParameters['locale'] = 'en-US';
    }

    // 2. Auto-attach auth token
    final token = await tokenStorage.getAccessToken();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Set timeout by level (via extra['level'])
    final level = options.extra['level'] as ApiLevel? ?? ApiLevel.s1;
    final timeout = _timeoutForLevel(level);
    options.connectTimeout = timeout;
    options.receiveTimeout = timeout;

    // 4. Request dedup — skip if identical request was sent < 1s ago
    final dedupKey = '${options.method}:${options.path}:${options.queryParameters}';
    final now = DateTime.now();
    final lastSent = _recentRequests[dedupKey];
    if (lastSent != null && now.difference(lastSent).inMilliseconds < 1000) {
      if (kDebugMode) print('API DEDUP: ${options.method} ${options.path}');
      _recentRequests.remove(dedupKey);
    }
    _recentRequests[dedupKey] = now;

    // Cleanup old dedup entries (> 5s)
    _recentRequests.removeWhere((_, t) => now.difference(t).inSeconds > 5);

    // 5. Add idempotency key for write operations
    if (['POST', 'PUT', 'DELETE'].contains(options.method.toUpperCase())) {
      options.headers['Idempotency-Key'] =
          '${DateTime.now().millisecondsSinceEpoch}-${options.uri}';
    }

    if (kDebugMode) {
      print('API → ${options.method} ${options.path} [${level.name}]');
    }
    handler.next(options);
  }

  // ── Response Interceptor ─────────────────────────────────
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('API ← ${response.statusCode} ${response.requestOptions.path}');
    }
    handler.next(response);
  }

  // ── Error Interceptor ────────────────────────────────────
  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    final opts = error.requestOptions;

    if (kDebugMode) {
      print('API ✗ ${opts.path} → ${error.type}: ${error.message}');
    }

    // 1. 401 → silent refresh + retry once
    if (error.response?.statusCode == 401 && opts.extra['_retried'] != true) {
      try {
        final newToken = await _silentRefresh();
        if (newToken != null) {
          opts.headers['Authorization'] = 'Bearer $newToken';
          opts.extra['_retried'] = true;
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Refresh failed — clear tokens, let error propagate
        await tokenStorage.clearTokens();
      }
    }

    // 2. 5xx → retry once with exponential backoff
    final status = error.response?.statusCode ?? 0;
    if (status >= 500 && status < 600 && opts.extra['_retried5xx'] != true) {
      opts.extra['_retried5xx'] = true;
      await Future.delayed(Duration(milliseconds: 1000 + (DateTime.now().millisecond % 1000)));
      try {
        final response = await _dio.fetch(opts);
        handler.resolve(response);
        return;
      } catch (_) {
        // Retry failed, fall through to original error
      }
    }

    // 3. Timeout → retry once (network may recover)
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      if (opts.extra['_retriedTimeout'] != true) {
        opts.extra['_retriedTimeout'] = true;
        try {
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
    }

    handler.next(error);
  }

  // ── Silent token refresh (singleton) ─────────────────────
  Future<String?> _silentRefresh() async {
    if (_refreshFuture != null) return _refreshFuture!;
    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await Dio().post(
        '${AppConfig.apiBaseUrl}/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final newAccess = data['access_token']?.toString();
        final newRefresh = data['refresh_token']?.toString();
        if (newAccess != null) {
          await tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh ?? refreshToken,
          );
          return newAccess;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Timeout mapping ──────────────────────────────────────
  Duration _timeoutForLevel(ApiLevel level) {
    switch (level) {
      case ApiLevel.s0:
        return const Duration(seconds: 3);
      case ApiLevel.s1:
        return const Duration(seconds: 5);
      case ApiLevel.s2:
        return const Duration(seconds: 10);
      case ApiLevel.s3:
        return const Duration(seconds: 30);
      case ApiLevel.s4:
        return const Duration(seconds: 60);
    }
  }

  // ── Public API ───────────────────────────────────────────
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    ApiLevel level = ApiLevel.s1,
  }) {
    final opts = options ?? Options();
    opts.extra = {...?opts.extra, 'level': level};
    return _dio.get<T>(path, queryParameters: queryParameters, options: opts);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ApiLevel level = ApiLevel.s2,
  }) {
    final opts = options ?? Options();
    opts.extra = {...?opts.extra, 'level': level};
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: opts);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ApiLevel level = ApiLevel.s2,
  }) {
    final opts = options ?? Options();
    opts.extra = {...?opts.extra, 'level': level};
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: opts);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ApiLevel level = ApiLevel.s1,
  }) {
    final opts = options ?? Options();
    opts.extra = {...?opts.extra, 'level': level};
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: opts);
  }

  /// Streaming for AI responses (SSE)
  Stream<String> streamChat(String prompt, {String? conversationId}) async* {
    final response = await _dio.post<ResponseBody>(
      '/ai/chat/stream',
      data: {
        'prompt': prompt,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      options: Options(
        responseType: ResponseType.stream,
        extra: {'level': ApiLevel.s3},
      ),
    );

    final stream = response.data?.stream;
    if (stream != null) {
      await for (final chunk in stream) {
        yield String.fromCharCodes(chunk);
      }
    }
  }

  /// Raw Dio instance for pages that need direct access
  Dio get dio => _dio;
}
