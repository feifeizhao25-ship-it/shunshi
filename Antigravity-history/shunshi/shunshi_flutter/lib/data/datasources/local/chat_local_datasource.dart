import 'dart:convert';
import '../../../core/storage/local_storage.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/solar_term.dart';
import '../../../domain/entities/follow_up_plan.dart';

/// 聊天本地数据源（本地持久化）
class ChatLocalDatasource {
  final LocalStorage _storage;

  ChatLocalDatasource(this._storage);

  // ─── Messages ───────────────────
  Future<void> saveMessage(String sessionId, Message message) async {
    final key = 'chat_messages_$sessionId';
    final messages = await getMessages(sessionId);
    messages.add(message);
    // 只保留最近100条
    final toSave = messages.length > 100
        ? messages.sublist(messages.length - 100)
        : messages;
    final jsonList = toSave.map((m) => m.toJson()).toList();
    await _storage.setString(key, jsonEncode(jsonList));
  }

  Future<List<Message>> getMessages(String sessionId) async {
    final key = 'chat_messages_$sessionId';
    final raw = await _storage.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Daily Plan Cache ───────────
  Future<void> saveDailyPlan(DailyPlan plan) async {
    await _storage.setString(
        'daily_plan_${plan.planDate}', jsonEncode(plan.toJson()));
  }

  Future<DailyPlan?> getDailyPlan(String dateKey) async {
    final raw = await _storage.getString('daily_plan_$dateKey');
    if (raw == null) return null;
    try {
      return DailyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Follow-up Plans ────────────
  Future<void> saveFollowUp(FollowUpPlan plan) async {
    final key = 'follow_ups';
    final plans = await getFollowUps();
    plans.add(plan);
    final jsonList = plans.map((p) => p.toJson()).toList();
    await _storage.setString(key, jsonEncode(jsonList));
  }

  Future<List<FollowUpPlan>> getFollowUps() async {
    final raw = await _storage.getString('follow_ups');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FollowUpPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> dismissFollowUp(String planId) async {
    final plans = await getFollowUps();
    final updated = plans.map((p) {
      if (p.id == planId) return p.copyWith(isDismissed: true);
      return p;
    }).toList();
    final jsonList = updated.map((p) => p.toJson()).toList();
    await _storage.setString('follow_ups', jsonEncode(jsonList));
  }

  // ─── Presence Record ────────────
  Future<void> savePresenceRecord(String userId, PresenceRecord record) async {
    await _storage.setString('presence_$userId', jsonEncode(record.toJson()));
  }

  Future<PresenceRecord> getPresenceRecord(String userId) async {
    final raw = await _storage.getString('presence_$userId');
    if (raw == null) return const PresenceRecord();
    try {
      return PresenceRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PresenceRecord();
    }
  }

  // ─── Clear Memory ───────────────
  Future<void> clearAllChatData() async {
    // Uses SharedPreferences - would need to iterate keys
    // For now, clear specific known keys
    await _storage.remove('follow_ups');
  }
}
