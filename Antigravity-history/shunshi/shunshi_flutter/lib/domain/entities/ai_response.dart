import 'care_status.dart';
import 'message.dart';

/// ──────────────────────────────────────────────────
/// AIResponse — 严格对应 JSON Schema
/// 所有 AI Router 返回的结构化响应
/// ──────────────────────────────────────────────────

class AIResponse {
  final String text;
  final String tone; // warm / gentle / professional
  final CareStatus careStatus;
  final FollowUpIntent? followUp;
  final bool offlineEncouraged;
  final PresenceLevel presenceLevel;
  final SafetyFlag safetyFlag;
  final List<ContentCard> contentCards;
  final List<String> followUpQuestions;
  final AIResponseMetadata? metadata;

  const AIResponse({
    required this.text,
    this.tone = 'warm',
    this.careStatus = CareStatus.stable,
    this.followUp,
    this.offlineEncouraged = false,
    this.presenceLevel = PresenceLevel.normal,
    this.safetyFlag = SafetyFlag.green,
    this.contentCards = const [],
    this.followUpQuestions = const [],
    this.metadata,
  });

  /// Schema 解析失败降级 — 提取纯文本，默认安全值
  factory AIResponse.fallback(String rawText) => AIResponse(
        text: rawText,
        tone: 'warm',
        careStatus: CareStatus.stable,
        offlineEncouraged: false,
        presenceLevel: PresenceLevel.normal,
        safetyFlag: SafetyFlag.green,
      );

  /// 从 JSON Schema 解析
  factory AIResponse.fromJson(Map<String, dynamic> json) => AIResponse(
        text: json['text'] as String? ?? '',
        tone: json['tone'] as String? ?? 'warm',
        careStatus: CareStatus.fromString(json['care_status'] as String?),
        followUp: json['follow_up'] != null
            ? FollowUpIntent.fromJson(json['follow_up'] as Map<String, dynamic>)
            : null,
        offlineEncouraged: json['offline_encouraged'] as bool? ?? false,
        presenceLevel:
            PresenceLevel.fromString(json['presence_level'] as String?),
        safetyFlag: SafetyFlag.fromString(json['safety_flag'] as String?),
        contentCards: (json['content_cards'] as List?)
                ?.map((e) => ContentCard.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        followUpQuestions: (json['follow_up_questions'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        metadata: json['metadata'] != null
            ? AIResponseMetadata.fromJson(
                json['metadata'] as Map<String, dynamic>)
            : null,
      );

  /// 转为 Message
  Message toMessage() => Message.assistantMessage(
        text,
        contentCards: contentCards,
        followUpQuestions: followUpQuestions,
        safetyFlag: safetyFlag,
      );
}

/// 跟进意图
class FollowUpIntent {
  final int inDays;
  final String intent;
  final String topic;

  const FollowUpIntent({
    required this.inDays,
    required this.intent,
    required this.topic,
  });

  DateTime get scheduledAt =>
      DateTime.now().add(Duration(days: inDays));

  factory FollowUpIntent.fromJson(Map<String, dynamic> json) => FollowUpIntent(
        inDays: json['in_days'] as int? ?? 1,
        intent: json['intent'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'in_days': inDays,
        'intent': intent,
        'topic': topic,
      };
}

/// AI 响应元数据（审计日志用）
class AIResponseMetadata {
  final String? model;
  final Map<String, String>? promptVersion;
  final AITokenUsage? tokens;
  final int? latencyMs;
  final String? safetyFlag;
  final String? userTier;

  const AIResponseMetadata({
    this.model,
    this.promptVersion,
    this.tokens,
    this.latencyMs,
    this.safetyFlag,
    this.userTier,
  });

  factory AIResponseMetadata.fromJson(Map<String, dynamic> json) =>
      AIResponseMetadata(
        model: json['model'] as String?,
        promptVersion: (json['prompt_version'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
        tokens: json['tokens'] != null
            ? AITokenUsage.fromJson(json['tokens'] as Map<String, dynamic>)
            : null,
        latencyMs: json['latency_ms'] as int?,
        safetyFlag: json['safety_flag'] as String?,
        userTier: json['user_tier'] as String?,
      );
}

/// Token 使用量
class AITokenUsage {
  final int prompt;
  final int completion;
  final int total;

  const AITokenUsage({
    required this.prompt,
    required this.completion,
    required this.total,
  });

  factory AITokenUsage.fromJson(Map<String, dynamic> json) => AITokenUsage(
        prompt: json['prompt'] as int? ?? 0,
        completion: json['completion'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );
}
