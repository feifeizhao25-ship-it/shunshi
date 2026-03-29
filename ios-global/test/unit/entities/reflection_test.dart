import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/reflection.dart';

void main() {
  group('DailyReflection', () {
    test('creates a daily reflection with all fields', () {
      final date = DateTime(2025, 3, 20);
      final reflection = DailyReflection(
        id: 'ref_001',
        userId: 'usr_001',
        date: date,
        mood: Mood.calm,
        energy: EnergyLevel.medium,
        sleep: SleepQuality.good,
        notes: 'Felt good after the morning walk.',
        tags: {'weather': 'sunny'},
      );

      expect(reflection.id, 'ref_001');
      expect(reflection.mood, Mood.calm);
      expect(reflection.energy, EnergyLevel.medium);
      expect(reflection.sleep, SleepQuality.good);
      expect(reflection.notes, 'Felt good after the morning walk.');
      expect(reflection.tags['weather'], 'sunny');
    });

    test('creates a daily reflection without optional notes', () {
      final reflection = DailyReflection(
        id: 'ref_002',
        userId: 'usr_001',
        date: DateTime(2025, 3, 19),
        mood: Mood.grateful,
        energy: EnergyLevel.high,
        sleep: SleepQuality.excellent,
      );

      expect(reflection.notes, isNull);
      expect(reflection.tags, isEmpty);
    });

    test('Mood enum has all expected values', () {
      expect(Mood.values, contains(Mood.calm));
      expect(Mood.values, contains(Mood.happy));
      expect(Mood.values, contains(Mood.energetic));
      expect(Mood.values, contains(Mood.tired));
      expect(Mood.values, contains(Mood.anxious));
      expect(Mood.values, contains(Mood.sad));
      expect(Mood.values, contains(Mood.grateful));
      expect(Mood.values, contains(Mood.hopeful));
    });

    test('EnergyLevel enum has correct values', () {
      expect(EnergyLevel.values, contains(EnergyLevel.low));
      expect(EnergyLevel.values, contains(EnergyLevel.medium));
      expect(EnergyLevel.values, contains(EnergyLevel.high));
    });

    test('SleepQuality enum has correct values', () {
      expect(SleepQuality.values, contains(SleepQuality.poor));
      expect(SleepQuality.values, contains(SleepQuality.fair));
      expect(SleepQuality.values, contains(SleepQuality.good));
      expect(SleepQuality.values, contains(SleepQuality.excellent));
    });
  });

  group('WeeklyReflection', () {
    test('creates a weekly reflection with all fields', () {
      final weekStart = DateTime(2025, 3, 10);
      final weekEnd = DateTime(2025, 3, 16);

      final weekly = WeeklyReflection(
        id: 'wk_001',
        userId: 'usr_001',
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        aiSummary: 'A calm week overall with good energy levels.',
        aiInsight: 'Your sleep improved mid-week. Keep the evening routine consistent.',
        moodTrend: [Mood.good, Mood.calm, Mood.grateful, Mood.energetic, Mood.calm, Mood.happy, Mood.hopeful],
        averageEnergy: EnergyLevel.medium,
        averageSleep: SleepQuality.good,
        streakDays: 5,
      );

      expect(weekly.id, 'wk_001');
      expect(weekly.aiSummary, contains('calm week'));
      expect(weekly.moodTrend.length, 7);
      expect(weekly.streakDays, 5);
      expect(weekly.averageEnergy, EnergyLevel.medium);
    });

    test('creates weekly reflection with default energy and sleep', () {
      final weekly = WeeklyReflection(
        id: 'wk_002',
        userId: 'usr_001',
        weekStartDate: DateTime(2025, 3, 17),
        weekEndDate: DateTime(2025, 3, 23),
        aiSummary: 'A varied week.',
        aiInsight: 'Try to maintain consistent wake times.',
      );

      expect(weekly.averageEnergy, EnergyLevel.medium);
      expect(weekly.averageSleep, SleepQuality.good);
      expect(weekly.streakDays, isNull);
    });

    test('moodTrend can be empty', () {
      final weekly = WeeklyReflection(
        id: 'wk_003',
        userId: 'usr_001',
        weekStartDate: DateTime(2025, 3, 24),
        weekEndDate: DateTime(2025, 3, 30),
        aiSummary: 'Not enough data.',
        aiInsight: 'Log your reflections daily.',
        moodTrend: [],
      );

      expect(weekly.moodTrend, isEmpty);
    });
  });
}
