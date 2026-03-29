// test/fixtures/api_responses.dart
// 顺时测试用 Mock API 响应

class ApiFixtures {
  ApiFixtures._();

  static const Map<String, dynamic> user = {
    'id': 'user_test_001',
    'phone': '13800138000',
    'name': '测试用户',
    'avatar_url': null,
    'gender': 'male',
    'subscription': 'free',
    'constitution': 'balanced',
    'hemisphere': 'north',
    'ai_memory_enabled': true,
    'created_at': '2026-01-01T00:00:00.000Z',
    'last_active_at': '2026-03-28T10:00:00.000Z',
    'preferences': {},
  };

  static const Map<String, dynamic> userPremium = {
    'id': 'user_test_002',
    'phone': '13900139000',
    'name': '尊享用户',
    'subscription': 'premium',
    'constitution': 'qiDeficiency',
    'hemisphere': 'north',
    'ai_memory_enabled': true,
    'created_at': '2026-01-01T00:00:00.000Z',
    'preferences': {},
  };

  static const Map<String, dynamic> message = {
    'id': 'msg_001',
    'conversation_id': 'conv_001',
    'role': 'assistant',
    'content': '今日立春，万物复苏。建议你今日饮食以温补为主，可食用韭菜、春笋等当季食材。',
    'created_at': '2026-02-04T08:00:00.000Z',
    'safety_flag': 'none',
    'care_status': 'stable',
    'tone': 'warm',
  };

  static const Map<String, dynamic> messageWithCard = {
    'id': 'msg_002',
    'conversation_id': 'conv_001',
    'role': 'assistant',
    'content': '为你推荐立春节气茶饮',
    'created_at': '2026-02-04T08:01:00.000Z',
    'safety_flag': 'none',
    'care_status': 'stable',
    'tone': 'gentle',
    'card_data': {
      'card_type': 'tea',
      'card_emoji': '🍵',
      'title': '玫瑰花茶',
      'description': '春季疏肝解郁，适合气郁体质',
      'ingredients': ['玫瑰花 3-5朵', '枸杞 10粒', '红枣 2颗'],
    },
  };

  static const Map<String, dynamic> solarTerm = {
    'id': 'solar_001',
    'name': '立春',
    'name_en': 'Start of Spring',
    'emoji': '🌱',
    'season': 'spring',
    'date': '2月3日-5日',
    'description': '立春是二十四节气中的第一个节气，标志着春天的开始。',
    'is_current': true,
    'wellness_plan': {
      'diet': [
        {'title': '韭菜炒鸡蛋', 'description': '温阳散寒，适合立春食用', 'difficulty': '简单'},
      ],
      'tea': [
        {'title': '玫瑰花茶', 'description': '疏肝解郁，春季必备'},
      ],
      'exercise': [
        {'title': '八段锦', 'description': '舒展筋骨，迎接春天'},
      ],
    },
  };

  static const Map<String, dynamic> content = {
    'id': 'content_001',
    'type': 'foodTherapy',
    'title': '立春食疗 — 韭菜炒鸡蛋',
    'summary': '韭菜温阳，鸡蛋补虚，是立春时节的经典食疗搭配。',
    'tags': ['立春', '温阳', '简单'],
    'season': 'spring',
    'solar_term': '立春',
    'difficulty': 'easy',
    'duration_minutes': 15,
    'created_at': '2026-02-01T00:00:00.000Z',
  };

  static const Map<String, dynamic> reflection = {
    'id': 'refl_001',
    'user_id': 'user_test_001',
    'content': '今天感觉状态不错，跟着顺时的建议早睡早起，确实精神了很多。',
    'mood': 'good',
    'sleep_hours': 8,
    'tags': ['睡眠', '早起'],
    'date': '2026-03-28T00:00:00.000Z',
    'created_at': '2026-03-28T20:00:00.000Z',
  };

  static const Map<String, dynamic> followUp = {
    'id': 'fu_001',
    'type': 'sleep_followup',
    'title': '昨晚睡得好吗？',
    'description': '你昨天提到睡眠不好，今天跟进一下',
    'scheduled_at': '2026-03-28T09:00:00.000Z',
    'priority': 'normal',
  };
}
