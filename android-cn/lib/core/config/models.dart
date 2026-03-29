// lib/core/config/models.dart

/// AI 配置模型
class AIConfig {
  final String apiGateway;
  final ModelInfo freeModel;
  final ModelInfo premiumModel;

  const AIConfig({
    required this.apiGateway,
    required this.freeModel,
    required this.premiumModel,
  });
}

/// 模型信息
class ModelInfo {
  final String name;
  final String apiKey;
  final double temperature;
  final int maxTokens;

  const ModelInfo({
    required this.name,
    required this.apiKey,
    this.temperature = 0.7,
    this.maxTokens = 2048,
  });
}

/// AI 请求
class AIRequest {
  final String requestId;
  final String userId;
  final String userInput;
  final String? intent;
  final bool isPremium;
  final Map<String, dynamic>? context;
  final String? expectedSchema;

  const AIRequest({
    required this.requestId,
    required this.userId,
    required this.userInput,
    this.intent,
    this.isPremium = false,
    this.context,
    this.expectedSchema,
  });
}

/// AI 响应
class AIResponse {
  final String text;
  final String tone;
  final String careStatus;
  final FollowUp? followUp;
  final bool offlineEncouraged;
  final String presenceLevel;
  final String safetyFlag;
  final List<String>? suggestedActions;

  const AIResponse({
    required this.text,
    this.tone = 'gentle',
    this.careStatus = 'stable',
    this.followUp,
    this.offlineEncouraged = false,
    this.presenceLevel = 'normal',
    this.safetyFlag = 'none',
    this.suggestedActions,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      text: json['text'] ?? json['content'] ?? '',
      tone: json['tone'] ?? 'gentle',
      careStatus: json['care_status'] ?? 'stable',
      followUp: json['follow_up'] != null
          ? FollowUp.fromJson(json['follow_up'])
          : null,
      offlineEncouraged: json['offline_encouraged'] ?? false,
      presenceLevel: json['presence_level'] ?? 'normal',
      safetyFlag: json['safety_flag'] ?? 'none',
      suggestedActions: json['suggested_actions'] != null
          ? List<String>.from(json['suggested_actions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'tone': tone,
        'care_status': careStatus,
        'follow_up': followUp?.toJson(),
        'offline_encouraged': offlineEncouraged,
        'presence_level': presenceLevel,
        'safety_flag': safetyFlag,
        'suggested_actions': suggestedActions,
      };
}

/// 跟进
class FollowUp {
  final int inDays;
  final String intent;
  final String? message;

  const FollowUp({
    required this.inDays,
    required this.intent,
    this.message,
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) {
    return FollowUp(
      inDays: json['in_days'] ?? 1,
      intent: json['intent'] ?? 'check_in',
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
        'in_days': inDays,
        'intent': intent,
        'message': message,
      };
}
