// lib/domain/repositories/reflection_repository.dart
// 感悟日记仓储接口

import '../entities/reflection.dart';

abstract class ReflectionRepository {
  /// 保存感悟
  Future<Reflection> saveReflection(Reflection reflection);

  /// 获取感悟列表（按日期排序）
  Future<List<Reflection>> getReflections({
    required String userId,
    int limit = 30,
    int offset = 0,
  });

  /// 获取指定日期感悟
  Future<Reflection?> getReflectionByDate(String userId, DateTime date);

  /// 删除感悟
  Future<void> deleteReflection(String id);
}
