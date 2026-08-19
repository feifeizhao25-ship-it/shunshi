import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/error/exceptions.dart';

/// Supabase Auth 仓库实现
class AuthRepositoryImpl implements AuthRepository {
  final sp.SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    return _fetchUserProfile(session.user.id);
  }

  @override
  Future<User> signInWithPhone(String phone, String code) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: sp.OtpType.sms,
        phone: phone,
        token: code,
      );
      if (response.user == null) {
        throw const ServerException('验证失败');
      }
      final user = await _fetchUserProfile(response.user!.id);
      if (user != null) return user;
      
      // 新用户注册
      return _createUserProfile(response.user!.id, phone);
    } catch (e) {
      throw ServerException('登录失败: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> updateProfile(User user) async {
    try {
      await _supabase.from('users').update({
        'nickname': user.nickname,
        'gender': user.gender?.index,
        'birthday': user.birthDate?.toIso8601String(),
        'constitution_type': user.constitution?.primary?.type,
      }).eq('id', user.id);
    } catch (e) {
      throw ServerException('更新资料失败: $e');
    }
  }

  @override
  Stream<User?> watchCurrentUser() {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      if (data.session == null) return null;
      return await _fetchUserProfile(data.session!.user.id);
    });
  }

  // --- Private Helpers ---

  Future<User?> _fetchUserProfile(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      
      // Map to User entity
      return User(
        id: data['id'],
        phone: data['phone_number'],
        nickname: data['nickname'],
        gender: data['gender'] != null ? Gender.values[data['gender']] : null,
        birthDate: data['birthday'] != null ? DateTime.parse(data['birthday']) : null,
        constitution: data['constitution_type'] != null
            ? UserConstitution(primary: UserConstitutionResult(type: data['constitution_type'], score: 0))
            : null,
        createdAt: DateTime.parse(data['created_at']),
      );
    } catch (e) {
      return null;
    }
  }

  Future<User> _createUserProfile(String id, String phone) async {
    final now = DateTime.now();
    final data = {
      'id': id,
      'phone_number': phone,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    await _supabase.from('users').insert(data);
    return User(
      id: id,
      phone: phone,
      createdAt: now,
    );
  }
}
