import 'package:share_plus/share_plus.dart';

/// Share Service — SEASONS Global
/// Generates shareable content for social media and messaging apps

class ShareService {
  /// Share a reflection as a text card
  static Future<void> shareReflection({
    required String mood,
    required String energy,
    required String sleep,
    String? note,
    required String season,
  }) async {
    final card = _buildReflectionCard(mood, energy, sleep, note, season);
    await Share.share(
      card,
      subject: 'My SEASONS Reflection',
    );
  }

  /// Share a seasonal insight
  static Future<void> shareSeasonInsight({
    required String season,
    required String insight,
  }) async {
    final emoji = _seasonEmoji(season);
    final card = '''
$emoji $season reflection

"$insight"

Shared from SEASONS — Your calm lifestyle companion
#SEASONS #${season.capitalize()} #Mindfulness #SelfCare
''';
    await Share.share(card.trim(), subject: 'SEASONS $season insight');
  }

  /// Share a daily insight
  static Future<void> shareDailyInsight({
    required String insight,
    required String season,
  }) async {
    final emoji = _seasonEmoji(season);
    final card = '''
$emoji Daily Insight

"$insight"

— from SEASONS
Your calm lifestyle companion 🌿
#Mindfulness #DailyInsight #Calm
''';
    await Share.share(card.trim(), subject: 'My SEASONS Daily Insight');
  }

  /// Share a gratitude item
  static Future<void> shareGratitude({
    required List<String> gratitudeItems,
  }) async {
    final items = gratitudeItems
        .map((item) => '✧ $item')
        .join('\n');
    final card = '''
🌿 Today I'm grateful for...

$items

Shared from SEASONS — Your calm lifestyle companion
#Gratitude #Mindfulness
''';
    await Share.share(card.trim(), subject: 'My SEASONS Gratitude');
  }

  /// Share an achievement/streak
  static Future<void> shareStreak({
    required int days,
  }) async {
    final card = '''
🔥 $days-day streak on SEASONS

Taking a moment each day to breathe, reflect, and find calm. This is my wellness practice.

Join me on SEASONS 🌿
#MindfulnessStreak #SelfCare #Wellness
''';
    await Share.share(card.trim(), subject: 'My SEASONS Streak');
  }

  /// Share a suggestion/completion
  static Future<void> shareSuggestionCompletion({
    required String suggestionText,
    required String category,
  }) async {
    final emoji = _categoryEmoji(category);
    final card = '''
$emoji $category completed

"$suggestionText"

Taking it one small moment at a time. 🌿
#Mindfulness #Wellness #SmallSteps
''';
    await Share.share(card.trim(), subject: 'SEASONS $category');
  }

  static String _buildReflectionCard(
    String mood,
    String energy,
    String sleep,
    String? note,
    String season,
  ) {
    final emoji = _seasonEmoji(season);
    final noteSection = note != null && note.isNotEmpty
        ? '\nNote: $note'
        : '';

    return '''
$emoji My SEASONS Reflection

Mood: $mood
Energy: $energy
Sleep: $sleep$noteSection

Taking a moment to pause and reflect.
#Reflection #Mindfulness #SEASONS
'''.trim();
  }

  static String _seasonEmoji(String season) {
    switch (season.toLowerCase()) {
      case 'spring': return '🌱';
      case 'summer': return '☀️';
      case 'autumn': return '🍂';
      case 'winter': return '❄️';
      default: return '🌿';
    }
  }

  static String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'breathing': return '🫁';
      case 'movement': return '🧘';
      case 'ritual': return '🍵';
      case 'unwind': return '🌙';
      case 'wellness': return '💧';
      case 'reflection': return '📝';
      case 'awareness': return '👀';
      default: return '🌿';
    }
  }
}

// String extension for capitalize
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
