import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationService {
  static const String _baseUrl = 'https://api.shunshi.app/api/v1/personalization';
  static final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept-Language': 'zh-CN'},
  ));

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? 'guest';
  }

  /// 获取今日个性化仪表盘
  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 获取生命状态
  static Future<Map<String, dynamic>?> getLifeState() async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/life-state',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 行为闭环：完成一个行动
  static Future<Map<String, dynamic>?> completeAction({
    required String actionType,
    required bool completed,
    int rating = 0,
    String skillName = '',
    int durationSeconds = 0,
    String note = '',
  }) async {
    try {
      final token = await _getToken();
      final res = await _dio.post('/action/complete',
        data: {
          'action_type': actionType,
          'completed': completed,
          'rating': rating,
          'skill_name': skillName,
          'duration_seconds': durationSeconds,
          'note': note,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 获取异常警报
  static Future<Map<String, dynamic>?> getAnomalyAlert() async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/anomaly-alert',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 获取每周洞察
  static Future<Map<String, dynamic>?> getWeeklyInsight() async {
    try {
      final token = await _getToken();
      final res = await _dio.get('/weekly-insight',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
