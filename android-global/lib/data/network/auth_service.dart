import 'package:dio/dio.dart';
import 'api_client.dart';
import '../storage/storage_manager.dart';

/// 认证服务
class AuthService {
  final ApiClient _client = ApiClient();
  
  /// 登录
  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data;
      
      if (data['token'] != null) {
        // 保存 Token
        await StorageManager.user.saveToken(data['token']);
        await StorageManager.user.saveUserInfo(data['user']);
        await StorageManager.user.setLoggedIn(true);
        
        return ApiResult.success({
          'token': data['token'],
          'user': data['user'],
        });
      }
      
      return ApiResult.failure('Login failed');
    } catch (e) {
      return ApiResult.failure(_handleError(e));
    }
  }
  
  /// 注册
  Future<ApiResult<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      
      final data = response.data;
      
      if (data['token'] != null) {
        await StorageManager.user.saveToken(data['token']);
        await StorageManager.user.saveUserInfo(data['user']);
        await StorageManager.user.setLoggedIn(true);
        
        return ApiResult.success({
          'token': data['token'],
          'user': data['user'],
        });
      }
      
      return ApiResult.failure('Registration failed');
    } catch (e) {
      return ApiResult.failure(_handleError(e));
    }
  }
  
  /// 登出
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {
      // 忽略错误
    } finally {
      await StorageManager.user.clear();
    }
  }
  
  /// Apple Sign-In
  Future<ApiResult<Map<String, dynamic>>> signInWithApple({
    String? identityToken,
    String? authorizationCode,
    String? name,
    String? email,
    String? platform,
    String? deviceId,
  }) async {
    try {
      final response = await _client.post('/api/v1/auth/apple/login', data: {
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
        'name': name,
        'email': email,
        'platform': platform ?? 'ios',
        'device_id': deviceId,
      });
      
      final data = response.data;
      
      if (data['success'] == true && data['token'] != null) {
        // 保存 Token
        await StorageManager.user.saveToken(data['token']);
        await StorageManager.user.saveUserInfo(data['user']);
        await StorageManager.user.setLoggedIn(true);
        
        // 保存 refresh_token
        if (data['refresh_token'] != null) {
          await StorageManager.user.saveRefreshToken(data['refresh_token']);
        }
        
        return ApiResult.success({
          'token': data['token'],
          'refresh_token': data['refresh_token'],
          'user': data['user'],
        });
      }
      
      return ApiResult.failure('Apple sign-in failed');
    } on DioException catch (e) {
      return ApiResult.failure(_handleAppleError(e));
    } catch (e) {
      return ApiResult.failure('Apple sign-in failed: ${e.toString()}');
    }
  }
  
  /// Google Sign-In
  Future<ApiResult<Map<String, dynamic>>> signInWithGoogle({
    required String idToken,
    String? name,
    String? email,
    String? avatarUrl,
    String? platform,
    String? deviceId,
  }) async {
    try {
      final response = await _client.post('/api/v1/auth/google', data: {
        'google_id_token': idToken,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'platform': platform ?? 'ios',
        'device_id': deviceId,
      });
      
      final data = response.data;
      
      if (data['success'] == true && data['token'] != null) {
        await StorageManager.user.saveToken(data['token']);
        await StorageManager.user.saveUserInfo(data['user']);
        await StorageManager.user.setLoggedIn(true);
        
        return ApiResult.success({
          'token': data['token'],
          'refresh_token': data['refresh_token'],
          'user': data['user'],
        });
      }
      
      return ApiResult.failure('Google sign-in failed');
    } on DioException catch (e) {
      return ApiResult.failure(_handleAppleError(e));
    } catch (e) {
      return ApiResult.failure('Google sign-in failed: ${e.toString()}');
    }
  }
  
  String _handleAppleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Network timeout';
      case DioExceptionType.connectionError:
        return 'Network connection failed';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Apple sign-in verification failed';
        } else if (statusCode == 502) {
          return 'Apple service unavailable, please try later';
        }
        return 'Server error: $statusCode';
      default:
        return 'Login failed';
    }
  }
  
  /// 检查登录状态
  Future<bool> checkAuth() async {
    final token = StorageManager.user.getToken();
    if (token == null) return false;
    
    try {
      final response = await _client.get('/auth/me');
      if (response.statusCode == 200) {
        await StorageManager.user.saveUserInfo(response.data);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
  
  /// 自动登录 (从本地存储恢复)
  Future<Map<String, dynamic>?> autoLogin() async {
    if (!StorageManager.user.isLoggedIn()) {
      return null;
    }
    
    final userInfo = StorageManager.user.getUserInfo();
    return userInfo;
  }
  
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Network timeout';
        case DioExceptionType.connectionError:
          return 'Network connection failed';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Wrong username or password';
          } else if (statusCode == 403) {
            return 'Account disabled';
          }
          return 'Server error: $statusCode';
        default:
          return 'Network error';
      }
    }
    return 'Unknown error';
  }
}
