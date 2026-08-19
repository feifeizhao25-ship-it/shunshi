import 'package:json_annotation/json_annotation.dart';
import 'care_status.dart';
import 'follow_up_plan.dart';

part 'ai_response.g.dart';

/// AI Router 严格 JSON Schema 响应
/// 解析失败时降级为纯文本消息 + safety_flag=sensitive
@JsonSerializable()
class AiResponseCard {
  final String type;
  @JsonKey(name: 'content_id')
  final String? contentId;
  final String? title;
  final Map<String, dynamic>? media;

  const AiResponseCard({
    required this.type,
    this.contentId,
    this.title,
    this.media,
  });

  factory AiResponseCard.fromJson(Map<String, dynamic> json) =>
      _$AiResponseCardFromJson(json);
  Map<String, dynamic> toJson() => _$AiResponseCardToJson(this);
}

@JsonSerializable()
class AiResponse {
  final String text;
  final String tone;
  @JsonKey(name: 'care_status')
  final String careStatus;
  @JsonKey(name: 'follow_up')
  final FollowUpPlan? followUp;
  @JsonKey(name: 'offline_encouraged')
  final bool offlineEncouraged;
  @JsonKey(name: 'presence_level')
  final String presenceLevel;
  @JsonKey(name: 'safety_flag')
  final String safetyFlag;
  final List<AiResponseCard>? cards;

  const AiResponse({
    required this.text,
    this.tone = 'gentle',
    this.careStatus = 'stable',
    this.followUp,
    this.offlineEncouraged = false,
    this.presenceLevel = 'normal',
    this.safetyFlag = 'none',
    this.cards,
  });

  bool get isSafe => safetyFlag == 'none';
  bool get needsSafeMode => safetyFlag != 'none';
  bool get isPresenceReduced => presenceLevel == 'reduced';

  CareStatus get parsedCareStatus {
    switch (careStatus) {
      case 'needs_attention':
        return CareStatus.needsAttention;
      case 'escalate':
        return CareStatus.escalate;
      default:
        return CareStatus.stable;
    }
  }

  factory AiResponse.fromJson(Map<String, dynamic> json) =>
      _$AiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AiResponseToJson(this);

  /// 解析降级：当 JSON 解析失败时，返回安全的默认响应
  factory AiResponse.degraded(String rawText) {
    return AiResponse(
      text: rawText.isNotEmpty ? rawText : '我暂时无法理解，稍后再为你回复。',
      tone: 'gentle',
      careStatus: 'stable',
      offlineEncouraged: false,
      presenceLevel: 'normal',
      safetyFlag: 'sensitive',
    );
  }

  /// 从原始 JSON 字符串安全解析
  static AiResponse safeParse(dynamic data) {
    if (data == null) {
      return AiResponse.degraded('');
    }
    if (data is String) {
      return AiResponse.degraded(data);
    }
    if (data is Map<String, dynamic>) {
      try {
        return AiResponse.fromJson(data);
      } catch (_) {
        final text = data['text']?.toString() ?? '';
        return AiResponse.degraded(text);
      }
    }
    return AiResponse.degraded('');
  }
}

/// Prompt 版本管理
class PromptVersion {
  final String core;
  final String policy;
  final String task;

  const PromptVersion({
    this.core = 'SS_CORE_ALL_v1.0',
    this.policy = 'SS_POLICY_FREE_v1.0',
    this.task = 'SS_TASK_CHAT_v1.0',
  });

  const PromptVersion.premiumChat()
      : core = 'SS_CORE_ALL_v1.0',
        policy = 'SS_POLICY_PREMIUM_v1.2',
        task = 'SS_TASK_CHAT_v1.0';

  const PromptVersion.dailyPlan()
      : core = 'SS_CORE_ALL_v1.0',
        policy = 'SS_POLICY_FREE_v1.0',
        task = 'SS_TASK_DAILY_PLAN_v1.0';

  const PromptVersion.premiumDailyPlan()
      : core = 'SS_CORE_ALL_v1.0',
        policy = 'SS_POLICY_PREMIUM_v1.2',
        task = 'SS_TASK_DAILY_PLAN_v1.0';

  Map<String, dynamic> toJson() => {
        'core': core,
        'policy': policy,
        'task': task,
      };
}
