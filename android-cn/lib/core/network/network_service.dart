// Network Service
// Handles API requests with retry, offline detection, and error handling

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../storage/local_storage.dart';

enum NetworkStatus {
  online,
  offline,
  unknown,
}

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  
  late final Dio _dio;
  final Connectivity _connectivity = Connectivity();
  
  // Network status stream
  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  NetworkStatus get currentStatus => _currentStatus;
  
  NetworkService._internal() {
    _dio = _createDio();
    _initConnectivity();
  }
  
  Dio get client => _dio;
  
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.shunshi.cn/v1',
      ),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
    
    // Add interceptors
    dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(),
      _OfflineInterceptor(),
      _LoggingInterceptor(),
    ]);
    
    return dio;
  }
  
  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _currentStatus = result == ConnectivityResult.none 
          ? NetworkStatus.offline 
          : NetworkStatus.online;
      _statusController.add(_currentStatus);
    });
    
    // Check initial status
    _connectivity.checkConnectivity().then((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _currentStatus = result == ConnectivityResult.none 
          ? NetworkStatus.offline 
          : NetworkStatus.online;
      _statusController.add(_currentStatus);
    });
  }
  
  // Check if online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    return result != ConnectivityResult.none;
  }
  
  // Force refresh connectivity status
  Future<void> refreshStatus() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _currentStatus = result == ConnectivityResult.none 
        ? NetworkStatus.offline 
        : NetworkStatus.online;
    _statusController.add(_currentStatus);
  }
  
  void dispose() {
    _statusController.close();
  }
}

// ==================== Auth Interceptor ====================

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      final refreshed = await tokenStorage.refreshToken((refreshToken) async {
        // Call refresh endpoint
        final dio = Dio();
        final baseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.shunshi.cn/v1',
        );
        final response = await dio.post(
          '$baseUrl/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        return response.data as Map<String, String>;
      });
      
      if (refreshed) {
        // Retry the original request
        try {
          final token = await tokenStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh failed, clear tokens
        await tokenStorage.clearTokens();
      }
    }
    handler.next(err);
  }
}

// ==================== Retry Interceptor ====================

class _RetryInterceptor extends Interceptor {
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 1);
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;
    
    // Only retry on network errors or 5xx errors
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode ?? 0) >= 500;
    
    if (shouldRetry && retryCount < _maxRetries) {
      // Wait before retrying
      await Future.delayed(_retryDelay * (retryCount + 1));
      
      // Update retry count
      options.extra['retryCount'] = retryCount + 1;
      
      try {
        final dio = Dio();
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }
    
    handler.next(err);
  }
}

// ==================== Offline Interceptor ====================

class _OfflineInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final networkService = NetworkService();
    final isOnline = await networkService.isOnline();
    
    if (!isOnline && options.extra['offlineMode'] != 'disabled') {
      // Check if request supports offline
      if (options.extra['offlineQueue'] == true) {
        // Queue the request for later
        await localStorage.addToOfflineQueue({
          'method': options.method,
          'path': options.path,
          'data': options.data,
          'queryParams': options.queryParameters,
          'requestId': options.hashCode.toString(),
        });
        
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Request queued for offline sync',
          ),
          true,
        );
      }
    }
    
    handler.next(options);
  }
}

// ==================== Logging Interceptor ====================

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('📤 [API] ${options.method} ${options.path}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('📥 [API] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ [API] ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}

// Global instance
final networkService = NetworkService();
