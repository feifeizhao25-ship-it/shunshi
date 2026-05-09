// lib/domain/repositories/solar_term_repository.dart
// 节气仓储接口

import '../entities/solar_term.dart';

abstract class SolarTermRepository {
  /// 获取当前节气
  Future<SolarTerm?> getCurrentSolarTerm();

  /// 获取所有节气列表
  Future<List<SolarTerm>> getAllSolarTerms();

  /// 获取节气详情（包含完整养生方案）
  Future<SolarTerm?> getSolarTermDetail(String termName);

  /// 获取节气养生方案
  Future<Map<String, dynamic>?> getWellnessPlan(String termName);
}
