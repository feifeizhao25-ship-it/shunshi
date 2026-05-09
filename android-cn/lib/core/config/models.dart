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
  final String? userMessage; // alias for userInput
  final String? intent;
  final bool isPremium;
  final Map<String, dynamic>? context;
  final String? expectedSchema;

  const AIRequest({
    required this.requestId,
    required this.userId,
    required this.userInput,
    this.userMessage,
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


/// 中医术语英汉对照（供国际版AI回复使用）
class TCMGlossary {
  static const Map<String, String> zhToEn = {
    '气血': 'Qi and Blood (vital energy and blood circulation)',
    '气虚': 'Qi Deficiency - low energy, fatigue',
    '血虚': 'Blood Deficiency - dizziness, pale complexion',
    '阴虚': 'Yin Deficiency - heat sensations, dry mouth',
    '阳虚': 'Yang Deficiency - cold intolerance, fatigue',
    '湿热': 'Damp-Heat - inflammation, digestive issues',
    '肝郁': 'Liver Qi Stagnation - stress, mood swings',
    '脾虚': 'Spleen Qi Deficiency - poor digestion, fatigue',
    '肾虚': 'Kidney Deficiency - low back pain, low vitality',
    '胃火': 'Stomach Heat - bad breath, mouth ulcers',
    '心火': 'Heart Fire - anxiety, insomnia',
    '肺热': 'Lung Heat - cough, fever',
    '涌泉穴': 'KD1 (Yongquan) - Kidney Channel Point 1, bottom of foot',
    '足三里': 'ST36 (Zusanli) - Stomach Channel Point 36, lower leg',
    '合谷穴': 'LI4 (Hegu) - Large Intestine Channel Point 4, hand',
    '关元穴': 'CV4 (Guanyuan) - Conception Vessel Point 4, lower abdomen',
    '命门穴': 'GV4 (Mingmen) - Governing Vessel Point 4, lower back',
    '中脘穴': 'CV12 (Zhongwan) - Conception Vessel Point 12, upper abdomen',
    '三阴交': 'SP6 (Sanyinjiao) - Spleen Channel Point 6, inner leg',
    '百会穴': 'GV20 (Baihui) - Governing Vessel Point 20, top of head',
    '时辰': 'Shichen (Chinese Clock) - traditional 2-hour period',
    '胆经': 'Gallbladder Meridian - emotional courage and decision-making',
    '肝经': 'Liver Meridian - emotional regulation and blood storage',
    '肺经': 'Lung Meridian - respiration and immune defense',
    '胃经': 'Stomach Meridian - digestion and appetite',
    '脾经': 'Spleen Meridian - digestion and nutrient absorption',
    '肾经': 'Kidney Meridian - reproduction and vitality',
    '心经': 'Heart Meridian - mind, emotions, and circulation',
    '膀胱经': 'Bladder Meridian - fluid metabolism and back channel',
    '任脉': 'Ren Mai (Conception Vessel) - front midline energy channel',
    '督脉': 'Du Mai (Governing Vessel) - back midline energy channel',
    '节气': 'Jieqi (Solar Term) - 24 seasonal nodes in Chinese calendar',
    '清肝明目': 'Clear Liver, Bright Eyes - liver health for vision',
    '补气养血': 'Tonify Qi, Nourish Blood - energy and blood building',
    '滋阴润燥': 'Nourish Yin, Moisten Dryness - for dry conditions',
    '温阳散寒': 'Warm Yang, Disperse Cold - for cold conditions',
    '活血化瘀': 'Invigorate Blood, Transform Stasis - for blood stasis',
    '健脾祛湿': 'Strengthen Spleen, Eliminate Dampness - for dampness',
    '疏肝解郁': 'Soothe Liver, Relieve Depression - for emotional stress',
    '养心安神': 'Nourish Heart, Calm Mind - for sleep and anxiety',
  };

  /// 获取英文解释
  static String explain(String term) {
    return zhToEn[term] ?? term;
  }
}
