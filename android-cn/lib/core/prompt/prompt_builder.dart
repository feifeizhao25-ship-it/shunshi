// lib/core/prompt/prompt_builder.dart

import 'core_prompts.dart';
import 'policy_prompts.dart';
import 'task_prompts.dart';
import '../config/models.dart';

/// Prompt 构建器 - 组合三层 Prompt
class PromptBuilder {
  /// 构建完整 Prompt
  /// 组合: Core + Policy + Task + Context
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

    // 组合
    final fullPrompt = '''
$corePrompt

---

$policyPrompt

---

## 当前任务
$taskPrompt

---

## 用户上下文
$contextPrompt

---

## 用户消息
$userMessage

---

## 输出要求
请以 JSON 格式输出：
$outputSchema
''';

    // 计算预估 Token
    final estimatedTokens = _estimateTokens(fullPrompt);

    return PromptBuildResult(
      prompt: fullPrompt,
      version: 'v1.0',
      estimatedTokens: estimatedTokens,
      model: _selectModel(userContext.isPremium, taskType),
    );
  }

  /// 构建用户上下文
  static String _buildContext(UserContext ctx) {
    final buffer = StringBuffer();

    buffer.writeln('## 用户信息');
    buffer.writeln('- 用户ID: ${ctx.userId}');
    buffer.writeln('- 体质: ${ctx.constitution ?? "未识别"}');
    buffer.writeln('- 当前季节: ${ctx.currentSeason}');
    buffer.writeln('- 用户类型: ${ctx.isPremium ? "尊享会员" : "普通用户"}');

    if (ctx.healthGoals.isNotEmpty) {
      buffer.writeln('- 养生目标: ${ctx.healthGoals.join(", ")}');
    }

    if (ctx.recentTopics.isNotEmpty) {
      buffer.writeln('- 最近话题: ${ctx.recentTopics.join(", ")}');
    }

    if (ctx.lastCareStatus != null) {
      buffer.writeln('- 上次关怀状态: ${ctx.lastCareStatus}');
    }

    if (ctx.followUpContext != null) {
      buffer.writeln('\n## 跟进上下文');
      buffer.writeln('- 上次对话: ${ctx.followUpContext}');
    }

    return buffer.toString();
  }

  /// 获取输出 Schema
  static String _getOutputSchema(TaskType taskType) {
    // 基础 Schema
    const baseSchema = '''
{
  "text": "回答内容",
  "tone": "gentle|warm|professional",
  "care_status": "stable|concerned|attention",
  "presence_level": "low|normal|high",
  "safety_flag": "none|caution|blocked"
}
''';

    // 需要 Follow-up 的任务
    const followUpSchema = '''
{
  "text": "回答内容",
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

    // 需要生成计划的任务
    const planSchema = '''
{
  "text": "回答内容",
  "tone": "gentle|warm|professional",
  "care_status": "stable|concerned|attention",
  "plan": {
    "insight": "1句话洞察",
    "actions": ["行动1", "行动2", "行动3"]
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

  /// 选择模型
  static ModelInfo _selectModel(bool isPremium, TaskType taskType) {
    // 关键任务使用大模型
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

  /// 预估 Token
  static int _estimateTokens(String prompt) {
    // 简单估算：中文约 1.5 字符/token
    return (prompt.length / 1.5).round();
  }
}

/// Prompt 构建结果
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

/// 用户上下文
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

/// 模型提供者
class ModelProvider {
  static const free = ModelInfo(
    name: 'qwen2.5-7b-instruct',
    temperature: 0.7,
    maxTokens: 1024,
  );

  static const premium = ModelInfo(
    name: 'qwen2.5-72b-instruct',
    temperature: 0.7,
    maxTokens: 2048,
  );
}
