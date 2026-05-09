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

/// 用户服务
class UserService {
  final ApiService _api = ApiService();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiClient.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));
  
  // 模拟用户数据
  Map<String, dynamic>? _currentUser;
  
  /// 登录
  Future<Map<String, dynamic>> login(String email, String password) async {
    // 模拟登录
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 简单验证
    if (email.isEmpty || password.isEmpty) {
      return {'error': '请输入邮箱和密码'};
    }
    
    _currentUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'name': email.split('@').first,
      'subscription_type': 'free',
      'daily_ai_limit': 5,
      'ai_usage_today': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    return {'token': 'AUTH_REQUIRED', 'user': _currentUser};
  }
  
  /// 注册
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return {'error': '请填写完整信息'};
    }
    
    _currentUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'name': name,
      'subscription_type': 'free',
      'daily_ai_limit': 5,
      'ai_usage_today': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    return {'token': 'AUTH_REQUIRED', 'user': _currentUser};
  }
  
  /// 获取当前用户
  Map<String, dynamic>? getCurrentUser() => _currentUser;
  
  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    if (_currentUser != null && _currentUser!['id'] == userId) {
      return _currentUser!;
    }
    return {
      'id': userId,
      'name': '测试用户',
      'subscription_type': 'free',
      'daily_ai_limit': 5,
      'ai_usage_today': 0,
    };
  }
  
  /// 更新用户信息
  Future<Map<String, dynamic>> updateUserInfo(String userId, Map<String, dynamic> data) async {
    if (_currentUser != null && _currentUser!['id'] == userId) {
      _currentUser!.addAll(data);
      return _currentUser!;
    }
    return {'error': '用户不存在'};
  }
  
  /// 登出
  void logout() {
    _currentUser = null;
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

/// 内容服务
class ContentService {
  final ApiService _api = ApiService();
  
  /// 获取今日养生建议
  Future<Map<String, dynamic>> getDailyPlan(String userId) async {
    final result = await _api.chat(
      userId: userId,
      message: '给我今日养生建议',
    );
    return result;
  }
  
  /// 获取节气养生
  Future<Map<String, dynamic>> getSolarTermGuide(String userId, String solarTerm) async {
    final result = await _api.chat(
      userId: userId,
      message: '告诉我$solarTerm节气的养生方法',
    );
    return result;
  }
  
  /// 获取食疗推荐
  Future<Map<String, dynamic>> getFoodRecommend({
    required String userId,
    String? constitution,
    String? season,
  }) async {
    final prompt = constitution != null 
        ? '我是$constitution体质，推荐适合的食物'
        : '推荐养生食物';
    final result = await _api.chat(userId: userId, message: prompt);
    return result;
  }
  
  /// 获取茶饮推荐
  Future<Map<String, dynamic>> getTeaRecommend({
    required String userId,
    String? constitution,
    String? timeOfDay,
  }) async {
    final prompt = '推荐养生茶饮';
    final result = await _api.chat(userId: userId, message: prompt);
    return result;
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

/// 家庭服务
class FamilyService {
  final ApiService _api = ApiService();
  
  // 模拟家庭数据
  Map<String, dynamic>? _currentFamily;
  final List<Map<String, dynamic>> _careLogs = [];
  
  /// 获取家庭信息
  Future<Map<String, dynamic>> getFamily(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_currentFamily != null) {
      return _currentFamily!;
    }
    
    // 返回示例家庭
    return {
      'id': 'family_001',
      'name': '我的家庭',
      'owner_id': userId,
      'members': [
        {'id': 'member_1', 'name': '爸爸', 'relation': '父亲', 'birthday': '1960-05-01', 'constitution': '阳虚质'},
        {'id': 'member_2', 'name': '妈妈', 'relation': '母亲', 'birthday': '1965-08-15', 'constitution': '气虚质'},
        {'id': 'member_3', 'name': '我', 'relation': '本人', 'birthday': '1990-03-20', 'constitution': '平和质'},
      ],
      'care_logs': _careLogs,
    };
  }
  
  /// 添加家庭成员
  Future<Map<String, dynamic>> addMember(String familyId, Map<String, dynamic> member) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final newMember = {
      'id': 'member_${DateTime.now().millisecondsSinceEpoch}',
      ...member,
    };
    
    if (_currentFamily != null) {
      final members = _currentFamily!['members'] as List;
      members.add(newMember);
    }
    
    return newMember;
  }
  
  /// 移除家庭成员
  Future<Map<String, dynamic>> removeMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_currentFamily != null) {
      final members = _currentFamily!['members'] as List;
      members.removeWhere((m) => m['id'] == memberId);
    }
    
    return {'success': true};
  }
  
  /// 发送关怀
  Future<Map<String, dynamic>> sendCare({
    required String familyId,
    required String toMemberId,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final careLog = {
      'id': 'care_${DateTime.now().millisecondsSinceEpoch}',
      'from_user': 'me',
      'to_member': toMemberId,
      'message': message,
      'time': DateTime.now().toIso8601String(),
      'type': 'care',
    };
    
    _careLogs.add(careLog);
    
    return {'success': true, 'care_log': careLog};
  }
  
  /// 获取关怀记录
  Future<List<Map<String, dynamic>>> getCareLogs(String familyId, {int days = 7}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _careLogs;
  }
  
  /// 获取家庭摘要
  Future<Map<String, dynamic>> getFamilyDigest(String userId) async {
    final result = await _api.chat(
      userId: userId,
      message: '给我家庭健康摘要',
    );
    return result;
  }
}

