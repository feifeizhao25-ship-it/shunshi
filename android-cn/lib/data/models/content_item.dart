/// SEASONS Content Models
library;

/// Content types in SEASONS
enum ContentType {
  breathing,
  stretch,
  teaRitual,
  sleep,
  reflection,
  seasonal,
}

/// Extension for ContentType
extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.breathing:
        return 'Breathing';
      case ContentType.stretch:
        return 'Stretch';
      case ContentType.teaRitual:
        return 'Tea Rituals';
      case ContentType.sleep:
        return 'Sleep';
      case ContentType.reflection:
        return 'Reflection';
      case ContentType.seasonal:
        return 'Seasonal Living';
    }
  }

  String get apiValue {
    switch (this) {
      case ContentType.breathing:
        return 'breathing';
      case ContentType.stretch:
        return 'stretch';
      case ContentType.teaRitual:
        return 'tea_ritual';
      case ContentType.sleep:
        return 'sleep';
      case ContentType.reflection:
        return 'reflection';
      case ContentType.seasonal:
        return 'seasonal';
    }
  }

  String get icon {
    switch (this) {
      case ContentType.breathing:
        return '🌬️';
      case ContentType.stretch:
        return '🧘';
      case ContentType.teaRitual:
        return '🍵';
      case ContentType.sleep:
        return '🌙';
      case ContentType.reflection:
        return '📝';
      case ContentType.seasonal:
        return '🍂';
    }
  }
}

/// Base content item
class ContentItem {
  final String id;
  final ContentType type;
  final String title;
  final String? subtitle;
  final String? useCase;
  final String? season;
  final String? bestTime;
  final int? durationMinutes;
  final List<String>? steps;
  final List<String>? prompts;
  final List<String>? ingredients;
  final List<String>? tags;
  final bool isPremium;

  ContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.useCase,
    this.season,
    this.bestTime,
    this.durationMinutes,
    this.steps,
    this.prompts,
    this.ingredients,
    this.tags,
    this.isPremium = false,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? '',
      type: _parseContentType(json['type']),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      useCase: json['use_case'],
      season: json['season'],
      bestTime: json['best_time'],
      durationMinutes: json['duration_minutes'],
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      prompts: json['prompts'] != null ? List<String>.from(json['prompts']) : null,
      ingredients: json['ingredients'] != null ? List<String>.from(json['ingredients']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.apiValue,
      'title': title,
      'subtitle': subtitle,
      'use_case': useCase,
      'season': season,
      'best_time': bestTime,
      'duration_minutes': durationMinutes,
      'steps': steps,
      'prompts': prompts,
      'ingredients': ingredients,
      'tags': tags,
      'is_premium': isPremium,
    };
  }
}

/// Breathing content specific fields
class BreathingContent extends ContentItem {
  final String? closingLine;

  BreathingContent({
    required super.id,
    required super.title,
    super.subtitle,
    super.useCase,
    super.bestTime,
    super.durationMinutes,
    super.steps,
    super.tags,
    super.isPremium,
    this.closingLine,
  }) : super(type: ContentType.breathing);

  factory BreathingContent.fromJson(Map<String, dynamic> json) {
    return BreathingContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      useCase: json['use_case'],
      bestTime: json['best_time'],
      durationMinutes: json['duration_minutes'],
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      closingLine: json['closing_line'],
    );
  }
}

/// Stretch content specific fields
class StretchContent extends ContentItem {
  final String? bodyFocus;
  final String? caution;
  final String? closingLine;

  StretchContent({
    required super.id,
    required super.title,
    super.subtitle,
    super.useCase,
    super.bestTime,
    super.durationMinutes,
    super.steps,
    super.tags,
    super.isPremium,
    this.bodyFocus,
    this.caution,
    this.closingLine,
  }) : super(type: ContentType.stretch);

  factory StretchContent.fromJson(Map<String, dynamic> json) {
    return StretchContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      useCase: json['use_case'],
      bestTime: json['best_time'],
      durationMinutes: json['duration_minutes'],
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      bodyFocus: json['body_focus'],
      caution: json['caution'],
      closingLine: json['closing_line'],
    );
  }
}

/// Tea Ritual content specific fields
class TeaRitualContent extends ContentItem {
  final String? mood;
  final String? ritualTip;
  final String? closingLine;

  TeaRitualContent({
    required super.id,
    required super.title,
    super.subtitle,
    super.season,
    super.bestTime,
    super.ingredients,
    super.steps,
    super.tags,
    super.isPremium,
    this.mood,
    this.ritualTip,
    this.closingLine,
  }) : super(type: ContentType.teaRitual);

  factory TeaRitualContent.fromJson(Map<String, dynamic> json) {
    return TeaRitualContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      season: json['season'],
      bestTime: json['best_time'],
      ingredients: json['ingredients'] != null ? List<String>.from(json['ingredients']) : null,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      mood: json['mood'],
      ritualTip: json['ritual_tip'],
      closingLine: json['closing_line'],
    );
  }
}

/// Sleep content specific fields
class SleepContent extends ContentItem {
  final String? environmentTip;
  final String? closingLine;

  SleepContent({
    required super.id,
    required super.title,
    super.subtitle,
    super.bestTime,
    super.durationMinutes,
    super.steps,
    super.tags,
    super.isPremium,
    this.environmentTip,
    this.closingLine,
  }) : super(type: ContentType.sleep);

  factory SleepContent.fromJson(Map<String, dynamic> json) {
    return SleepContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      bestTime: json['best_time'],
      durationMinutes: json['duration_minutes'],
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      environmentTip: json['environment_tip'],
      closingLine: json['closing_line'],
    );
  }
}

/// Reflection content specific fields
class ReflectionContent extends ContentItem {
  final String? closingLine;

  ReflectionContent({
    required super.id,
    required super.title,
    super.subtitle,
    super.useCase,
    super.prompts,
    super.tags,
    super.isPremium,
    this.closingLine,
  }) : super(type: ContentType.reflection);

  factory ReflectionContent.fromJson(Map<String, dynamic> json) {
    return ReflectionContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      useCase: json['use_case'],
      prompts: json['prompts'] != null ? List<String>.from(json['prompts']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      closingLine: json['closing_line'],
    );
  }
}

/// Seasonal content specific fields
class SeasonalContent extends ContentItem {
  final String? howItFeels;
  final List<String>? smallPractices;
  final String? foodSuggestion;
  final String? closingLine;

  SeasonalContent({
    required super.id,
    required super.title,
    super.subtitle,
    required super.season,
    super.tags,
    super.isPremium,
    this.howItFeels,
    this.smallPractices,
    this.foodSuggestion,
    this.closingLine,
  }) : super(type: ContentType.seasonal);

  factory SeasonalContent.fromJson(Map<String, dynamic> json) {
    return SeasonalContent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      season: json['season'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPremium: json['is_premium'] ?? false,
      howItFeels: json['how_it_feels'],
      smallPractices: json['3_small_practices'] != null 
          ? List<String>.from(json['3_small_practices']) 
          : null,
      foodSuggestion: json['food_or_drink_suggestion'],
      closingLine: json['closing_line'],
    );
  }
}

/// Helper function to parse content type
ContentType _parseContentType(String? type) {
  switch (type) {
    case 'breathing':
      return ContentType.breathing;
    case 'stretch':
      return ContentType.stretch;
    case 'tea_ritual':
      return ContentType.teaRitual;
    case 'sleep':
      return ContentType.sleep;
    case 'reflection':
      return ContentType.reflection;
    case 'seasonal':
      return ContentType.seasonal;
    default:
      return ContentType.breathing;
  }
}
