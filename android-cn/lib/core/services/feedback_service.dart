import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackService {
  static const String _baseUrl = 'http://116.62.32.43:4000/api/v1';
  static final _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: Duration(seconds: 10)));

  /// Record practice completion with rating
  static Future<bool> practiceComplete({
    required String contentId,
    required int rating,
    String note = '',
  }) async {
    try {
      final userId = await _getUserId();
      final resp = await _dio.post('/feedback/practice-complete', data: {
        'user_id': userId,
        'content_id': contentId,
        'rating': rating,
        'note': note,
      });
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Daily check-in
  static Future<bool> dailyCheckin({
    required int mood,
    required int sleepQuality,
    required int energy,
    String notes = '',
  }) async {
    try {
      final userId = await _getUserId();
      final resp = await _dio.post('/feedback/checkin', data: {
        'user_id': userId,
        'mood': mood,
        'sleep_quality': sleepQuality,
        'energy': energy,
        'notes': notes,
      });
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get personalized insights
  static Future<Map<String, dynamic>?> getInsights() async {
    try {
      final userId = await _getUserId();
      final resp = await _dio.get('/feedback/insights/$userId');
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  /// Get personalized recommendations
  static Future<Map<String, dynamic>?> getRecommendations() async {
    try {
      final userId = await _getUserId();
      final resp = await _dio.get('/feedback/recommendations/$userId');
      return resp.data;
    } catch (_) {
      return null;
    }
  }

  /// Get subscription tier status
  static Future<Map<String, dynamic>?> getTierStatus() async {
    try {
      final userId = await _getUserId();
      final resp = await _dio.get('/subscription/status/$userId');
      return resp.data;
    } catch (_) {
      return {'tier': 'free', 'limits': {'daily_messages': 10, 'model': 'glm-4-flash'}};
    }
  }

  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? 'guest';
  }
}
