// lib/core/prompt/prompt_manager.dart

import 'prompt_versions.dart';

/// Prompt 管理器 - 负责模块化 Prompt 的加载、版本管理和组装
class PromptManager {
  final Map<String, PromptVersion> _prompts = {};

  PromptManager() {
    _loadPrompts();
  }

  void _loadPrompts() {
    // 加载所有 Prompt 版本
    for (final prompt in promptVersions) {
      _prompts['${prompt.id}_${prompt.version}'] = prompt;
    }
  }

  /// 构建完整 Prompt
  Future<String> build(AIRequest request) async {
    // 1. 获取 Core Prompt
    final corePrompt = await _getPrompt('SS_CORE_ALL', request.userType);

    // 2. 获取 Policy Prompt
    final policyPrompt = await _getPrompt(
      'SS_POLICY_${request.userType.toUpperCase()}',
      request.userType,
    );

    // 3. 获取 Task Prompt
    final taskPrompt = await _getTaskPrompt(request.intent);

    // 4. 获取用户上下文
    final contextPrompt = await _getContext(request.userId);

    // 5. 组装
    return '''
${corePrompt.content}

---

${policyPrompt.content}

---

## 当前任务
${taskPrompt.content}

---

## 用户上下文
${contextPrompt.content}

---

## 输出要求
请以 JSON 格式输出，包含以下字段：
- text: 回答内容
- tone: 语气 (gentle/warm/professional)
- care_status: 关怀状态 (stable/concerned/attention)
- follow_up: 跟进设置（可选）
- presence_level: 主动程度 (low/normal/high)
- safety_flag: 安全标志 (none/caution/blocked)
''';
  }

  /// 获取 Prompt
  Future<PromptVersion> _getPrompt(String id, String userType) async {
    // 查找匹配的 Prompt
    final key = '${id}_v1.0';
    return _prompts[key] ?? defaultPrompts[id] ?? defaultCorePrompt;
  }

  /// 获取任务 Prompt
  Future<PromptVersion> _getTaskPrompt(String? intent) async {
    if (intent == null) return defaultTaskPrompt;

    final taskPrompts = {
      'chat': promptTaskChat,
      'daily_plan': promptTaskDailyPlan,
      'weekly_summary': promptTaskWeeklySummary,
      'solar_term': promptTaskSolarTerm,
      'health_assessment': promptTaskHealthAssessment,
      'dietary_advice': promptTaskDietary,
      'sleep_advice': promptTaskSleep,
      'emotion_support': promptTaskEmotion,
    };

    return taskPrompts[intent] ?? defaultTaskPrompt;
  }

  /// 获取用户上下文
  Future<ContextPrompt> _getContext(String userId) async {
    // 从数据库获取用户上下文
    // 这里简化处理
    return ContextPrompt(
      userId: userId,
      constitution: '平和质',
      currentSeason: 'spring',
      recentTopics: ['睡眠', '饮食'],
      lastCareStatus: 'stable',
    );
  }
}

/// Prompt 版本
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

/// 用户上下文
class ContextPrompt {
  final String userId;
  final String constitution;
  final String currentSeason;
  final List<String> recentTopics;
  final String lastCareStatus;

  const ContextPrompt({
    required this.userId,
    required this.constitution,
    required this.currentSeason,
    required this.recentTopics,
    required this.lastCareStatus,
  });

  String get content => '''
用户ID: $userId
体质: $constitution
当前季节: $currentSeason
最近话题: ${recentTopics.join(', ')}
上次关怀状态: $lastCareStatus
''';
}
