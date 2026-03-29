// lib/domain/repositories/user_repository.dart
import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User> updateUser(User user);
  Future<void> updateHemisphere(String userId, String hemisphere);
  Future<void> logout();
  Future<void> deleteAccount(String userId);
}
