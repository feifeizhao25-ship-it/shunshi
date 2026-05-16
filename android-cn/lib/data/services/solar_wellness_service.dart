/// 节气养生服务 — 对接 /api/v1/solar-wellness API
library;

import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class SolarWellnessService {
  static final String _baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
  ));

  /// 获取当前节气
  Future<Map<String, dynamic>?> getCurrentTerm() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/current');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取今日综合建议
  Future<Map<String, dynamic>?> getDailyAdvice() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/daily-advice');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取当前时辰
  Future<Map<String, dynamic>?> getCurrentShichen() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/shichen');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// 获取节气上下文（含饮食/运动/睡眠建议）
  Future<Map<String, dynamic>?> getTermContext() async {
    try {
      final res = await _dio.get('/api/v1/solar-wellness/context');
      if (res.data is Map && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
