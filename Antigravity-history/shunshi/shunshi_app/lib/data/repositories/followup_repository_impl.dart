import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/follow_up_plan.dart';
import '../../domain/repositories/followup_repository.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final SharedPreferences _prefs;
  static const _prefix = 'followup_';

  FollowUpRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  String _key(String userId) => '$_prefix$userId';

  @override
  Future<void> saveFollowUp(FollowUpPlan plan, {required String userId}) async {
    final plans = await getPendingFollowUps(userId);
    final updated = plan.copyWith(scheduledAt: DateTime.now());
    plans.add(updated);
    await _prefs.setString(
      _key(userId),
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<List<FollowUpPlan>> getPendingFollowUps(String userId) async {
    final raw = _prefs.getString(_key(userId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FollowUpPlan.fromJson(e as Map<String, dynamic>))
          .where((p) => !p.completed)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> markCompleted(String userId, String intentId) async {
    final all = await getPendingFollowUps(userId);
    final updated = all
        .map((p) => p.intent == intentId ? p.copyWith(completed: true) : p)
        .toList();
    await _prefs.setString(
      _key(userId),
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<void> clearAll(String userId) async {
    await _prefs.remove(_key(userId));
  }
}
