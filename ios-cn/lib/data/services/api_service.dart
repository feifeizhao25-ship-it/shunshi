import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../storage/storage_manager.dart';

/// API 服务 (增强版 - 带重试和离线支持)
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
  ));
  
  // 重试次数
  static const int maxRetries = 2;
  
  ApiService() {
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 自动添加 Token
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 处理错误 - 超时
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '网络连接超时，请检查网络后重试',
              type: DioExceptionType.connectionTimeout,
            ),
          );
        }
        
        // 处理错误 - 断网
        if (error.type == DioExceptionType.connectionError) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '网络连接失败，请检查网络设置',
              type: DioExceptionType.connectionError,
            ),
          );
        }
        
        // 处理 401 - Token 过期
        if (error.response?.statusCode == 401) {
          // 清除本地 Token
          StorageManager.user.clearToken();
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '登录已过期，请重新登录',
              type: DioExceptionType.badResponse,
              response: error.response,
            ),
          );
        }
        
        // 处理 403 - 权限不足
        if (error.response?.statusCode == 403) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '权限不足，无法访问该资源',
              type: DioExceptionType.badResponse,
              response: error.response,
            ),
          );
        }
        
        // 处理 429 - 请求过于频繁
        if (error.response?.statusCode == 429) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '请求过于频繁，请稍后重试',
              type: DioExceptionType.badResponse,
              response: error.response,
            ),
          );
        }
        
        // 处理 500+ 服务器错误
        if (error.response?.statusCode != null && 
            error.response!.statusCode! >= 500) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: '服务器错误，请稍后重试',
              type: DioExceptionType.badResponse,
              response: error.response,
            ),
          );
        }
        
        return handler.next(error);
      },
    ));
  }
  
  /// 带重试的请求
  Future<T> _requestWithRetry<T>(
    Future<T> Function() request,
  ) async {
    int attempts = 0;
    
    while (true) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }
  
  // ==================== 路由 ====================
  
  /// 模型路由
  Future<Map<String, dynamic>> route({
    required String userId,
    required String userTier,
    required String apiPath,
    required String prompt,
    String? skillName,
    int contextLength = 0,
  }) async {
    try {
      final response = await _dio.post('/route', data: {
        'user_id': userId,
        'user_tier': userTier,
        'api_path': apiPath,
        'prompt': prompt,
        'skill_name': skillName,
        'context_length': contextLength,
      });
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // ==================== 对话 ====================
  
  /// 发送消息
  /// 后端接口: POST /api/v1/chat?message=xxx&user_id=xxx&conversation_id=xxx
  Future<Map<String, dynamic>> chat({
    required String userId,
    required String message,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      };
      final response = await _dio.post(
        '/api/v1/chat',
        queryParameters: queryParams,
        data: context != null ? {'context': context} : {},
      );
      return response.data;
    } catch (e) {
      return {'error': e.toString(), 'message': '连接失败，请稍后重试'};
    }
  }
  
  // ==================== 统计 ====================
  
  /// 获取统计
  Future<Map<String, dynamic>> stats() async {
    try {
      final response = await _dio.get('/stats');
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // ==================== 模型 ====================
  
  /// 获取模型列表
  Future<List<dynamic>> models() async {
    try {
      final response = await _dio.get('/models');
      return response.data['models'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  // ==================== Prompts ====================
  
  /// 获取 Prompt 列表
  Future<List<dynamic>> listPrompts() async {
    try {
      final response = await _dio.get('/prompts');
      return response.data['prompts'] ?? [];
    } catch (e) {
      return [];
    }
  }
}

/// 用户服务 — 对接 /api/v1/auth/* 后端 API
class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
  ));

  Map<String, dynamic>? _currentUser;

  UserService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// 登录
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return {'error': '请输入邮箱和密码'};
    }
    try {
      final res = await _dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (res.data is Map && res.data['success'] == true) {
        _currentUser = res.data['data']?['user'] as Map<String, dynamic>?;
        final token = res.data['data']?['token'];
        if (token != null) StorageManager.user.saveToken(token);
        return res.data as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '登录失败: $e'};
    }
  }

  /// 注册
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return {'error': '请填写完整信息'};
    }
    try {
      final res = await _dio.post('/api/v1/auth/register', data: {
        'username': name,
        'email': email,
        'password': password,
      });
      if (res.data is Map && res.data['success'] == true) {
        _currentUser = res.data['data']?['user'] as Map<String, dynamic>?;
        final token = res.data['data']?['token'];
        if (token != null) StorageManager.user.saveToken(token);
        return res.data as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '注册失败: $e'};
    }
  }

  /// 获取当前用户
  Map<String, dynamic>? getCurrentUser() => _currentUser;

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      final res = await _dio.get('/api/v1/auth/profile',
          queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return _currentUser ?? {'id': userId, 'name': '用户', 'subscription_type': 'free'};
    }
  }

  /// 更新用户信息
  Future<Map<String, dynamic>> updateUserInfo(String userId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/api/v1/auth/profile', data: {
        'user_id': userId,
        ...data,
      });
      if (res.data is Map && res.data['success'] == true) {
        _currentUser?.addAll(data);
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '更新失败: $e'};
    }
  }

  /// 登出
  void logout() {
    _currentUser = null;
    StorageManager.user.clearToken();
  }

  /// Google 登录
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    String? deviceId,
    String? platform,
  }) async {
    try {
      final res = await _dio.post('/api/v1/auth/google', data: {
        'google_id_token': idToken,
        if (deviceId != null) 'device_id': deviceId,
        if (platform != null) 'platform': platform,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Google 登录失败: $e'};
    }
  }

  /// Apple 登录
  Future<Map<String, dynamic>> appleLogin({
    required String identityToken,
    String? authorizationCode,
    String? name,
    String? deviceId,
    String? platform,
  }) async {
    try {
      final res = await _dio.post('/api/v1/auth/apple', data: {
        'identity_token': identityToken,
        if (authorizationCode != null) 'authorization_code': authorizationCode,
        if (name != null) 'name': name,
        if (deviceId != null) 'device_id': deviceId,
        if (platform != null) 'platform': platform,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Apple 登录失败: $e'};
    }
  }

  /// 游客登录
  Future<Map<String, dynamic>> guestLogin({
    String? deviceId,
    String? platform,
  }) async {
    try {
      final res = await _dio.post('/api/v1/auth/guest-login', data: {
        if (deviceId != null) 'device_id': deviceId,
        if (platform != null) 'platform': platform,
      });
      if (res.data is Map && res.data['success'] == true) {
        _currentUser = res.data['data']?['user'] as Map<String, dynamic>?;
        final token = res.data['data']?['token'];
        if (token != null) StorageManager.user.saveToken(token);
        return res.data as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '游客登录失败: $e'};
    }
  }

  /// 获取用户 Profile (通过 /me 接口)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _dio.get('/api/v1/auth/me');
      if (res.data is Map && res.data['success'] == true) {
        _currentUser = res.data['data'] as Map<String, dynamic>?;
        return res.data as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '获取用户信息失败: $e'};
    }
  }
}

/// 内容服务 — 对接 /api/v1/contents/* 后端 API
class ContentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
  ));

  ContentService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// 获取内容列表
  Future<List<Map<String, dynamic>>> getContents({String? type, int limit = 20}) async {
    try {
      final res = await _dio.get('/api/v1/contents', queryParameters: {
        if (type != null) 'type': type,
        'limit': limit,
      });
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 获取内容分类
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await _dio.get('/api/v1/contents/categories');
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 搜索内容
  Future<List<Map<String, dynamic>>> searchContents(String query) async {
    try {
      final res = await _dio.get('/api/v1/contents/search', queryParameters: {'q': query});
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 获取推荐内容
  Future<List<Map<String, dynamic>>> getRecommended({String? constitution}) async {
    try {
      final res = await _dio.get('/api/v1/contents/recommend', queryParameters: {
        if (constitution != null) 'constitution': constitution,
      });
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 获取内容详情
  Future<Map<String, dynamic>?> getContentDetail(String contentId) async {
    try {
      final res = await _dio.get('/api/v1/contents/$contentId');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 获取今日养生建议（通过节气 API）
  Future<Map<String, dynamic>> getDailyPlan(String userId) async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/daily-advice',
          queryParameters: {'user_id': userId});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '$e'};
    }
  }

  /// 获取食疗推荐
  Future<List<Map<String, dynamic>>> getFoodRecommend({
    required String userId,
    String? constitution,
    String? season,
  }) async {
    return getContents(type: 'food');
  }

  /// 获取茶饮推荐
  Future<List<Map<String, dynamic>>> getTeaRecommend({
    required String userId,
    String? constitution,
    String? timeOfDay,
  }) async {
    return getContents(type: 'tea');
  }
}

/// 习惯服务
class HabitService {
  // 模拟习惯数据
  final List<Map<String, dynamic>> _habits = [
    {'id': 'habit_1', 'name': '喝水', 'icon': 'water', 'target': 8, 'unit': '杯'},
    {'id': 'habit_2', 'name': '运动', 'icon': 'run', 'target': 30, 'unit': '分钟'},
    {'id': 'habit_3', 'name': '早睡', 'icon': 'sleep', 'target': 22, 'unit': '点'},
    {'id': 'habit_4', 'name': '泡脚', 'icon': 'foot', 'target': 15, 'unit': '分钟'},
    {'id': 'habit_5', 'name': '冥想', 'icon': 'meditation', 'target': 10, 'unit': '分钟'},
    {'id': 'habit_6', 'name': '阅读', 'icon': 'book', 'target': 20, 'unit': '分钟'},
  ];
  
  // 打卡记录
  final Map<String, List<Map<String, dynamic>>> _logs = {};
  
  /// 获取习惯列表
  Future<List<Map<String, dynamic>>> getHabits(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _habits;
  }
  
  /// 添加习惯
  Future<Map<String, dynamic>> addHabit(String userId, Map<String, dynamic> habit) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newHabit = {
      'id': 'habit_${DateTime.now().millisecondsSinceEpoch}',
      ...habit,
    };
    _habits.add(newHabit);
    return newHabit;
  }
  
  /// 打卡
  Future<Map<String, dynamic>> checkIn(String habitId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    
    _logs[habitId] ??= [];
    _logs[habitId]!.add({
      'date': dateKey,
      'time': now.toIso8601String(),
      'completed': true,
    });
    
    return {
      'success': true,
      'habit_id': habitId,
      'date': dateKey,
      'time': now.toIso8601String(),
    };
  }
  
  /// 取消打卡
  Future<Map<String, dynamic>> uncheckIn(String habitId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    
    _logs[habitId]?.removeWhere((log) => log['date'] == dateKey);
    
    return {
      'success': true,
      'habit_id': habitId,
      'date': dateKey,
      'uncheck': true,
    };
  }
  
  /// 获取今日打卡状态
  Future<Map<String, bool>> getTodayStatus(String userId) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';
    
    final status = <String, bool>{};
    for (final habit in _habits) {
      final logs = _logs[habit['id']] ?? [];
      status[habit['id']] = logs.any((log) => log['date'] == dateKey);
    }
    return status;
  }
  
  /// 获取打卡记录
  Future<List<Map<String, dynamic>>> getHabitLogs(String habitId, {int days = 7}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _logs[habitId] ?? [];
  }
  
  /// 删除习惯
  Future<Map<String, dynamic>> deleteHabit(String habitId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _habits.removeWhere((h) => h['id'] == habitId);
    _logs.remove(habitId);
    return {'success': true};
  }
}

/// 家庭服务 — 对接 /api/v1/family/* 后端 API
class FamilyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
  ));

  FamilyService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// 获取家庭信息
  Future<Map<String, dynamic>> getFamily(String userId) async {
    try {
      final res = await _dio.get('/api/v1/family', queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '获取家庭信息失败: $e', 'members': []};
    }
  }

  /// 获取家庭成员列表
  Future<List<Map<String, dynamic>>> getMembers(String userId) async {
    try {
      final res = await _dio.get('/api/v1/family/members', queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 添加家庭成员
  Future<Map<String, dynamic>> addMember(String familyId, Map<String, dynamic> member) async {
    try {
      final res = await _dio.post('/api/v1/family/members', data: member);
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '添加成员失败: $e'};
    }
  }

  /// 移除家庭成员
  Future<Map<String, dynamic>> removeMember(String memberId) async {
    try {
      final res = await _dio.delete('/api/v1/family/members/$memberId');
      return {'success': res.statusCode == 200};
    } catch (e) {
      return {'error': '移除成员失败: $e'};
    }
  }

  /// 发送关怀提醒
  Future<Map<String, dynamic>> sendCare({
    required String familyId,
    required String toMemberId,
    required String message,
  }) async {
    try {
      final res = await _dio.post('/api/v1/family/reminder', data: {
        'member_id': toMemberId,
        'message': message,
        'type': 'care',
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '发送关怀失败: $e'};
    }
  }

  /// 获取家庭状态概览
  Future<Map<String, dynamic>> getFamilyOverview(String userId) async {
    try {
      final res = await _dio.get('/api/v1/family/overview', queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '获取概览失败: $e'};
    }
  }

  /// 获取关怀记录（通过 records API）
  Future<List<Map<String, dynamic>>> getCareLogs(String familyId, {int days = 7}) async {
    try {
      final res = await _dio.get('/api/v1/records/care', queryParameters: {'days': days});
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 生成邀请码
  Future<Map<String, dynamic>> createInvite(String userId) async {
    try {
      final res = await _dio.post('/api/v1/family/invite', data: {'user_id': userId});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '生成邀请码失败: $e'};
    }
  }

  /// 加入家庭
  Future<Map<String, dynamic>> joinFamily(String inviteCode) async {
    try {
      final res = await _dio.post('/api/v1/family/join', data: {'invite_code': inviteCode});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '加入家庭失败: $e'};
    }
  }

  /// 获取家庭摘要（AI 生成）
  Future<Map<String, dynamic>> getFamilyDigest(String userId) async {
    try {
      final res = await _dio.get('/api/v1/family/overview', queryParameters: {'user_id': userId});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '获取摘要失败: $e'};
    }
  }
}

/// 订阅服务 — 对接 /api/v1/subscription/* 后端 API
class SubscriptionService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
  ));

  SubscriptionService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageManager.user.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// 检查订阅状态
  Future<Map<String, dynamic>> checkSubscription(String userId) async {
    try {
      final res = await _dio.get('/api/v1/subscription/status',
          queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
      return res.data as Map<String, dynamic>;
    } catch (e) {
      // 降级到免费版
      return {
        'type': 'free',
        'ai_remaining': 5,
        'ai_used_today': 0,
        'expires_at': null,
      };
    }
  }

  /// 获取订阅计划列表
  Future<List<Map<String, dynamic>>> getPlansAsync() async {
    try {
      final res = await _dio.get('/api/v1/subscription/plans');
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return _fallbackPlans();
    } catch (_) {
      return _fallbackPlans();
    }
  }

  /// 同步获取计划（兼容旧接口）
  List<Map<String, dynamic>> getPlans() => _fallbackPlans();

  List<Map<String, dynamic>> _fallbackPlans() => [
    {'id': 'free', 'name': '免费版', 'price': 0, 'daily_ai_limit': 5,
     'features': ['AI 对话', '基础养生', '每日建议']},
    {'id': 'yangxin', 'name': '养心会员', 'price': 29, 'daily_ai_limit': 50,
     'features': ['AI 对话', '全部养生功能', '家庭关怀', '专属体质报告', '优先客服']},
    {'id': 'yiyang', 'name': '颐养会员', 'price': 199, 'daily_ai_limit': 100,
     'features': ['AI 对话', '全部养生功能', '家庭关怀', '专属体质报告', '优先客服', '线下活动', '专属顾问']},
  ];

  /// 订阅
  Future<Map<String, dynamic>> subscribe(String userId, String planType) async {
    try {
      final res = await _dio.post('/api/v1/subscription/subscribe', data: {
        'user_id': userId,
        'plan': planType,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '订阅失败: $e'};
    }
  }

  /// 取消订阅
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    try {
      final res = await _dio.post('/api/v1/subscription/cancel', data: {
        'user_id': userId,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'error': '取消失败: $e'};
    }
  }

  /// 获取订阅历史
  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    try {
      final res = await _dio.get('/api/v1/subscription/history',
          queryParameters: {'user_id': userId});
      if (res.data is Map && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 使用 AI 次数
  Future<bool> useAI(String userId) async {
    final status = await checkSubscription(userId);
    return (status['ai_remaining'] ?? 0) > 0;
  }

  /// 检查 AI 次数
  Future<bool> canUseAI(String userId) async {
    final status = await checkSubscription(userId);
    return (status['ai_remaining'] ?? 0) > 0;
  }

  /// 重置每日次数（由服务端定时任务处理，客户端仅刷新状态）
  Future<void> resetDailyLimit(String userId) async {
    await checkSubscription(userId);
  }
}


