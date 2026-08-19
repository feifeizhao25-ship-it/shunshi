import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/user_context.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final SharedPreferences _prefs;
  static const _userKey = 'user_context';

  UserRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<UserContext> getUser() async {
    final raw = _prefs.getString(_userKey);
    if (raw == null) {
      // First launch: create a new user
      final user = UserContext(userId: const Uuid().v4());
      await saveUser(user);
      return user;
    }
    try {
      return UserContext.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      final user = UserContext(userId: const Uuid().v4());
      await saveUser(user);
      return user;
    }
  }

  @override
  Future<void> saveUser(UserContext user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> updateMemoryEnabled(bool enabled) async {
    final user = await getUser();
    await saveUser(user.copyWith(memoryEnabled: enabled));
  }

  @override
  Future<void> updateProactiveEnabled(bool enabled) async {
    final user = await getUser();
    await saveUser(user.copyWith(proactiveEnabled: enabled));
  }

  @override
  Future<void> updateQuietHours(QuietHours hours) async {
    final user = await getUser();
    await saveUser(user.copyWith(quietHours: hours));
  }
}
