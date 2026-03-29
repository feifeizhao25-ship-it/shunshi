import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/domain/entities/ai_response.dart';

void main() {
  group('AIResponse', () {
    test('creates an AI response with required fields', () {
      const response = AIResponse(
        text: 'Hello, how are you feeling today?',
      );

      expect(response.text, 'Hello, how are you feeling today?');
      expect(response.tone, Tone.calm);
      expect(response.suggestions, isEmpty);
      expect(response.followUp, isNull);
      expect(response.safetyFlag, SafetyFlag.none);
    });

    test('creates an AI response with all optional fields', () {
      const response = AIResponse(
        text: 'Try this breathing exercise.',
        tone: Tone.gentle,
        suggestions: ['Take a deep breath', 'Stretch your neck'],
        followUp: FollowUp(
          inDays: 2,
          intent: 'check_in',
        ),
        safetyFlag: SafetyFlag.none,
      );

      expect(response.tone, Tone.gentle);
      expect(response.suggestions.length, 2);
      expect(response.followUp!.inDays, 2);
      expect(response.followUp!.intent, 'check_in');
    });
  });

  group('Tone', () {
    test('has all expected tones', () {
      expect(Tone.values, contains(Tone.calm));
      expect(Tone.values, contains(Tone.gentle));
      expect(Tone.values, contains(Tone.reflective));
      expect(Tone.values, contains(Tone.supportive));
      expect(Tone.values, contains(Tone.encouraging));
    });
  });

  group('SafetyFlag', () {
    test('has correct values', () {
      expect(SafetyFlag.values, contains(SafetyFlag.none));
      expect(SafetyFlag.values, contains(SafetyFlag.monitor));
      expect(SafetyFlag.values, contains(SafetyFlag.escalate));
    });

    test('default safety flag is none', () {
      const response = AIResponse(text: 'Hello');
      expect(response.safetyFlag, SafetyFlag.none);
    });
  });

  group('FollowUp', () {
    test('creates with default values', () {
      const followUp = FollowUp();

      expect(followUp.inDays, 2);
      expect(followUp.intent, 'energy_check');
      expect(followUp.customPrompt, isNull);
    });

    test('creates with custom values', () {
      const followUp = FollowUp(
        inDays: 7,
        intent: 'weekly_reflection',
        customPrompt: 'How did this week feel compared to last week?',
      );

      expect(followUp.inDays, 7);
      expect(followUp.intent, 'weekly_reflection');
      expect(followUp.customPrompt, contains('this week'));
    });
  });

  group('DailyInsight', () {
    test('creates a daily insight with all fields', () {
      final generatedAt = DateTime(2025, 3, 20, 8, 0);
      final insight = DailyInsight(
        id: 'ins_001',
        text: 'Spring energy invites you to start something new.',
        season: 'spring',
        generatedAt: generatedAt,
        context: {'temperature': 'mild'},
      );

      expect(insight.id, 'ins_001');
      expect(insight.text, contains('Spring'));
      expect(insight.season, 'spring');
      expect(insight.generatedAt, generatedAt);
      expect(insight.context['temperature'], 'mild');
    });

    test('creates a daily insight without optional fields', () {
      const insight = DailyInsight(
        id: 'ins_002',
        text: 'Take a deep breath.',
        season: 'all',
      );

      expect(insight.generatedAt, isNull);
      expect(insight.context, isEmpty);
    });
  });

  group('GentleSuggestion', () {
    test('creates a suggestion with required fields', () {
      const suggestion = GentleSuggestion(
        id: 'sug_001',
        text: 'Take a short walk',
        category: 'movement',
      );

      expect(suggestion.id, 'sug_001');
      expect(suggestion.text, 'Take a short walk');
      expect(suggestion.category, 'movement');
      expect(suggestion.isCompleted, false);
      expect(suggestion.iconName, isNull);
    });

    test('creates a suggestion with optional fields', () {
      const suggestion = GentleSuggestion(
        id: 'sug_002',
        text: 'Brew some tea',
        category: 'ritual',
        isCompleted: true,
        iconName: 'tea',
      );

      expect(suggestion.isCompleted, true);
      expect(suggestion.iconName, 'tea');
    });

    test('copyWith toggles isCompleted', () {
      const original = GentleSuggestion(
        id: 'sug_001',
        text: 'Drink water',
        category: 'wellness',
        isCompleted: false,
      );

      final toggled = original.copyWith(isCompleted: true);

      expect(original.isCompleted, false);
      expect(toggled.isCompleted, true);
      expect(toggled.id, 'sug_001'); // unchanged
      expect(toggled.text, 'Drink water'); // unchanged
    });
  });

  group('SeasonInsight', () {
    test('creates a season insight with all fields', () {
      const insight = SeasonInsight(
        season: 'spring',
        insight: 'Renewal and gentle growth.',
        foodSuggestions: ['Spinach', 'Asparagus', 'Green tea'],
        stretchRoutines: ['Morning sun salutation'],
        sleepRituals: ['Open window for fresh air'],
      );

      expect(insight.season, 'spring');
      expect(insight.foodSuggestions.length, 3);
      expect(insight.stretchRoutines, isNotEmpty);
      expect(insight.sleepRituals, isNotEmpty);
    });

    test('creates season insight with empty suggestion lists', () {
      const insight = SeasonInsight(
        season: 'summer',
        insight: 'Stay cool and hydrated.',
      );

      expect(insight.foodSuggestions, isEmpty);
      expect(insight.stretchRoutines, isEmpty);
      expect(insight.sleepRituals, isEmpty);
    });
  });
}
