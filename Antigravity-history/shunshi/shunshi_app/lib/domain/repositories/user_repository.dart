import '../../data/models/user_context.dart';

abstract class UserRepository {
  Future<UserContext> getUser();
  Future<void> saveUser(UserContext user);
  Future<void> updateMemoryEnabled(bool enabled);
  Future<void> updateProactiveEnabled(bool enabled);
  Future<void> updateQuietHours(QuietHours hours);
}
