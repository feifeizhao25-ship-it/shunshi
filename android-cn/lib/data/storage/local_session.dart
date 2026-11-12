import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';
import '../network/session.dart';
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
/// 先尽力通知服务端作废当前令牌（POST /api/v1/auth/logout）。网络失败不阻止本机退出。
/// 不清除首次引导标记，下一次打开仍停在登录页，而不是再看一遍介绍。
/// 下一个游客拿不到上一个人的昵称、关注和令牌。
Future<void> endLocalSession({Dio? client}) async {
  try {
    await revokeServerSession(client: client);
  } catch (_) {}
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

/// 在清掉本机令牌之前，用仍有效的会话调用 POST /api/v1/auth/logout。
///
/// 没有令牌时不发请求。调用方负责吞掉网络错误，避免挡住本机退出。
Future<void> revokeServerSession({Dio? client}) async {
  final token = StorageManager.user.getToken();
  if (token == null || token.trim().isEmpty) return;
  final dio = withSessionAuth(
    client ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        ),
  );
  await dio.post('/api/v1/auth/logout');
}
