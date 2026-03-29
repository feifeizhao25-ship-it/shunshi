enum Mood {
  calm,
  happy,
  energetic,
  tired,
  anxious,
  sad,
  grateful,
  hopeful,
}

enum EnergyLevel {
  low,
  medium,
  high,
}

enum SleepQuality {
  poor,
  fair,
  good,
  excellent,
}

class DailyReflection {
  final String id;
  final String userId;
  final DateTime date;
  final Mood mood;
  final EnergyLevel energy;
  final SleepQuality sleep;
  final String? notes;
  final Map<String, dynamic> tags;
  
  const DailyReflection({
    required this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.energy,
    required this.sleep,
    this.notes,
    this.tags = const {},
  });
}

class WeeklyReflection {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String aiSummary;
  final String aiInsight;
  final List<Mood> moodTrend;
  final EnergyLevel averageEnergy;
  final SleepQuality averageSleep;
  final int? streakDays;
  
  const WeeklyReflection({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.aiSummary,
    required this.aiInsight,
    this.moodTrend = const [],
    this.averageEnergy = EnergyLevel.medium,
    this.averageSleep = SleepQuality.good,
    this.streakDays,
  });
}
