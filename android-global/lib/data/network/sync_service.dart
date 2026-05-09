import 'package:dio/dio.dart';
import 'api_client.dart';
import '../storage/storage_manager.dart';

/// 数据同步服务
class SyncService {
  final ApiClient _client = ApiClient();
  
  /// 同步用户信息
  Future<ApiResult<Map<String, dynamic>>> syncUserInfo() async {
    try {
      final response = await _client.get('/user/info');
      
      if (response.statusCode == 200) {
        final userData = response.data;
        await StorageManager.user.saveUserInfo(userData);
        return ApiResult.success(userData);
      }
      
      return ApiResult.failure('Sync failed');
    } catch (e) {
      // 失败时返回本地数据
      final localData = StorageManager.user.getUserInfo();
      if (localData != null) {
        return ApiResult.success(localData);
      }
      return ApiResult.failure(_handleError(e));
    }
  }
  
  /// 同步习惯数据
  Future<ApiResult<List<Map<String, dynamic>>>> syncHabits() async {
    try {
      final response = await _client.get('/habits');
      
      if (response.statusCode == 200) {
        final habits = (response.data as List).cast<Map<String, dynamic>>();
        await StorageManager.habit.saveHabits(habits);
        return ApiResult.success(habits);
      }
      
      return ApiResult.failure('Sync failed');
    } catch (e) {
      // 返回本地数据
      return ApiResult.success(StorageManager.habit.getHabits());
    }
  }
  
  /// 同步打卡记录
  Future<ApiResult<Map<String, dynamic>>> syncCheckins(String date) async {
    try {
      final response = await _client.get('/checkins', queryParameters: {'date': date});
      
      if (response.statusCode == 200) {
        final checkins = response.data as Map<String, dynamic>;
        
        // 更新本地
        for (final entry in checkins.entries) {
          if (entry.value == true) {
            StorageManager.habit.checkIn(entry.key, date);
          }
        }
        
        return ApiResult.success(checkins);
      }
      
      return ApiResult.failure('Sync failed');
    } catch (e) {
      // 返回本地数据
      return ApiResult.success(StorageManager.habit.getTodayCheckins(date));
    }
  }
  
  /// 上传打卡
  Future<ApiResult<bool>> uploadCheckin(String habitId, String date) async {
    try {
      final response = await _client.post('/checkins', data: {
        'habit_id': habitId,
        'date': date,
      });
      
      if (response.statusCode == 200) {
        // 保存到本地
        await StorageManager.habit.checkIn(habitId, date);
        return ApiResult.success(true);
      }
      
      return ApiResult.failure('Upload failed');
    } catch (e) {
      // 离线时先保存到本地
      await StorageManager.habit.checkIn(habitId, date);
      return ApiResult.success(true); // Assume success, sync later
    }
  }
  
  /// 同步家庭数据
  Future<ApiResult<Map<String, dynamic>>> syncFamily() async {
    try {
      final response = await _client.get('/family');
      
      if (response.statusCode == 200) {
        return ApiResult.success(response.data);
      }
      
      return ApiResult.failure('Sync failed');
    } catch (e) {
      return ApiResult.failure(_handleError(e));
    }
  }
  
  /// 同步订阅信息
  Future<ApiResult<Map<String, dynamic>>> syncSubscription() async {
    try {
      final response = await _client.get('/subscription');
      
      if (response.statusCode == 200) {
        final subscription = response.data;
        await StorageManager.user.saveSubscription(subscription);
        return ApiResult.success(subscription);
      }
      
      return ApiResult.failure('Sync failed');
    } catch (e) {
      // 返回本地数据
      final local = StorageManager.user.getSubscription();
      if (local != null) {
        return ApiResult.success(local);
      }
      return ApiResult.failure(_handleError(e));
    }
  }
  
  /// 全量同步
  Future<ApiResult<Map<String, dynamic>>> syncAll() async {
    final results = <String, dynamic>{};
    
    // 同步用户信息
    final userResult = await syncUserInfo();
    results['user'] = userResult.data;
    
    // 同步习惯
    final habitsResult = await syncHabits();
    results['habits'] = habitsResult.data;
    
    // 同步订阅
    final subResult = await syncSubscription();
    results['subscription'] = subResult.data;
    
    return ApiResult.success(results);
  }
  
  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError) {
        return 'Network connection failed';
      }
      if (error.response?.statusCode == 401) {
        return 'Session expired, please log in again';
      }
    }
    return 'Sync failed';
  }
}
