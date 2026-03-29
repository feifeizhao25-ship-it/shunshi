import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/reflection.dart';

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
  ReflectionNotifier() : super(const ReflectionState()) {
    loadReflectionData();
  }
  
  Future<void> loadReflectionData() async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock data
    final history = [
      DailyReflection(
        id: '1',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        mood: Mood.calm,
        energy: EnergyLevel.medium,
        sleep: SleepQuality.good,
        notes: 'Had a wonderful morning meditation session. Feeling centered and at peace with where things are.',
      ),
      DailyReflection(
        id: '2',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 2)),
        mood: Mood.grateful,
        energy: EnergyLevel.high,
        sleep: SleepQuality.excellent,
        notes: 'Grateful for the sunny weather and a meaningful conversation with a good friend.',
      ),
      DailyReflection(
        id: '3',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 3)),
        mood: Mood.tired,
        energy: EnergyLevel.low,
        sleep: SleepQuality.fair,
        notes: 'A long day at work. Remembered to take a few deep breaths during breaks, which helped.',
      ),
      DailyReflection(
        id: '4',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 4)),
        mood: Mood.happy,
        energy: EnergyLevel.high,
        sleep: SleepQuality.good,
        notes: 'Started the day with a morning walk and it completely shifted my mood for the better.',
      ),
      DailyReflection(
        id: '5',
        userId: 'user1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        mood: Mood.hopeful,
        energy: EnergyLevel.medium,
        sleep: SleepQuality.good,
        notes: 'Set a new intention for the week. Feeling optimistic about what is ahead.',
      ),
    ];
    
    final weeklyReflection = WeeklyReflection(
      id: 'w1',
      userId: 'user1',
      weekStartDate: DateTime.now().subtract(const Duration(days: 7)),
      weekEndDate: DateTime.now(),
      aiSummary: 'You completed 7 reflections this week — a perfect streak. Your mood has been mostly positive, with gratitude and calm appearing most often.',
      aiInsight: 'You had a wonderful week. Your energy dipped mid-week but bounced back strongly. Morning routines seem to make a real difference for you — consider keeping that as a non-negotiable. Your sleep quality has been consistently good, and your overall emotional trend is moving in a positive direction.',
      moodTrend: [Mood.hopeful, Mood.happy, Mood.tired, Mood.grateful, Mood.calm, Mood.happy, Mood.calm],
      averageEnergy: EnergyLevel.medium,
      averageSleep: SleepQuality.good,
      streakDays: 7,
    );
    
    state = state.copyWith(
      history: history,
      weeklyReflection: weeklyReflection,
      streakDays: 7,
      isLoading: false,
    );
  }
  
  Future<void> submitReflection({
    required Mood mood,
    required EnergyLevel energy,
    required SleepQuality sleep,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    final newReflection = DailyReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'user1',
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
  }
  
  Future<void> deleteReflection(String id) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 200));
    
    state = state.copyWith(
      history: state.history.where((r) => r.id != id).toList(),
    );
  }
}

final reflectionProvider = StateNotifierProvider<ReflectionNotifier, ReflectionState>((ref) {
  return ReflectionNotifier();
});
