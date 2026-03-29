enum Tone {
  calm,
  gentle,
  reflective,
  supportive,
  encouraging,
}

enum SafetyFlag {
  none,
  monitor,
  escalate,
}

class AIResponse {
  final String text;
  final Tone tone;
  final List<String> suggestions;
  final FollowUp? followUp;
  final SafetyFlag safetyFlag;
  
  const AIResponse({
    required this.text,
    this.tone = Tone.calm,
    this.suggestions = const [],
    this.followUp,
    this.safetyFlag = SafetyFlag.none,
  });
}

class FollowUp {
  final int inDays;
  final String intent;
  final String? customPrompt;
  
  const FollowUp({
    this.inDays = 2,
    this.intent = 'energy_check',
    this.customPrompt,
  });
}

class DailyInsight {
  final String id;
  final String text;
  final String season;
  final DateTime? generatedAt;
  final Map<String, dynamic> context;
  
  const DailyInsight({
    required this.id,
    required this.text,
    required this.season,
    this.generatedAt,
    this.context = const {},
  });
}

class GentleSuggestion {
  final String id;
  final String text;
  final String category;
  final bool isCompleted;
  final String? iconName;
  
  const GentleSuggestion({
    required this.id,
    required this.text,
    required this.category,
    this.isCompleted = false,
    this.iconName,
  });
  
  GentleSuggestion copyWith({
    String? id,
    String? text,
    String? category,
    bool? isCompleted,
    String? iconName,
  }) {
    return GentleSuggestion(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      iconName: iconName ?? this.iconName,
    );
  }
}

class SeasonInsight {
  final String season;
  final String insight;
  final List<String> foodSuggestions;
  final List<String> stretchRoutines;
  final List<String> sleepRituals;
  
  const SeasonInsight({
    required this.season,
    required this.insight,
    this.foodSuggestions = const [],
    this.stretchRoutines = const [],
    this.sleepRituals = const [],
  });
}
