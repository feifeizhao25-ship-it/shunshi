import 'dart:convert';

/// 风险等级
enum RiskLevel { low, medium, high, crisis }

/// AI安全服务 — Prompt Injection防护 + 健康风险评估
class AISafetyService {
  AISafetyService._();

  // ── Prompt Injection 检测模式 ──

  static final RegExp _roleHijack = RegExp(
    r'\b(system|assistant|user)\s*:',
    caseSensitive: false,
  );

  static final List<RegExp> _injectionPatterns = [
    RegExp(r'ignore\s+(all\s+)?previous\s+(instructions|prompts|rules)', caseSensitive: false),
    RegExp(r'you\s+are\s+now\b', caseSensitive: false),
    RegExp(r'forget\s+(everything|all|your)\b', caseSensitive: false),
    RegExp(r'disregard\s+(your|all|previous)\b', caseSensitive: false),
    RegExp(r'jailbreak|DAN\s+mode|bypass\s+(filter|safety|guard)', caseSensitive: false),
    RegExp(r'pretend\s+you\s+(are|can)\b', caseSensitive: false),
    RegExp(r'act\s+as\s+(if\s+)?you\s+(are|were|have)\b', caseSensitive: false),
    // base64-encoded payloads (40+ chars of base64)
    RegExp(r'[A-Za-z0-9+/]{40,}={0,2}'),
  ];

  /// 重复字符检测阈值
  static const int _repeatThreshold = 50;

  /// 检测是否为 prompt injection 攻击
  static bool isPromptInjection(String input) {
    final trimmed = input.trim();

    // 1. 已知 injection 模式
    for (final pattern in _injectionPatterns) {
      if (pattern.hasMatch(trimmed)) return true;
    }

    // 2. Role hijacking (system:, assistant:, user:)
    if (_roleHijack.hasMatch(trimmed)) return true;

    // 3. 长重复字符 (aaaa... 50+)
    if (_hasLongRepetition(trimmed)) return true;

    // 4. 尝试 base64 解码 — 如果解码后包含可疑内容
    if (_looksLikeBase64(trimmed)) {
      try {
        final decoded = utf8.decode(base64Decode(trimmed));
        for (final pattern in _injectionPatterns) {
          if (pattern.hasMatch(decoded)) return true;
        }
      } catch (_) {
        // not valid base64, skip
      }
    }

    return false;
  }

  static bool _hasLongRepetition(String text) {
    if (text.length < _repeatThreshold) return false;
    for (int i = 0; i < text.length - _repeatThreshold; i++) {
      final ch = text[i];
      int count = 1;
      for (int j = i + 1; j < text.length && text[j] == ch; j++) {
        count++;
      }
      if (count >= _repeatThreshold) return true;
    }
    return false;
  }

  static bool _looksLikeBase64(String text) {
    if (text.length < 40) return false;
    return RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(text);
  }

  // ── 健康风险评估 ──

  // 危机关键词 — 需要立即干预
  static const List<String> _crisisKeywords = [
    '自杀', '想死', '不想活', '自残', '割腕', '跳楼', '上吊',
    '结束生命', '活着没意思',
  ];

  static const List<String> _crisisKeywordsEn = [
    'suicide', 'kill myself', 'end my life', 'want to die',
    "don't want to live", 'self-harm', 'self harm', 'hurt myself',
    'overdose', 'end it all',
  ];

  // 高风险关键词 — 需要强烈警告
  static const List<String> _highRiskKeywords = [
    '抑郁症', '心脏病发作', '心肌梗塞', '脑溢血', '中风',
    '癌症', '肿瘤', '大出血', '窒息', '昏迷', '休克',
    '过敏休克', '呼吸困难', '胸痛', '剧烈头痛',
  ];

  static const List<String> _highRiskKeywordsEn = [
    'depression', 'heart attack', 'cancer', 'tumor', 'seizure',
    'overdose', 'anaphylaxis', 'can\'t breathe', 'chest pain',
    'severe headache', 'stroke',
  ];

