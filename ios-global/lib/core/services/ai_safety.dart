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
    'suicide', 'want to die', 'don\'t want to live', 'self-harm', 'cut my wrists', 'jump off a building', 'hang myself',
    'end my life', 'no point in living',
  ];

  static const List<String> _crisisKeywordsEn = [
    'suicide', 'kill myself', 'end my life', 'want to die',
    "don't want to live", 'self-harm', 'self harm', 'hurt myself',
    'overdose', 'end it all',
  ];

  // 高风险关键词 — 需要强烈警告
  static const List<String> _highRiskKeywords = [
    'depression', 'heart attack', 'myocardial infarction', 'cerebral hemorrhage', 'stroke',
    'cancer', 'tumor', 'severe bleeding', 'choking', 'unconscious', 'shock',
    'anaphylaxis', 'trouble breathing', 'chest pain', 'severe headache',
  ];

  static const List<String> _highRiskKeywordsEn = [
    'depression', 'heart attack', 'cancer', 'tumor', 'seizure',
    'overdose', 'anaphylaxis', 'can\'t breathe', 'chest pain',
    'severe headache', 'stroke',
  ];

  // 中等风险关键词 — 添加免责声明
  static const List<String> _mediumRiskKeywords = [
    'fever', 'cough', 'headache', 'stomach pain', 'diarrhea', 'vomiting', 'rash', 'bleeding',
    'high blood pressure', 'diabetes', 'heart disease', 'liver disease', 'kidney disease',
    'take medicine', 'medication', 'stop medication', 'drugs', 'surgery', 'pregnant', 'miscarriage',
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
        return '⚠️ What you shared worries us about your safety. Please contact professional help right away:\n\n'
            '• Call or text your local crisis line (US: 988 · UK & ROI: 116 123 · Canada: 988 · Australia: 13 11 14)\n'
            '• Or find a crisis line in your country at findahelpline.com\n'
            '• Emergency services: your local emergency number (US/CA: 911 · UK: 999 · EU: 112 · AU: 000)\n\n'
            'Your life and wellbeing matter most. SEASONS AI cannot replace professional medical diagnosis — please reach out to a professional.';
      case RiskLevel.high:
        return '⚠️ The health issue you mention needs professional medical attention. Please see a qualified clinician soon for a proper check.\n\n'
            'The wellness suggestions from SEASONS AI are for reference only and do not replace a doctor\'s diagnosis. If you feel unwell, please seek medical care.';
      case RiskLevel.medium:
        return '📌 Gentle reminder: the suggestions below are based on traditional wellness ideas and are for reference only. If discomfort persists, please consult a qualified professional.';
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
