import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const int _connectTimeout = 10000; // 10s
  static const int _receiveTimeout = 30000; // 30s
  static const int _maxRetries = 2;

  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient({required String baseUrl, String? apiKey}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: _connectTimeout),
      receiveTimeout: const Duration(milliseconds: _receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (apiKey != null) 'X-API-Key': apiKey,
      },
    ));
    _dio.interceptors.addAll([
      _RetryInterceptor(dio: _dio, maxRetries: _maxRetries, logger: _logger),
      _LoggingInterceptor(logger: _logger),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Retry interceptor with exponential backoff (max 2 retries)
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Logger logger;

  _RetryInterceptor({
    required this.dio,
    required this.maxRetries,
    required this.logger,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retries = extra['retries'] as int? ?? 0;

    final isRetriable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);

    if (isRetriable && retries < maxRetries) {
      logger.w('Retry ${retries + 1}/$maxRetries for ${err.requestOptions.path}');
      final delay = Duration(milliseconds: 500 * (retries + 1));
      await Future.delayed(delay);

      try {
        final opts = err.requestOptions;
        opts.extra['retries'] = retries + 1;
        final response = await dio.fetch(opts);
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to next retry or error
      }
    }

    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  final Logger logger;

  _LoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('✗ ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}