  // 中等风险关键词 — 添加免责声明
  static const List<String> _mediumRiskKeywords = [
    '发烧', '咳嗽', '头痛', '腹痛', '腹泻', '呕吐', '皮疹', '出血',
    '高血压', '糖尿病', '心脏病', '肝病', '肾病',
    '吃药', '用药', '停药', '药物', '手术', '怀孕', '流产',
  ];

  static const List<String> _mediumRiskKeywordsEn = [
    'fever', 'cough', 'headache', 'stomach pain', 'diarrhea', 'vomiting',
    'rash', 'bleeding', 'high blood pressure', 'diabetes', 'heart disease',
    'pregnancy', 'medication', 'surgery',
  ];

  /// 评估输入的健康风险等级
  static RiskLevel assessRisk(String input) {
    final lower = input.toLowerCase();

    // Crisis — 最高优先级
    for (final kw in _crisisKeywords) {
      if (lower.contains(kw)) return RiskLevel.crisis;
    }
    for (final kw in _crisisKeywordsEn) {
      if (lower.contains(kw)) return RiskLevel.crisis;
    }

    // High
    for (final kw in _highRiskKeywords) {
      if (lower.contains(kw)) return RiskLevel.high;
    }
    for (final kw in _highRiskKeywordsEn) {
      if (lower.contains(kw)) return RiskLevel.high;
    }

    // Medium
    for (final kw in _mediumRiskKeywords) {
      if (lower.contains(kw)) return RiskLevel.medium;
    }
    for (final kw in _mediumRiskKeywordsEn) {
      if (lower.contains(kw)) return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  /// 获取危机响应文本
  static String getCrisisResponse(RiskLevel level, {bool isEnglish = false}) {
    if (isEnglish) {
      return _getCrisisResponseEn(level);
    }
    return _getCrisisResponseCn(level);
  }

  static String _getCrisisResponseCn(RiskLevel level) {
    switch (level) {
      case RiskLevel.crisis:
        return '⚠️ 您提到的内容让我们非常担心您的安全。请您立即联系专业帮助：\n\n'
            '• 24小时心理援助热线：400-161-9995\n'
            '• 北京心理危机研究与干预中心：010-82951332\n'
            '• 急救电话：120\n\n'
            '您的生命安全和身心健康是最重要的。顺时AI不能替代专业医疗诊断，请务必寻求专业人士的帮助。';
      case RiskLevel.high:
        return '⚠️ 您提到的健康问题需要专业医疗关注。建议您尽快咨询专业医师，进行详细检查。\n\n'
            '顺时AI提供的养生建议仅供参考，不能替代医生诊断。如有不适，请及时就医。';
      case RiskLevel.medium:
        return '📌 温馨提示：以下建议基于中医养生理论，仅供参考。如有持续不适，请咨询专业医师。';
      case RiskLevel.low:
        return '';
    }
  }

  static String _getCrisisResponseEn(RiskLevel level) {
    switch (level) {
      case RiskLevel.crisis:
        return 'It sounds like you\'re going through a really difficult time. '
            'Please reach out to someone who can help:\n\n'
            '• 988 Suicide & Crisis Lifeline (US)\n'
            '• 111 NHS Mental Health (UK)\n'
            '• findahelpline.com (International)\n\n'
            'You don\'t have to face this alone. SEASONS cannot replace '
            'professional medical care.';
      case RiskLevel.high:
        return '⚠️ The health issue you mentioned requires professional medical '
            'attention. Please consult a healthcare provider as soon as possible.\n\n'
            'SEASONS provides wellness suggestions based on traditional wisdom only '
            'and cannot replace medical diagnosis.';
      case RiskLevel.medium:
        return '📌 Note: Suggestions below are based on traditional wellness '
            'principles and are for reference only. Please consult a healthcare '
            'provider for persistent symptoms.';
      case RiskLevel.low:
        return '';
    }
  }
}
