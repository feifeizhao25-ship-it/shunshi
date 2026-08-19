import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 封装
class LocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // String
  Future<void> setString(String key, String value) async =>
      (await prefs).setString(key, value);

  Future<String?> getString(String key) async =>
      (await prefs).getString(key);

  // Bool
  Future<void> setBool(String key, bool value) async =>
      (await prefs).setBool(key, value);

  Future<bool?> getBool(String key) async =>
      (await prefs).getBool(key);

  // Int
  Future<void> setInt(String key, int value) async =>
      (await prefs).setInt(key, value);

  Future<int?> getInt(String key) async =>
      (await prefs).getInt(key);

  // JSON Object
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      (await prefs).setString(key, jsonEncode(value));

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = (await prefs).getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Remove
  Future<void> remove(String key) async => (await prefs).remove(key);

  // Clear all
  Future<void> clear() async => (await prefs).clear();
}
