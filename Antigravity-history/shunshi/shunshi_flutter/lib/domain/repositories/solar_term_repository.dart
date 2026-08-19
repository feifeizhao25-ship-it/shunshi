import '../entities/solar_term.dart';

/// 节气数据仓库抽象
abstract class SolarTermRepository {
  Future<SolarTerm?> getCurrentSolarTerm();
  Future<List<SolarTerm>> getSolarTermsForYear(int year);
  Future<SolarTerm?> getSolarTermById(String id);
}
