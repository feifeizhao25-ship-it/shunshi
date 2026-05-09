import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 习惯数据本地存储
class HabitStorage {
  static const String _keyHabits = 'habits';

  
  final SharedPreferences _prefs;
  
  HabitStorage(this._prefs);
  
  /// 保存习惯列表
  Future<bool> saveHabits(List<Map<String, dynamic>> habits) async {
    return await _prefs.setString(_keyHabits, jsonEncode(habits));
  }
  
  /// 获取习惯列表
  List<Map<String, dynamic>> getHabits() {
    final data = _prefs.getString(_keyHabits);
    if (data == null) return _defaultHabits;
    final list = jsonDecode(data) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
  
  /// 默认习惯
  List<Map<String, dynamic>> get _defaultHabits => [
    {'id': 'habit_1', 'name': '喝水', 'icon': 'water', 'target': 8, 'unit': '杯', 'enabled': true},
    {'id': 'habit_2', 'name': '运动', 'icon': 'run', 'target': 30, 'unit': '分钟', 'enabled': true},
    {'id': 'habit_3', 'name': '早睡', 'icon': 'sleep', 'target': 22, 'unit': '点', 'enabled': true},
    {'id': 'habit_4', 'name': '泡脚', 'icon': 'foot', 'target': 15, 'unit': '分钟', 'enabled': true},
  ];
  
  /// 添加习惯
  Future<bool> addHabit(Map<String, dynamic> habit) async {
    final habits = getHabits();
    habits.add(habit);
    return await saveHabits(habits);
  }
  
  /// 删除习惯
  Future<bool> deleteHabit(String habitId) async {
    final habits = getHabits();
    habits.removeWhere((h) => h['id'] == habitId);
    return await saveHabits(habits);
  }
  
  /// 打卡记录
  static String _checkinKey(String habitId, String date) => 'checkin_${habitId}_$date';
  
  /// 打卡
  Future<bool> checkIn(String habitId, String date) async {
    return await _prefs.setBool(_checkinKey(habitId, date), true);
  }
  
  /// 取消打卡
  Future<bool> uncheckIn(String habitId, String date) async {
    return await _prefs.remove(_checkinKey(habitId, date));
  }
  
  /// 今日是否已打卡
  bool isCheckedIn(String habitId, String date) {
    return _prefs.getBool(_checkinKey(habitId, date)) ?? false;
  }
  
  /// 获取今日打卡状态
  Map<String, bool> getTodayCheckins(String date) {
    final habits = getHabits();
    final checkins = <String, bool>{};
    for (final habit in habits) {
      checkins[habit['id']] = isCheckedIn(habit['id'], date);
    }
    return checkins;
  }
  
  /// 获取连续打卡天数
  int getStreak(String habitId) {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month}-${date.day}';
      if (isCheckedIn(habitId, dateStr)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }
  
  /// 清除所有数据
  Future<bool> clear() async {
    await _prefs.remove(_keyHabits);
    // 保留打卡记录，不清除
    return true;
  }
}
