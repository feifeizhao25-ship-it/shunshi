/// Solar Term Wellness服务 — 对接 /api/v1/solar-wellness API
library;

import 'package:dio/dio.dart';

class SolarWellnessService {
  static const _baseUrl = 'http://116.62.32.43:4000';
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
  ));

  /// 获取Current Solar Term
  Future<Map<String, dynamic>?> getCurrentTerm() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/current?locale=en-US');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取今th综合建议
  Future<Map<String, dynamic>?> getDailyAdvice() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/daily-advice?locale=en-US');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取Current Shichen
  Future<Map<String, dynamic>?> getCurrentShichen() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/shichen?locale=en-US');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取Solar Term上下文（含Diet/Exercise/Sleep建议）
  Future<Map<String, dynamic>?> getTermContext() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/context?locale=en-US');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
