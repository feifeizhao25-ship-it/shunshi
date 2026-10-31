import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage_manager.dart';

/// 当前登录账号（或游客会话）的用户 id；没有登录、或本地存储还没初始化时返回 null。
///
/// 一律从登录令牌里取（取不到再用保存的账号资料）。**不要**在页面里写 `'user-001'` / `'guest'` /
/// `'seasons-user'` 这类字面量当用户 id——服务端按令牌核对本人，写死的 id 一律 403，
/// 页面于是永远显示 0 条记录（复测 B03 / B19 / B20）。
String? currentUserId() {
  try {
    final token = StorageManager.user.getToken();
    final fromToken = token == null ? null : userIdFromToken(token);
    if (fromToken != null) return fromToken;
    final id = StorageManager.user.getUserInfo()?['id']?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  } catch (_) {
    return null;
  }
}

/// 令牌（JWT）里的 `sub` 就是服务端核对的本人 id；这里只读不验，验签在服务端。
/// 手机号登录 / 游客登录只保存了令牌、没有保存用户资料，所以以令牌为准。
String? userIdFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final sub = payload is Map ? payload['sub'] : null;
    final id = sub?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  } catch (_) {
    return null;
  }
}

/// 要放进查询串 / 请求体的 `user_id`：已登录是 `{'user_id': id}`，否则是空映射。
/// 用法：`queryParameters: {...userIdParam(), 'limit': 50}`。
/// 服务端发现路由带 `user_id` 却没传时，会按令牌补上本人。
Map<String, String> userIdParam() {
  final id = currentUserId();
  return id == null ? const <String, String>{} : <String, String>{'user_id': id};
}

/// 从 guest-login 的两种响应形状里取出访问令牌：
/// `{access_token: ...}` 或 `{data: {token: ...}}` / `{token: ...}`。
String? tokenFromAuthBody(dynamic body) {
  if (body is! Map) return null;
  final inner = body['data'] is Map ? body['data'] as Map : body;
  for (final v in [body['access_token'], inner['access_token'], inner['token'], body['token']]) {
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return null;
}

Future<String?>? _pendingSession;

/// 当前会话的令牌。
///
/// 1. 本机已有令牌（登录账号或之前建立的游客会话）→ 直接用；
/// 2. 都没有 → 只建立**一个**游客会话并保存下来，之后所有页面共用。
///
/// 以前「记录」「体质测试」等页面每次打开都调一次 guest-login，等于每次换一个全新的空账号，
/// 用户自己写的日记、积分、成就永远查不到（复测 B03）。
Future<String?> ensureSessionToken(Dio dio) {
  return _pendingSession ??= _ensure(dio).whenComplete(() => _pendingSession = null);
}

Future<String?> _ensure(Dio dio) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('auth_token');
  if (saved != null && saved.trim().isNotEmpty) return saved;
  try {
    final res = await dio.post('/api/v1/auth/guest-login', data: {});
    final token = tokenFromAuthBody(res.data);
    if (token == null) return null;
    await prefs.setString('auth_token', token);
    final body = res.data;
    final inner = body is Map && body['data'] is Map ? body['data'] as Map : body;
    if (inner is Map) {
      if (inner['user'] is Map) await prefs.setString('user_info', jsonEncode(inner['user']));
      final refresh = inner['refresh_token'];
      if (refresh is String && refresh.isNotEmpty) await prefs.setString('refresh_token', refresh);
    }
    return token;
  } catch (_) {
    return null;
  }
}

/// 日记列表接口返回 `{success, data: {entries: [...]}}`；旧版直接返回 `{entries: [...]}`，两种都认。
List<Map<String, dynamic>>? journalEntriesFromBody(dynamic body) {
  final inner = body is Map && body['data'] is Map ? body['data'] as Map : body;
  final list = inner is Map ? inner['entries'] : null;
  if (list is! List) return null;
  return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

/// 周度洞察：取服务端给出的趋势说明；没有数据时不编造。
String? journalInsightFromBody(dynamic body) {
  final inner = body is Map && body['data'] is Map ? body['data'] as Map : body;
  if (inner is! Map) return null;
  if ((inner['entries_count'] ?? 1) == 0) return null;
  for (final k in ['trend_message', 'insight']) {
    final v = inner[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return null;
}

/// 给页面 / 服务里自建的 Dio 挂上当前会话令牌（与 ApiClient 同一份）。已带 Authorization 的请求不动。
/// 之前这些 Dio 完全不带令牌，用户相关接口一律 401 / 403，页面只能显示空数据。
Dio withSessionAuth(Dio dio) {
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (!options.headers.containsKey('Authorization')) {
      String? token;
      try {
        token = StorageManager.user.getToken();
      } catch (_) {}
      if (token != null && token.trim().isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }));
  return dio;
}
