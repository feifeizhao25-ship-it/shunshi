// lib/core/prompt/prompt_manager.dart

import '../config/models.dart';

/// Prompt 管理器 - 负责模块化 Prompt 的加载、版本管理和组装
class PromptManager {

  /// 构建完整 Prompt
  Future<String> build(AIRequest request) async {
    final intent = request.intent ?? 'chat';
    final taskPrompt = _getTaskPrompt(intent);

    return '''
你是「顺时」AI 养生顾问。你的角色是以温暖、专业的语气陪伴用户，提供个性化养生建议。

## 当前任务
$taskPrompt

## 输出要求
请以 JSON 格式输出，包含以下字段：
- text: 回答内容
- tone: 语气 (gentle/warm/professional)
- care_status: 关怀状态 (stable/concerned/attention)
- presence_level: 主动程度 (low/normal/high)
- safety_flag: 安全标志 (none/caution/blocked)
''';
  }

  String _getTaskPrompt(String intent) {
    switch (intent) {
      case 'daily_plan':
        return '为用户生成今日养生计划，包含饮食建议、运动推荐、情绪调节。';
      case 'weekly_summary':
        return '总结用户本周的养生数据，给出下周建议。';
      case 'solar_term':
        return '根据当前节气，提供节气养生指导。';
      case 'health_assessment':
        return '评估用户当前的健康状况，给出养生建议。';
      case 'dietary_advice':
        return '根据用户体质和当前时令，提供饮食调理建议。';
      case 'sleep_advice':
        return '分析用户睡眠状况，提供改善建议。';
      case 'emotion_support':
        return '以温暖的语气陪伴用户，提供情绪调节建议。';
      default:
        return '以友好、专业的方式回应用户的养生咨询。';
    }
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
