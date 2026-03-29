import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/reflection.dart';

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
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  ReflectionNotifier() : super(const ReflectionState()) {
    loadReflectionData();
  }

  Future<void> loadReflectionData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(
        '/api/v1/seasons/reflection/list',
        queryParameters: {'user_id': 'seasons-user'},
      );

      final data = response.data as List;
      final history = data.map((item) => _parseReflection(item)).toList();

      state = state.copyWith(
        history: history,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to empty on error
      state = state.copyWith(
        history: [],
        isLoading: false,
        error: e.toString(),
      );
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
      final moodStr = _moodToString(mood);
      final energyStr = _energyToString(energy);
      final sleepStr = _sleepToString(sleep);

      await _dio.post(
        '/api/v1/seasons/reflection/submit',
        data: {
          'user_id': 'seasons-user',
          'mood': moodStr,
          'energy': energyStr,
          'sleep': sleepStr,
          'notes': notes,
        },
      );

      final newReflection = DailyReflection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'seasons-user',
        date: DateTime.now(),
        mood: mood,
        energy: energy,
        sleep: sleep,
        notes: notes,
      );

      state = state.copyWith(
        history: [newReflection, ...state.history],
        streakDays: state.streakDays + 1,
        isSubmitting: false,
      );
    } catch (e) {
      // Still update UI optimistically
      final newReflection = DailyReflection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'seasons-user',
        date: DateTime.now(),
        mood: mood,
        energy: energy,
        sleep: sleep,
        notes: notes,
      );

      state = state.copyWith(
        history: [newReflection, ...state.history],
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteReflection(String id) async {
    state = state.copyWith(
      history: state.history.where((r) => r.id != id).toList(),
    );
  }

  DailyReflection _parseReflection(Map<String, dynamic> json) {
    return DailyReflection(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? 'seasons-user',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      mood: _stringToMood(json['mood'] ?? 'calm'),
      energy: _stringToEnergy(json['energy'] ?? 'medium'),
      sleep: _stringToSleep(json['sleep'] ?? 'good'),
      notes: json['notes'],
    );
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
