import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户数据本地存储
class UserStorage {
  static const String _keyUserInfo = 'user_info';
  static const String _keyToken = 'auth_token';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keySubscription = 'subscription';
  
  final SharedPreferences _prefs;
  
  UserStorage(this._prefs);
  
  /// 保存用户信息
  Future<bool> saveUserInfo(Map<String, dynamic> userInfo) async {
    return await _prefs.setString(_keyUserInfo, jsonEncode(userInfo));
  }
  
  /// 获取用户信息
  Map<String, dynamic>? getUserInfo() {
    final data = _prefs.getString(_keyUserInfo);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  /// 保存 Token
  Future<bool> saveToken(String token) async {
    return await _prefs.setString(_keyToken, token);
  }
  
  /// 获取 Token
  String? getToken() {
    return _prefs.getString(_keyToken);
  }
  
  /// 清除 Token
  Future<bool> clearToken() async {
    return await _prefs.remove(_keyToken);
  }
  
  /// 保存 Refresh Token
  Future<bool> saveRefreshToken(String token) async {
    return await _prefs.setString('refresh_token', token);
  }
  
  /// 获取 Refresh Token
  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }
  
  /// 设置登录状态
  Future<bool> setLoggedIn(bool isLoggedIn) async {
    return await _prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }
  
  /// 是否已登录
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }
  
  /// 保存订阅信息
  Future<bool> saveSubscription(Map<String, dynamic> subscription) async {
    return await _prefs.setString(_keySubscription, jsonEncode(subscription));
  }
  
  /// 获取订阅信息
  Map<String, dynamic>? getSubscription() {
    final data = _prefs.getString(_keySubscription);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  /// 获取用户 ID
  String? getUserId() {
    final info = getUserInfo();
    return info?['id'] as String?;
  }

  /// 清除所有用户数据
  Future<bool> clear() async {
    await _prefs.remove(_keyUserInfo);
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keySubscription);
    await _prefs.remove('refresh_token');
    await _prefs.remove('device_id');
    return true;
  }

  /// 通用字符串存储
  Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// 通用字符串读取
  String? getString(String key) {
    return _prefs.getString(key);
  }
}

/// 应用设置存储
class SettingsStorage {
  static const String _keyTheme = 'theme_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyFirstLaunch = 'first_launch';
  
  final SharedPreferences _prefs;
  
  SettingsStorage(this._prefs);
  
  /// 主题模式 (light/dark/system)
  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_keyTheme, mode);
  }
  
  String getThemeMode() {
    return _prefs.getString(_keyTheme) ?? 'system';
  }
  
  /// 通知开关
  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(_keyNotifications, enabled);
  }
  
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotifications) ?? true;
  }
  
  /// 提醒时间
  Future<bool> setReminderTime(String time) async {
    return await _prefs.setString(_keyReminderTime, time);
  }
  
  String? getReminderTime() {
    return _prefs.getString(_keyReminderTime);
  }
  
  /// 是否首次启动
  Future<bool> setFirstLaunch(bool first) async {
    return await _prefs.setBool(_keyFirstLaunch, first);
  }
  
  bool isFirstLaunch() {
    return _prefs.getBool(_keyFirstLaunch) ?? true;
  }
}
