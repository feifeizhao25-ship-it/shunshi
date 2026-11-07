import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/token_storage.dart';
import 'storage_manager.dart';

const _accountKeys = <String>[
  'profile_completed',
  'user_name',
  'user_gender',
  'user_birth_year',
  'user_constitution',
  'user_health_concerns',
  'user_concerns',
  'user_phone',
  'constitution_type',
  'checkin_days',
];

/// 退出登录时清掉这个账号留在本机的身份。
///
/// 不清除首次引导标记，下一次打开仍停在登录页，而不是再看一遍介绍。
/// 下一个游客拿不到上一个人的昵称、关注和令牌。
Future<void> endLocalSession() async {
  try {
    await tokenStorage.clearTokens();
  } catch (_) {}
  try {
    await StorageManager.user.clear();
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  for (final key in _accountKeys) {
    await prefs.remove(key);
  }
}
