// lib/core/prompt/prompt_builder.dart

import 'core_prompts.dart';
import 'policy_prompts.dart';
import 'task_prompts.dart';
import '../config/models.dart';

/// Prompt Builder - Combines three layers of Prompts
class PromptBuilder {
  /// Build complete Prompt
  /// Combines: Core + Policy + Task + Context
  static PromptBuildResult build({
    required String userId,
    required TaskType taskType,
    required String userMessage,
    required UserContext userContext,
  }) {
    // 1. Core Prompt
    final corePrompt = CorePrompts.getCurrent();

    // 2. Policy Prompt
    final policyPrompt = PolicyPrompts.getPolicy(userContext.isPremium);

    // 3. Task Prompt
    final taskPrompt = TaskPrompts.getTask(taskType);

    // 4. User Context
    final contextPrompt = _buildContext(userContext);

    // 5. Output Schema
    final outputSchema = _getOutputSchema(taskType);

    // Combine
    final fullPrompt = '''
$corePrompt

---

$policyPrompt

---

## Current Task
$taskPrompt

---

## User Context
$contextPrompt

---

## User Message
$userMessage

---

## Output Requirements
Please output in JSON format:
$outputSchema
''';

    // Estimate tokens
    final estimatedTokens = _estimateTokens(fullPrompt);

    return PromptBuildResult(
      prompt: fullPrompt,
      version: 'v1.0',
      estimatedTokens: estimatedTokens,
      model: _selectModel(userContext.isPremium, taskType),
    );
  }

  /// Build user context
  static String _buildContext(UserContext ctx) {
    final buffer = StringBuffer();

    buffer.writeln('## User Info');
    buffer.writeln('- User ID: ${ctx.userId}');
    buffer.writeln('- Body Type: ${ctx.constitution ?? "Unidentified"}');
    buffer.writeln('- Current Season: ${ctx.currentSeason}');
    buffer.writeln('- User Type: ${ctx.isPremium ? "Premium" : "Free"}');

    if (ctx.healthGoals.isNotEmpty) {
      buffer.writeln('- Wellness Goals: ${ctx.healthGoals.join(", ")}');
    }

    if (ctx.recentTopics.isNotEmpty) {
      buffer.writeln('- Recent Topics: ${ctx.recentTopics.join(", ")}');
    }

    if (ctx.lastCareStatus != null) {
      buffer.writeln('- Last Care Status: ${ctx.lastCareStatus}');
    }

    if (ctx.followUpContext != null) {
      buffer.writeln('\n## Follow-up Context');
      buffer.writeln('- Last Conversation: ${ctx.followUpContext}');
    }

    return buffer.toString();
  }

  /// Get output schema
  static String _getOutputSchema(TaskType taskType) {
    // Base schema
    const baseSchema = '''
{
  "text": "Response content",
  "tone": "gentle|warm|professional",
  "care_status": "stable|concerned|attention",
  "presence_level": "low|normal|high",
  "safety_flag": "none|caution|blocked"
}
''';

    // Schema for follow-up tasks
    const followUpSchema = '''
{
  "text": "Response content",
  "tone": "gentle|warm|professional",
  "care_status": "stable|concerned|attention",
  "follow_up": {
    "in_days": 1-7,
    "intent": "check_in|sleep_check|diet_check|mood_check|exercise_check"
  },
  "offline_encouraged": true|false,
  "presence_level": "low|normal|high",
  "safety_flag": "none|caution|blocked"
}
''';

    // Schema for plan generation tasks
    const planSchema = '''
{
  "text": "Response content",
  "tone": "gentle|warm|professional",
  "care_status": "stable|concerned|attention",
  "plan": {
    "insight": "One-sentence insight",
    "actions": ["Action 1", "Action 2", "Action 3"]
  },
  "presence_level": "low|normal|high",
  "safety_flag": "none|caution|blocked"
}
''';

    switch (taskType) {
      case TaskType.dailyPlan:
      case TaskType.solarTerm:
        return planSchema;
      case TaskType.chat:
      case TaskType.emotionSupport:
      case TaskType.followUp:
        return followUpSchema;
      default:
        return baseSchema;
    }
  }

  /// Select model
  static ModelInfo _selectModel(bool isPremium, TaskType taskType) {
    // Critical tasks use larger model
    const criticalTasks = [
      TaskType.dailyPlan,
      TaskType.solarTerm,
      TaskType.constitution,
    ];

    if (criticalTasks.contains(taskType)) {
      return ModelProvider.premium;
    }

    return isPremium ? ModelProvider.premium : ModelProvider.free;
  }

  /// Estimate tokens
  static int _estimateTokens(String prompt) {
    // Simple estimate: ~1.5 chars/token for English, ~1 char/token for Chinese
    return (prompt.length / 1.5).round();
  }
}

/// Prompt build result
class PromptBuildResult {
  final String prompt;
  final String version;
  final int estimatedTokens;
  final ModelInfo model;

  PromptBuildResult({
    required this.prompt,
    required this.version,
    required this.estimatedTokens,
    required this.model,
  });
}

/// User context
class UserContext {
  final String userId;
  final bool isPremium;
  final String? constitution;
  final String currentSeason;
  final List<String> healthGoals;
  final List<String> recentTopics;
  final String? lastCareStatus;
  final String? followUpContext;

  UserContext({
    required this.userId,
    this.isPremium = false,
    this.constitution,
    this.currentSeason = 'spring',
    this.healthGoals = const [],
    this.recentTopics = const [],
    this.lastCareStatus,
    this.followUpContext,
  });
}

/// Model provider
class ModelProvider {
  static const free = ModelInfo(
    name: 'qwen2.5-7b-instruct',
    apiKey: '',
    temperature: 0.7,
    maxTokens: 1024,
  );

  static const premium = ModelInfo(
    name: 'qwen2.5-72b-instruct',
    apiKey: '',
    temperature: 0.7,
    maxTokens: 2048,
  );
}
