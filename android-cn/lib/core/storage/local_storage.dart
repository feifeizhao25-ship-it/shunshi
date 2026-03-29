// Local Data Storage Service
// Handles user preferences and cached data

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _userPrefsKey = 'user_preferences';
  static const _habitsKey = 'habits_cache';
  static const _messagesKey = 'messages_cache';
  static const _lastSyncKey = 'last_sync_time';
  static const _offlineQueueKey = 'offline_queue';
  
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  // ==================== User Preferences ====================
  
  Future<void> saveUserPreferences(Map<String, dynamic> prefs) async {
    final p = await _preferences;
    await p.setString(_userPrefsKey, jsonEncode(prefs));
  }
  
  Future<Map<String, dynamic>?> getUserPreferences() async {
    final p = await _preferences;
    final str = p.getString(_userPrefsKey);
    if (str == null) return null;
    return jsonDecode(str) as Map<String, dynamic>;
  }
  
  Future<void> updatePreference(String key, dynamic value) async {
    final prefs = await getUserPreferences() ?? {};
    prefs[key] = value;
    await saveUserPreferences(prefs);
  }
  
  // ==================== Habits Cache ====================
  
  Future<void> cacheHabits(List<Map<String, dynamic>> habits) async {
    final p = await _preferences;
    await p.setString(_habitsKey, jsonEncode(habits));
    await _updateLastSync('habits');
  }
  
  Future<List<Map<String, dynamic>>?> getCachedHabits() async {
    final p = await _preferences;
    final str = p.getString(_habitsKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }
  
  // ==================== Messages Cache ====================
  
  Future<void> cacheMessages(List<Map<String, dynamic>> messages) async {
    final p = await _preferences;
    // Only keep last 100 messages
    final limited = messages.length > 100 
        ? messages.sublist(messages.length - 100) 
        : messages;
    await p.setString(_messagesKey, jsonEncode(limited));
    await _updateLastSync('messages');
  }
  
  Future<List<Map<String, dynamic>>?> getCachedMessages() async {
    final p = await _preferences;
    final str = p.getString(_messagesKey);
    if (str == null) return null;
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }
  
  Future<void> addMessageToCache(Map<String, dynamic> message) async {
    final messages = await getCachedMessages() ?? [];
    messages.add(message);
    await cacheMessages(messages);
  }
  
  // ==================== Offline Queue ====================
  
  Future<void> addToOfflineQueue(Map<String, dynamic> request) async {
    final p = await _preferences;
    final queue = await getOfflineQueue();
    queue.add({
      ...request,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    await p.setString(_offlineQueueKey, jsonEncode(queue));
  }
  
  Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    final p = await _preferences;
    final str = p.getString(_offlineQueueKey);
    if (str == null) return [];
    return (jsonDecode(str) as List).cast<Map<String, dynamic>>();
  }
  
  Future<void> clearOfflineQueue() async {
    final p = await _preferences;
    await p.remove(_offlineQueueKey);
  }
  
  Future<void> removeFromOfflineQueue(String requestId) async {
    final queue = await getOfflineQueue();
    queue.removeWhere((item) => item['requestId'] == requestId);
    final p = await _preferences;
    await p.setString(_offlineQueueKey, jsonEncode(queue));
  }
  
  // ==================== Sync Status ====================
  
  Future<void> _updateLastSync(String type) async {
    final p = await _preferences;
    final lastSync = await getLastSync();
    lastSync[type] = DateTime.now().toIso8601String();
    await p.setString(_lastSyncKey, jsonEncode(lastSync));
  }
  
  Future<Map<String, String>> getLastSync() async {
    final p = await _preferences;
    final str = p.getString(_lastSyncKey);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }
  
  Future<DateTime?> getLastSyncTime(String type) async {
    final lastSync = await getLastSync();
    final timeStr = lastSync[type];
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }
  
  // ==================== Clear Data ====================
  
  Future<void> clearAll() async {
    final p = await _preferences;
    await p.clear();
  }
  
  Future<void> clearUserData() async {
    final p = await _preferences;
    await p.remove(_userPrefsKey);
    await p.remove(_habitsKey);
    await p.remove(_messagesKey);
    await p.remove(_offlineQueueKey);
  }
}

// Global instance
final localStorage = LocalStorage();
