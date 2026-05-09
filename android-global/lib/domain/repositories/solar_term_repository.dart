// lib/domain/repositories/solar_term_repository.dart
// Solar Term仓储接口

import '../entities/solar_term.dart';

abstract class SolarTermRepository {
  /// 获取Current Solar Term
  Future<SolarTerm?> getCurrentSolarTerm();

  /// 获取所有Solar Term列表
  Future<List<SolarTerm>> getAllSolarTerms();

  /// 获取Solar Term详情（包含完整Wellness方案）
  Future<SolarTerm?> getSolarTermDetail(String termName);

  /// 获取Solar Term Wellness方案
  Future<Map<String, dynamic>?> getWellnessPlan(String termName);
}