/// 订阅服务
class SubscriptionService {
  // 模拟订阅数据
  final Map<String, Map<String, dynamic>> _subscriptions = {};
  
  // 订阅计划
  static const Map<String, Map<String, dynamic>> plans = {
    'free': {
      'name': '免费版',
      'price': 0,
      'daily_ai_limit': 5,
      'features': ['AI 对话', '基础养生', '每日建议'],
    },
    'monthly': {
      'name': '月度会员',
      'price': 29,
      'daily_ai_limit': 50,
      'features': ['AI 对话', '全部养生功能', '家庭关怀', '专属体质报告', '优先客服'],
    },
    'yearly': {
      'name': '年度会员',
      'price': 199,
      'daily_ai_limit': 100,
      'features': ['AI 对话', '全部养生功能', '家庭关怀', '专属体质报告', '优先客服', '线下活动', '专属顾问'],
    },
  };
  
  /// 检查订阅状态
  Future<Map<String, dynamic>> checkSubscription(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_subscriptions.containsKey(userId)) {
      return _subscriptions[userId]!;
    }
    
    return {
      'type': 'free',
      'ai_remaining': 5,
      'ai_used_today': 0,
      'expires_at': null,
    };
  }
  
  /// 获取订阅计划列表
  List<Map<String, dynamic>> getPlans() {
    return plans.entries.map((e) => {'id': e.key, ...e.value}).toList();
  }
  
  /// 订阅
  Future<Map<String, dynamic>> subscribe(String userId, String planType) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final plan = plans[planType];
    if (plan == null) {
      return {'error': '无效的订阅计划'};
    }
    
    final now = DateTime.now();
    DateTime? expiresAt;
    if (planType == 'monthly') {
      expiresAt = now.add(const Duration(days: 30));
    } else if (planType == 'yearly') {
      expiresAt = now.add(const Duration(days: 365));
    }
    
    final subscription = {
      'type': planType,
      'name': plan['name'],
      'ai_remaining': plan['daily_ai_limit'],
      'ai_used_today': 0,
      'subscribed_at': now.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
    
    _subscriptions[userId] = subscription;
    
    return {'success': true, 'subscription': subscription};
  }
  
  /// 取消订阅
  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _subscriptions[userId] = {
      'type': 'free',
      'ai_remaining': 5,
      'ai_used_today': 0,
      'expires_at': null,
    };
    
    return {'success': true};
  }
  
  /// 使用 AI 次数
  Future<bool> useAI(String userId) async {
    final status = await checkSubscription(userId);
    final remaining = status['ai_remaining'] as int? ?? 0;
    
    if (remaining <= 0) {
      return false;
    }
    
    // 扣减次数
    _subscriptions[userId]?['ai_remaining'] = remaining - 1;
    _subscriptions[userId]?['ai_used_today'] = (status['ai_used_today'] as int? ?? 0) + 1;
    
    return true;
  }
  
  /// 重置每日次数
  Future<void> resetDailyLimit(String userId) async {
    if (_subscriptions.containsKey(userId)) {
      final type = _subscriptions[userId]!['type'] as String;
      final limit = plans[type]?['daily_ai_limit'] as int? ?? 5;
      _subscriptions[userId]!['ai_remaining'] = limit;
      _subscriptions[userId]!['ai_used_today'] = 0;
    }
  }
  
  /// 检查 AI 次数
  Future<bool> canUseAI(String userId) async {
    final status = await checkSubscription(userId);
    return (status['ai_remaining'] ?? 0) > 0;
  }
}
