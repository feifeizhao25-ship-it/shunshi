import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/reflection.dart';
import '../../data/network/session.dart';

const _baseUrl = AppConstants.baseUrl;

class ReflectionState {
  final List<DailyReflection> history;
  final WeeklyReflection? weeklyReflection;
  final int streakDays;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const ReflectionState({
    this.history = const [],
    this.weeklyReflection,
    this.streakDays = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ReflectionState copyWith({
    List<DailyReflection>? history,
    WeeklyReflection? weeklyReflection,
    int? streakDays,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return ReflectionState(
      history: history ?? this.history,
      weeklyReflection: weeklyReflection ?? this.weeklyReflection,
      streakDays: streakDays ?? this.streakDays,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ReflectionNotifier extends StateNotifier<ReflectionState> {
  final Dio _dio = withSessionAuth(Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )));

  ReflectionNotifier() : super(const ReflectionState()) {
    loadReflectionData();
  }

  Future<void> loadReflectionData() async {
    state = state.copyWith(isLoading: true, error: null);
    final uid = currentUserId();
    if (uid == null) {
      // 没有登录令牌就没有「我的日记」可取（不再用写死的 user-001 去撞别人的数据）。
      state = state.copyWith(history: [], isLoading: false);
      return;
    }
    try {
      final enc = Uri.encodeComponent(uid);
      final response = await _dio.get('/api/v1/journal/entries/$enc', queryParameters: {'limit': 30});
      final entries = journalEntriesFromBody(response.data) ?? const [];
      final history = entries.map(_parseReflection).toList();
      var streak = 0;
      try {
        final s = await _dio.get('/api/v1/journal/streak/$enc');
        final d = s.data is Map && s.data['data'] is Map ? s.data['data'] as Map : const {};
        streak = (d['current_streak'] as num?)?.toInt() ?? 0;
      } catch (_) {}
      state = state.copyWith(history: history, streakDays: streak, isLoading: false);
    } catch (e) {
      state = state.copyWith(history: [], isLoading: false, error: e.toString());
    }
  }

  Future<void> submitReflection({
    required Mood mood,
    required EnergyLevel energy,
    required SleepQuality sleep,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final text = notes?.trim() ?? '';
      // 与后端 POST /api/v1/journal/entry 一一对应：三项都是 1–5 的整数，心情词放进 tags 方便读回。
      await _dio.post('/api/v1/journal/entry', data: {
        ...userIdParam(),
        'mood': _moodScore(mood),
        'energy': _energyScore(energy),
        'sleep_quality': _sleepScore(sleep),
        if (text.isNotEmpty) 'notes': text,
        'tags': [_moodToString(mood)],
      });
      await loadReflectionData();
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      // 保存失败就如实报错，不再在界面上假装已保存。
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<void> deleteReflection(String id) async {
    state = state.copyWith(
      history: state.history.where((r) => r.id != id).toList(),
    );
  }

  DailyReflection _parseReflection(Map<String, dynamic> json) {
    final tags = (json['tags'] as List?)?.map((e) => '$e').toList() ?? const <String>[];
    final moodScore = (json['mood'] as num?)?.toInt() ?? 3;
    final energyScore = (json['energy'] as num?)?.toInt() ?? 3;
    final sleepScore = (json['sleep_quality'] as num?)?.toInt() ?? 3;
    final tagMood = tags.isEmpty ? null : tags.first;
    return DailyReflection(
      id: '${json['entry_id'] ?? json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
      mood: tagMood != null && _knownMoods.contains(tagMood) ? _stringToMood(tagMood) : _scoreToMood(moodScore),
      energy: energyScore <= 2 ? EnergyLevel.low : (energyScore == 3 ? EnergyLevel.medium : EnergyLevel.high),
      sleep: sleepScore <= 1 ? SleepQuality.poor : (sleepScore <= 3 ? SleepQuality.fair : (sleepScore == 4 ? SleepQuality.good : SleepQuality.excellent)),
      notes: (json['notes'] as String?)?.isEmpty ?? true ? null : json['notes'] as String?,
    );
  }

  static const _knownMoods = {'grateful', 'calm', 'happy', 'tired', 'hopeful', 'anxious', 'sad'};

  int _moodScore(Mood m) {
    switch (m) {
      case Mood.grateful: case Mood.happy: case Mood.energetic: return 5;
      case Mood.calm: case Mood.hopeful: return 4;
      case Mood.tired: return 3;
      case Mood.anxious: case Mood.sad: return 2;
    }
  }

  Mood _scoreToMood(int s) => s >= 5 ? Mood.happy : (s == 4 ? Mood.calm : (s == 3 ? Mood.tired : Mood.sad));
  int _energyScore(EnergyLevel e) => e == EnergyLevel.low ? 2 : (e == EnergyLevel.medium ? 3 : 4);
  int _sleepScore(SleepQuality s) {
    switch (s) {
      case SleepQuality.poor: return 1;
      case SleepQuality.fair: return 3;
      case SleepQuality.good: return 4;
      case SleepQuality.excellent: return 5;
    }
  }

  String _moodToString(Mood mood) {
    switch (mood) {
      case Mood.grateful: return 'grateful';
      case Mood.calm: return 'calm';
      case Mood.happy: return 'happy';
      case Mood.tired: return 'tired';
      case Mood.hopeful: return 'hopeful';
      case Mood.anxious: return 'anxious';
      case Mood.sad: return 'sad';
      case Mood.energetic: return 'happy'; // map to closest
    }
  }

  Mood _stringToMood(String s) {
    switch (s.toLowerCase()) {
      case 'grateful': return Mood.grateful;
      case 'calm': return Mood.calm;
      case 'happy': return Mood.happy;
      case 'tired': return Mood.tired;
      case 'hopeful': return Mood.hopeful;
      case 'anxious': return Mood.anxious;
      case 'sad': return Mood.sad;
      case 'reflective': return Mood.calm; // map to closest
      default: return Mood.calm;
    }
  }

  String _energyToString(EnergyLevel e) {
    switch (e) {
      case EnergyLevel.low: return 'low';
      case EnergyLevel.medium: return 'medium';
      case EnergyLevel.high: return 'high';
    }
  }

  EnergyLevel _stringToEnergy(String s) {
    switch (s.toLowerCase()) {
      case 'low': return EnergyLevel.low;
      case 'medium': return EnergyLevel.medium;
      case 'high': return EnergyLevel.high;
      case 'excellent': return EnergyLevel.high; // map to high
      default: return EnergyLevel.medium;
    }
  }

  String _sleepToString(SleepQuality s) {
    switch (s) {
      case SleepQuality.poor: return 'poor';
      case SleepQuality.fair: return 'fair';
      case SleepQuality.good: return 'good';
      case SleepQuality.excellent: return 'excellent';
    }
  }

  SleepQuality _stringToSleep(String s) {
    switch (s.toLowerCase()) {
      case 'poor': return SleepQuality.poor;
      case 'fair': return SleepQuality.fair;
      case 'good': return SleepQuality.good;
      case 'excellent': return SleepQuality.excellent;
      default: return SleepQuality.good;
    }
  }
}

final reflectionProvider = StateNotifierProvider<ReflectionNotifier, ReflectionState>((ref) {
  return ReflectionNotifier();
});
