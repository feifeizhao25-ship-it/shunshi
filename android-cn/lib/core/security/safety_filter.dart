// lib/core/security/safety_filter.dart

/// 安全过滤器 - 负责内容安全过滤
class SafetyFilter {
  /// 医疗相关关键词
  static const medicalKeywords = [
    '诊断', '治疗', '治愈', '药', '处方', '手术',
    '检查', '体检', '指标', '数值',
    '血压', '血糖', '血脂', '尿酸',
    '肿瘤', '癌症', '新冠', '肺炎',
    '吃什么药', '怎么治疗', '如何治愈',
  ];

  /// 敏感关键词
  static const sensitiveKeywords = [
    '自杀', '自残', '抑郁', '焦虑症',
    '死亡', '轻生',
  ];

  /// 检查输入
  Future<SafetyResult> check(String input) async {
    final lowerInput = input.toLowerCase();

    // 1. 检查敏感词
    for (final keyword in sensitiveKeywords) {
      if (lowerInput.contains(keyword)) {
        return SafetyResult(
          isSafe: false,
          response: _getSensitiveResponse(keyword),
          flag: 'sensitive',
        );
      }
    }

    // 2. 检查医疗关键词
    for (final keyword in medicalKeywords) {
      if (lowerInput.contains(keyword)) {
        return SafetyResult(
          isSafe: true,
          response: '',
          flag: 'caution',
          needsDoctorConsult: true,
        );
      }
    }

    return SafetyResult(isSafe: true, flag: 'none');
  }

  String _getSensitiveResponse(String keyword) {
    final responses = {
      '自杀': '我感受到你可能正在经历困难时刻。你的生命很宝贵，如果感到难以承受，建议你寻求专业帮助。可以拨打心理援助热线：400-161-9995',
      '自残': '我听到你提到伤害自己的想法。我很关心你，建议你和信任的人聊聊，或者寻求专业心理帮助。',
      '抑郁': '听起来你最近情绪很低落。如果这种状态持续，建议你咨询专业心理医生。',
      '焦虑': '焦虑是很多人都会有的感受。如果影响到了日常生活，可以考虑寻求专业帮助。',
    };
    return responses[keyword] ?? '我理解你的感受，建议你寻求专业帮助。';
  }
}

/// 安全检查结果
class SafetyResult {
  final bool isSafe;
  final String response;
  final String flag;
  final bool needsDoctorConsult;

  const SafetyResult({
    required this.isSafe,
    required this.response,
    required this.flag,
    this.needsDoctorConsult = false,
  });
}
