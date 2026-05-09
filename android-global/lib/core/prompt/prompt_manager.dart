// lib/core/prompt/prompt_manager.dart

import '../config/models.dart';

/// Prompt Manager - Handles modular Prompt loading, versioning and assembly
class PromptManager {

  /// Build complete Prompt
  Future<String> build(AIRequest request) async {
    final intent = request.intent ?? 'chat';
    final taskPrompt = _getTaskPrompt(intent);

    return '''
You are "SEASONS", an AI wellness consultant. Your role is to accompany users with a warm, professional tone and provide personalized wellness tips.

## Current Task
$taskPrompt

## Output Requirements
Please output in JSON format with the following fields:
- text: Response content
- tone: Tone (gentle/warm/professional)
- care_status: Care status (stable/concerned/attention)
- presence_level: Proactivity level (low/normal/high)
- safety_flag: Safety flag (none/caution/blocked)
''';
  }

  String _getTaskPrompt(String intent) {
    switch (intent) {
      case 'daily_plan':
        return 'Generate a daily wellness plan for the user, including dietary suggestions, exercise recommendations, and emotional regulation.';
      case 'weekly_summary':
        return 'Summarize the user\'s wellness data this week and provide suggestions for next week.';
      case 'solar_term':
        return 'Provide Solar Term wellness guidance based on the current solar term.';
      case 'health_assessment':
        return 'Assess the user\'s current health status and provide wellness tips.';
      case 'dietary_advice':
        return 'Provide dietary conditioning suggestions based on the user\'s body type and current season.';
      case 'sleep_advice':
        return 'Analyze the user\'s sleep status and provide improvement suggestions.';
      case 'emotion_support':
        return 'Accompany the user with a warm tone and provide emotional regulation suggestions.';
      default:
        return 'Respond to the user\'s wellness inquiry in a friendly, professional manner.';
    }
  }
}

/// Prompt version
class PromptVersion {
  final String id;
  final String version;
  final String content;
  final DateTime createdAt;

  const PromptVersion({
    required this.id,
    required this.version,
    required this.content,
    required this.createdAt,
  });
}
