import 'package:shared_preferences/shared_preferences.dart';
import 'user_storage.dart';
import 'habit_storage.dart';
import 'message_storage.dart';

/// 统一存储管理器
class StorageManager {
  static SharedPreferences? _prefs;
  
  static UserStorage? _userStorage;
  static HabitStorage? _habitStorage;
  static MessageStorage? _messageStorage;
  static SettingsStorage? _settingsStorage;
  
  /// 初始化所有存储服务
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    _userStorage = UserStorage(_prefs!);
    _habitStorage = HabitStorage(_prefs!);
    _messageStorage = MessageStorage(_prefs!);
    _settingsStorage = SettingsStorage(_prefs!);
  }
  
  /// 获取用户存储
  static UserStorage get user => _userStorage ??= UserStorage(_prefs!);
  
  /// 获取习惯存储
  static HabitStorage get habit => _habitStorage ??= HabitStorage(_prefs!);
  
  /// 获取消息存储
  static MessageStorage get message => _messageStorage ??= MessageStorage(_prefs!);
  
  /// 获取设置存储
  static SettingsStorage get settings => _settingsStorage ??= SettingsStorage(_prefs!);
  
  /// 清除所有数据 (登出时使用)
  static Future<void> clearAll() async {
    await user.clear();
    await habit.clear();
    await message.clear();
    // 设置保留
  }
  
  /// 获取缓存大小 (MB)
  static double getCacheSizeMB() {
    final bytes = message.getCacheSize();
    return bytes / (1024 * 1024);
  }
}
