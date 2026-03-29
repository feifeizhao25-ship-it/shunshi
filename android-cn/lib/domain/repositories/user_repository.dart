// lib/domain/repositories/user_repository.dart
// 用户仓储接口

import '../entities/user.dart';

abstract class UserRepository {
  /// 获取当前登录用户
  Future<User?> getCurrentUser();

  /// 更新用户信息
  Future<User> updateUser(User user);

  /// 更新体质
  Future<void> updateConstitution(String userId, ConstitutionType constitution);

  /// 更新半球设置
  Future<void> updateHemisphere(String userId, String hemisphere);

  /// 登出
  Future<void> logout();

  /// 注销账户
  Future<void> deleteAccount(String userId);
}
