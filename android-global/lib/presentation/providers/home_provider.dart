import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ai_response.dart';

final apiBaseUrlProvider = Provider<String>((ref) {
  return AppConstants.baseUrl;
});

class HomeState {
  final DailyInsight? dailyInsight;
  final List<GentleSuggestion> suggestions;
  final SeasonCardData? seasonCard;
  final String? greeting;
  final int streak;
  final String subscription;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.dailyInsight,
    this.suggestions = const [],
    this.seasonCard,
    this.greeting,
    this.streak = 0,
    this.subscription = 'free',
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    DailyInsight? dailyInsight,
    List<GentleSuggestion>? suggestions,
    SeasonCardData? seasonCard,
    String? greeting,
    int? streak,
    String? subscription,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      dailyInsight: dailyInsight ?? this.dailyInsight,
      suggestions: suggestions ?? this.suggestions,
      seasonCard: seasonCard ?? this.seasonCard,
      greeting: greeting ?? this.greeting,
      streak: streak ?? this.streak,
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeasonCardData {
  final String name;
  final String phase;
  final String emoji;
  final String color;
  final String hemisphere;
  final String insight;

  const SeasonCardData({
    required this.name,
    required this.phase,
    required this.emoji,
    required this.color,
    required this.hemisphere,
    required this.insight,
  });

  factory SeasonCardData.fromJson(Map<String, dynamic> json) {
    return SeasonCardData(
      name: json['name'] ?? '',
      phase: json['phase'] ?? '',
      emoji: json['emoji'] ?? _getEmoji(json['name'] ?? ''),
      color: json['color'] ?? '#81C784',
      hemisphere: json['hemisphere'] ?? 'north',
      insight: json['insight'] ?? '',
    );
  }

  static String _getEmoji(String season) {
    switch (season.toLowerCase()) {
      case 'spring': return '🌱';
      case 'summer': return '☀️';
      case 'autumn': return '🍂';
      case 'winter': return '❄️';
      default: return '🌿';
    }
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final Dio _dio;
  final String _baseUrl;

  HomeNotifier(this._baseUrl) : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )), super(const HomeState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Read user_id and hemisphere from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'seasons-user';
    final hemisphere = prefs.getString('hemisphere') ?? 'north';

    try {
      final response = await _dio.get(
        '/api/v1/seasons/home/dashboard',
        queryParameters: {
          'user_id': userId,
          'hemisphere': hemisphere,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Parse daily insight
      final insightJson = data['daily_insight'] ?? {};
      final insight = DailyInsight(
        id: insightJson['id'] ?? 'daily-${DateTime.now().millisecondsSinceEpoch}',
        text: insightJson['text'] ?? 'Take it slow today',
        season: insightJson['season'] ?? 'spring',
        generatedAt: DateTime.tryParse(insightJson['generated_at'] ?? '') ?? DateTime.now(),
      );

      // Parse suggestions
      final suggestionsList = (data['suggestions'] as List?)
              ?.map((s) => GentleSuggestion(
                    id: s['id'] ?? 's-${s['text']?.hashCode ?? 0}',
                    text: s['text'] ?? '',
                    category: s['category'] ?? 'calm',
                    iconName: s['icon_name'] ?? _emojiToIconName(null),
                  ))
              .toList() ??
          [];

      // Parse season card
      SeasonCardData? seasonCard;
      if (data['season_card'] != null) {
        seasonCard = SeasonCardData.fromJson(data['season_card']);
      }

      // Parse user
      final userJson = data['user'] ?? {};

      state = state.copyWith(
        dailyInsight: insight,
        suggestions: suggestionsList,
        seasonCard: seasonCard,
        greeting: data['greeting'] ?? _getDefaultGreeting(),
        streak: userJson['streak'] ?? 0,
        subscription: userJson['subscription'] ?? 'free',
        isLoading: false,
      );
    } catch (e) {
      // Fallback to hardcoded data on error
      state = state.copyWith(
        dailyInsight: _getFallbackInsight(),
        suggestions: _getFallbackSuggestions(),
        seasonCard: const SeasonCardData(
          name: 'Spring',
          phase: 'early',
          emoji: '🌱',
          color: '#81C784',
          hemisphere: 'north',
          insight: 'A new season of gentle beginnings.',
        ),
        greeting: _getDefaultGreeting(),
        isLoading: false,
      );
    }
  }

  String _getDefaultGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  DailyInsight _getFallbackInsight() {
    final month = DateTime.now().month;
    String season;
    if (month >= 3 && month <= 5) season = 'spring';
    else if (month >= 6 && month <= 8) season = 'summer';
    else if (month >= 9 && month <= 11) season = 'autumn';
    else season = 'winter';

    final insights = {
      'spring': 'Like the earth after winter, this is your time to plant seeds. Not big changes — just one small thing.',
      'summer': 'The warmth invites you to move your body and soak in the light. Stay hydrated. Make time for what makes you alive.',
      'autumn': 'Autumn whispers: slow down. As the leaves let go, you too can release what you\'ve been carrying.',
      'winter': 'Winter is not emptiness — it\'s depth. Give yourself permission to rest deeply today.',
    };

    return DailyInsight(
      id: 'fallback',
      text: insights[season] ?? insights['spring']!,
      season: season,
      generatedAt: DateTime.now(),
    );
  }

  List<GentleSuggestion> _getFallbackSuggestions() {
    return const [
      GentleSuggestion(id: 's1', text: 'Take three slower breaths before checking your phone', category: 'breathing', iconName: 'breathe'),
      GentleSuggestion(id: 's2', text: 'Make a warm drink and just hold it for a moment', category: 'ritual', iconName: 'tea'),
      GentleSuggestion(id: 's3', text: 'Step outside, even for 60 seconds', category: 'movement', iconName: 'walk'),
    ];
  }

  String _emojiToIconName(String? emoji) {
    switch (emoji) {
      case '🌅': return 'sunrise';
      case '☕': return 'tea';
      case '🚶': return 'walk';
      case '🌿': return 'breathe';
      case '💧': return 'water';
      case '👀': return 'look_away';
      case '🍵': return 'tea';
      case '📖': return 'read';
      case '🌙': return 'moon';
      case '🫁': return 'breathe';
      case '💜': return 'stretch';
      case '📝': return 'journal';
      default: return 'calm';
    }
  }

  Future<void> refresh() async {
    await loadData();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return HomeNotifier(baseUrl);
});
