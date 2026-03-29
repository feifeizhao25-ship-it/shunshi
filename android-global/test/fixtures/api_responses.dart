// Test fixtures — reusable mock data for unit and widget tests
// These mirror the JSON structure returned by the SEASONS backend.

class ChatFixtures {
  static Map<String, dynamic> calmGreeting = {
    'text': 'Hello! How are you feeling today?',
    'tone': 'calm',
    'suggestions': ['Share how you feel', 'Take a deep breath'],
    'follow_up': {'in_days': 2, 'intent': 'general_check_in'},
    'safety_flag': 'none',
    'model': 'seasons-small',
    'tokens_used': 45,
    'latency_ms': 890,
  };

  static Map<String, dynamic> tiredResponse = {
    'text': 'Feeling tired is your body asking for rest. Here is a gentle 5-minute wind-down routine...',
    'tone': 'warm',
    'suggestions': ['Try the 4-7-8 breathing exercise', 'A cup of chamomile tea'],
    'follow_up': {'in_days': 1, 'intent': 'sleep_check'},
    'safety_flag': 'none',
    'model': 'seasons-small',
    'tokens_used': 52,
    'latency_ms': 1020,
  };

  static Map<String, dynamic> breathingExercise = {
    'text': 'Let me guide you through a simple breathing exercise.',
    'tone': 'gentle',
    'suggestions': [
      'Find a comfortable seated position',
      'Breathe in for 4 counts',
      'Hold for 4 counts',
      'Exhale for 6 counts',
    ],
    'safety_flag': 'none',
    'model': 'seasons-small',
    'tokens_used': 38,
    'latency_ms': 720,
  };

  static Map<String, dynamic> highRiskEmotionalResponse = {
    'text':
        'I hear that you are going through something very difficult right now. Thank you for sharing this with me.',
    'tone': 'calm',
    'suggestions': [],
    'safety_flag': 'escalate',
    'model': 'seasons-small',
    'tokens_used': 30,
    'latency_ms': 600,
  };
}

class HomeFixtures {
  static Map<String, dynamic> dashboardSpring = {
    'greeting': 'Good morning, Jane',
    'daily_insight': {
      'id': 'ins_spring_1',
      'text':
          'Spring energy is building inside you. Today is a wonderful day to start something small.',
      'season': 'spring',
      'generated_at': '2025-03-20T08:00:00Z',
    },
    'suggestions': [
      {
        'id': 'sug_001',
        'text': 'Take a short walk after lunch',
        'category': 'movement',
        'icon_name': 'walk',
      },
      {
        'id': 'sug_002',
        'text': 'Brew a cup of herbal tea',
        'category': 'ritual',
        'icon_name': 'tea',
      },
    ],
    'season_card': {
      'name': 'Spring',
      'emoji': '🌸',
      'color': '#A8D5A2',
    },
  };

  static Map<String, dynamic> dashboardWinter = {
    'greeting': 'Good evening',
    'daily_insight': {
      'id': 'ins_winter_1',
      'text': 'Winter is a season of depth. Give yourself permission to rest.',
      'season': 'winter',
      'generated_at': '2025-12-20T18:00:00Z',
    },
    'suggestions': [
      {
        'id': 'sug_010',
        'text': 'Take 5 slow, deep breaths',
        'category': 'breathing',
        'icon_name': 'breathe',
      },
    ],
    'season_card': {
      'name': 'Winter',
      'emoji': '❄️',
      'color': '#A5C4D4',
    },
  };
}

class ReflectionFixtures {
  static List<Map<String, dynamic>> reflectionList = [
    {
      'id': 'ref_001',
      'date': '2025-03-20T00:00:00Z',
      'mood': 'calm',
      'energy': 'medium',
      'sleep': 'good',
      'notes': 'Felt good after the morning walk.',
    },
    {
      'id': 'ref_002',
      'date': '2025-03-19T00:00:00Z',
      'mood': 'grateful',
      'energy': 'high',
      'sleep': 'excellent',
      'notes': null,
    },
    {
      'id': 'ref_003',
      'date': '2025-03-18T00:00:00Z',
      'mood': 'tired',
      'energy': 'low',
      'sleep': 'poor',
      'notes': 'Long day at work.',
    },
  ];

  static Map<String, dynamic> weeklyReflection = {
    'ai_summary': 'A calm week with improving energy levels.',
    'ai_insight': 'Your sleep improved mid-week.',
    'mood_trend': ['calm', 'good', 'grateful', 'energetic', 'calm', 'happy', 'hopeful'],
    'average_energy': 'medium',
    'average_sleep': 'good',
    'streak_days': 5,
  };
}

class ContentFixtures {
  static List<Map<String, dynamic>> contentList = [
    {
      'id': 'cnt_001',
      'title': 'Morning Breathing Exercise',
      'description': 'A gentle 5-minute breathing exercise to start your day.',
      'type': 'breathing',
      'image_url': 'https://cdn.example.com/breathing.jpg',
      'audio_url': null,
      'video_url': null,
      'duration_seconds': 300,
      'tags': ['morning', 'breathing', 'energy'],
      'is_premium': false,
    },
    {
      'id': 'cnt_002',
      'title': 'Sleep Story: Forest Rain',
      'description': 'A calming audio story to help you drift off.',
      'type': 'story',
      'image_url': 'https://cdn.example.com/forest.jpg',
      'audio_url': 'https://cdn.example.com/forest-rain.mp3',
      'duration_seconds': 1200,
      'tags': ['sleep', 'relaxation'],
      'is_premium': true,
    },
    {
      'id': 'cnt_003',
      'title': 'Spring Tea Rituals',
      'description': 'Green tea and jasmine — the perfect spring combination.',
      'type': 'teaRitual',
      'image_url': 'https://cdn.example.com/tea.jpg',
      'tags': ['tea', 'spring', 'ritual'],
      'is_premium': false,
    },
  ];
}

class UserFixtures {
  static Map<String, dynamic> freeUser = {
    'id': 'usr_free_001',
    'email': 'free@example.com',
    'name': 'Free User',
    'country': 'US',
    'subscription': 'free',
    'created_at': '2025-01-01T00:00:00Z',
  };

  static Map<String, dynamic> premiumUser = {
    'id': 'usr_premium_001',
    'email': 'premium@example.com',
    'name': 'Premium User',
    'avatar_url': 'https://cdn.example.com/avatar.jpg',
    'country': 'UK',
    'subscription': 'serenity',
    'created_at': '2025-01-15T00:00:00Z',
  };
}
