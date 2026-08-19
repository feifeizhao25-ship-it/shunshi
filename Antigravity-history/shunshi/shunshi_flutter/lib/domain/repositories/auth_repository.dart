import '../entities/user.dart';

/// 认证仓库抽象
abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithPhone(String phone, String code);
  Future<void> signOut();
  Future<void> updateProfile(User user);
  Stream<User?> watchCurrentUser();
}
