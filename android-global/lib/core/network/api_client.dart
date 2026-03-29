import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  
  ApiClient({String? baseUrl, String? authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
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
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('API Request: ${options.method} ${options.path}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('API Response: ${response.statusCode}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('API Error: ${error.message}');
          }
          handler.next(error);
        },
      ),
    );
  }
  
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  // Generic methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }
  
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
  
  // Streaming for AI responses
  Stream<String> streamChat(String prompt, {String? conversationId}) async* {
    final response = await _dio.post<ResponseBody>(
      '/ai/chat/stream',
      data: {
        'prompt': prompt,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      options: Options(responseType: ResponseType.stream),
    );
    
    final stream = response.data?.stream;
    if (stream != null) {
      await for (final chunk in stream) {
        yield String.fromCharCodes(chunk);
      }
    }
  }
}
