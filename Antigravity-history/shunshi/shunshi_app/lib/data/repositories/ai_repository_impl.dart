import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/ai_router_api.dart';
import '../../data/models/ai_response.dart';
import '../../data/models/message.dart';
import '../../data/models/user_context.dart';
import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRouterApi _api;
  final SharedPreferences _prefs;

  static const String _chatHistoryPrefix = 'chat_history_';
  static const int _maxLocalHistory = 200;

  AiRepositoryImpl({required AiRouterApi api, required SharedPreferences prefs})
      : _api = api,
        _prefs = prefs;

  @override
  Future<AiResponse> sendMessage({
    required String userId,
    required UserContext context,
    required String message,
  }) {
    return _api.sendMessage(
      userId: userId,
      context: context,
      message: message,
      isPremium: context.isPremium,
    );
  }

  @override
  Future<AiResponse> generateDailyPlan({
    required String userId,
    required UserContext context,
  }) {
    return _api.generateDailyPlan(
      userId: userId,
      context: context,
      isPremium: context.isPremium,
    );
  }

  @override
  Future<List<Message>> getChatHistory({
    required String userId,
    int limit = 50,
  }) async {
    final raw = _prefs.getString('$_chatHistoryPrefix$userId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMessage(String userId, Message message) async {
    final history = await getChatHistory(userId: userId, limit: _maxLocalHistory);
    history.add(message);
    // Keep latest N messages
    final trimmed = history.length > _maxLocalHistory
        ? history.sublist(history.length - _maxLocalHistory)
        : history;
    await _prefs.setString(
      '$_chatHistoryPrefix$userId',
      jsonEncode(trimmed.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> clearMemory(String userId) async {
    await _prefs.remove('$_chatHistoryPrefix$userId');
  }
}
