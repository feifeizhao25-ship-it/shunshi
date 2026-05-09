// Offline Data Manager — 本地缓存关键数据供离线使用
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  static const _prefix = 'offline_';

  /// Save数据到本地缓存
  static Future<void> save(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(data);
    await prefs.setString('$_prefix$key', json);
  }

  /// Save列表数据
  static Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items);
    await prefs.setString('$_prefix$key', json);
  }

  /// 读取缓存数据
  static Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// 读取列表缓存
  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// 检查是否有缓存
  static Future<bool> has(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$key');
  }

  /// 清除指定缓存
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// 缓存 Dashboard 数据（5min有效）
  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    final wrapper = {
      'data': data,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
    await save('dashboard', wrapper);
  }

  /// 获取缓存的 Dashboard
  static Future<Map<String, dynamic>?> getCachedDashboard() async {
    final wrapper = await load('dashboard');
    if (wrapper == null) return null;
    final cachedAt = wrapper['cached_at'] as int? ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age > 5 * 60 * 1000) return null; // 5 min expiry
    return wrapper['data'] as Map<String, dynamic>;
  }

  /// 缓存内容列表
  static Future<void> cacheContentList(String type, List<Map<String, dynamic>> items) async {
    await saveList('content_$type', items);
  }

  static Future<List<Map<String, dynamic>>> getCachedContentList(String type) async {
    return await loadList('content_$type');
  }
}
