import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/reflection.dart';

void main() {
  group('Mood', () {
    test('has expected values', () {
      expect(Mood.values, contains(Mood.calm));
      expect(Mood.values, contains(Mood.happy));
      expect(Mood.values, contains(Mood.energetic));
      expect(Mood.values, contains(Mood.tired));
      expect(Mood.values, contains(Mood.anxious));
      expect(Mood.values, contains(Mood.sad));
      expect(Mood.values, contains(Mood.grateful));
      expect(Mood.values, contains(Mood.hopeful));
    });

    test('has correct number of values', () {
      expect(Mood.values.length, 8);
    });
  });

  group('EnergyLevel', () {
    test('has expected values', () {
      expect(EnergyLevel.values, contains(EnergyLevel.low));
      expect(EnergyLevel.values, contains(EnergyLevel.medium));
      expect(EnergyLevel.values, contains(EnergyLevel.high));
    });
  });

  group('DailyReflection', () {
    test('can be created with required fields', () {
      final reflection = DailyReflection(
        id: 'test-id',
        userId: 'user-1',
        date: DateTime(2025, 1, 1),
        mood: Mood.calm,
        energy: EnergyLevel.medium,
        sleep: SleepQuality.good,
        notes: 'Test note',
      );
      expect(reflection.mood, Mood.calm);
      expect(reflection.notes, 'Test note');
      expect(reflection.energy, EnergyLevel.medium);
      expect(reflection.sleep, SleepQuality.good);
    });
  });

  group('WeeklyReflection', () {
    test('can be created with required fields', () {
      final reflection = WeeklyReflection(
        id: 'week-1',
        userId: 'user-1',
        weekStartDate: DateTime(2025, 1, 6),
        weekEndDate: DateTime(2025, 1, 12),
        aiSummary: 'Good week',
        aiInsight: 'Keep it up',
      );
      expect(reflection.aiSummary, 'Good week');
      expect(reflection.averageEnergy, EnergyLevel.medium);
    });
  });
}
