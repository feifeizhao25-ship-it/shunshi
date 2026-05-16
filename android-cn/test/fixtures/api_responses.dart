// test/fixtures/api_responses.dart
// 顺时测试用 Mock API 响应 — 扩充版

class ApiFixtures {
  ApiFixtures._();

  // ── User ──
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
    'preferences': <String, dynamic>{},
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
    'preferences': <String, dynamic>{},
  };

  static const Map<String, dynamic> userFamily = {
    'id': 'user_test_003',
    'name': '家庭用户',
    'subscription': 'family',
    'constitution': 'yinDeficiency',
    'hemisphere': 'south',
    'ai_memory_enabled': false,
    'created_at': '2026-02-01T00:00:00.000Z',
    'preferences': <String, dynamic>{},
  };

  static const Map<String, dynamic> userWithEmail = {
    'id': 'user_test_004',
    'email': 'test@example.com',
    'name': '邮箱用户',
    'subscription': 'standard',
    'constitution': 'phlegmDamp',
    'hemisphere': 'north',
    'ai_memory_enabled': true,
    'created_at': '2026-01-15T00:00:00.000Z',
    'preferences': <String, dynamic>{},
  };

  // ── Message ──
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

  static const Map<String, dynamic> messageUser = {
    'id': 'msg_003',
    'conversation_id': 'conv_001',
    'role': 'user',
    'content': '今天适合吃什么？',
    'created_at': '2026-02-04T07:55:00.000Z',
    'safety_flag': 'none',
  };

  static const Map<String, dynamic> messageBlocked = {
    'id': 'msg_004',
    'conversation_id': 'conv_002',
    'role': 'assistant',
    'content': '',
    'created_at': '2026-02-04T08:05:00.000Z',
    'safety_flag': 'blocked',
    'care_status': 'attention',
  };

  // ── SolarTerm ──
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

  static const Map<String, dynamic> solarTermLixia = {
    'id': 'solar_007',
    'name': '立夏',
    'name_en': 'Start of Summer',
    'emoji': '☀️',
    'season': 'summer',
    'date': '5月5日-7日',
    'description': '立夏标志着夏天的开始，气温逐渐升高。',
    'is_current': false,
  };

  // ── Content ──
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

  static const Map<String, dynamic> contentTea = {
    'id': 'content_002',
    'type': 'tea',
    'title': '菊花枸杞茶',
    'summary': '清肝明目，适合春季饮用。',
    'tags': ['春季', '清肝'],
    'season': 'spring',
    'difficulty': 'easy',
    'duration_minutes': 5,
  };

  static const Map<String, dynamic> contentExercise = {
    'id': 'content_003',
    'type': 'exercise',
    'title': '八段锦 — 第一式',
    'summary': '双手托天理三焦，疏通经络。',
    'tags': ['导引', '八段锦'],
    'season': 'spring',
    'difficulty': 'easy',
    'duration_minutes': 10,
  };

  static const Map<String, dynamic> contentMeditation = {
    'id': 'content_004',
    'type': 'audio',
    'title': '春季冥想 — 万物生长',
    'summary': '跟随呼吸感受春天的生机。',
    'tags': ['冥想', '春季'],
    'season': 'spring',
    'difficulty': 'easy',
    'duration_minutes': 15,
  };

  static const Map<String, dynamic> contentSleepTip = {
    'id': 'content_005',
    'type': 'sleep_tip',
    'title': '春季睡眠调理',
    'summary': '春困缓解方法，顺应自然作息。',
    'tags': ['睡眠', '春困'],
    'season': 'spring',
    'difficulty': 'easy',
  };

  // ── Reflection ──
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

  static const Map<String, dynamic> reflectionBadMood = {
    'id': 'refl_002',
    'user_id': 'user_test_001',
    'content': '昨晚没睡好，今天精神很差。',
    'mood': 'bad',
    'sleep_hours': 4,
    'tags': ['失眠'],
    'date': '2026-03-29T00:00:00.000Z',
    'created_at': '2026-03-29T20:00:00.000Z',
  };

  // ── FollowUp ──
  static const Map<String, dynamic> followUp = {
    'id': 'fu_001',
    'type': 'sleep_followup',
    'title': '昨晚睡得好吗？',
    'description': '你昨天提到睡眠不好，今天跟进一下',
    'scheduled_at': '2026-03-28T09:00:00.000Z',
    'priority': 'normal',
  };

  // ── API Responses (full envelope) ──
  static const Map<String, dynamic> healthResponse = {
    'status': 'healthy',
    'version': '2.0.0',
    'services': {
      'database': 'ok',
      'redis': 'ok',
    },
  };

  static const Map<String, dynamic> guestLoginResponse = {
    'user': {
      'id': 'guest_001',
      'name': 'Guest User',
      'subscription': 'free',
      'constitution': 'unknown',
      'hemisphere': 'north',
    },
    'token': 'guest_token_abc123',
  };

  static const Map<String, dynamic> contentsResponse = {
    'total': 2,
    'page': 1,
    'items': [content, contentTea],
  };

  static const Map<String, dynamic> constitutionQuestionsResponse = {
    'total': 25,
    'questions': [
      {
        'id': 'q_001',
        'text': '您容易感到疲乏吗？',
        'options': ['是的', '有时', '不是'],
      },
      {
        'id': 'q_002',
        'text': '您容易气短吗？',
        'options': ['是的', '有时', '不是'],
      },
    ],
  };

  static const Map<String, dynamic> dailyAdviceResponse = {
    'greeting': '早安',
    'solar_term': '立春',
    'advice': [
      '早睡早起，与日同步',
      '饮食宜温补，少食酸味',
      '适当运动，舒展筋骨',
    ],
  };
}
