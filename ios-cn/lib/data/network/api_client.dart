import 'package:dio/dio.dart';
import 'dart:io';
import '../storage/storage_manager.dart';

/// API 错误类型
enum ApiErrorType {
  network,
  server,
  unauthorized,
  timeout,
  unknown,
}

/// API 错误
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;
  
  ApiException(this.message, {this.statusCode, this.type = ApiErrorType.unknown});
  
  @override
  String toString() => message;
}

/// 自动检测 baseUrl：模拟器用 10.0.2.2，真机用局域网 IP
class ApiClient {
  // 模拟器地址（Android emulator → host localhost）
  static const _emulatorUrl = 'http://10.0.2.2:4000';
  // 真机：优先公网直连
  static const _realDeviceUrl = 'https://api.shunshi.app';

  static String baseUrl = _realDeviceUrl;
  static bool _detected = true; // 默认用真机IP，不需要检测

  /// 自动检测网络环境（仅模拟器需要）
  static Future<void> detectBaseUrl() async {
    if (_detected) return;
    _detected = true;
    try {
      final socket = await Socket.connect('10.0.2.2', 4000, timeout: const Duration(seconds: 1));
      socket.destroy();
      baseUrl = _emulatorUrl;
    } catch (_) {
      baseUrl = _realDeviceUrl;
    }
  }
  
  late final Dio _dio;
  
  ApiClient() {
    // baseUrl 可能在 main() 中已通过 detectBaseUrl() 设置
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
    ));
    
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // ngrok 免费版跳过浏览器警告
        options.headers['ngrok-skip-browser-warning'] = 'true';
        // 自动添加 Token
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token 过期 → 尝试刷新
          try {
            final refreshToken = StorageManager.user.getRefreshToken();
            if (refreshToken == null) return handler.next(error);
            final resp = await Dio(BaseOptions(baseUrl: baseUrl)).post(
              '/api/v1/auth/refresh',
              data: {'refresh_token': refreshToken},
            );
            if (resp.data is Map && resp.data['data'] != null) {
              final newToken = resp.data['data']['token'] ?? resp.data['data']['access_token'];
              final newRefresh = resp.data['data']['refresh_token'];
              if (newToken != null) {
                await StorageManager.user.saveToken(newToken);
                if (newRefresh != null) await StorageManager.user.saveRefreshToken(newRefresh);
                // 重试原请求
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                return handler.resolve(await _dio.fetch(error.requestOptions));
              }
            }
          } catch (_) {}
        }
        return handler.next(error);
      },
    ));
  }
  
  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    return await _dio.post(path, data: data);
  }
  
  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return await _dio.put(path, data: data);
  }
  
  /// DELETE 请求
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

/// 网络状态
class NetworkStatus {
  final bool isConnected;
  final String? type;
  
  NetworkStatus({required this.isConnected, this.type});
}

/// API 结果
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  
  ApiResult.success(this.data) : success = true, error = null;
  ApiResult.failure(this.error) : success = false, data = null;
}
