import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/entities/ai_response.dart';

class HomeState {
  final DailyInsight? dailyInsight;
  final List<GentleSuggestion> suggestions;
  final bool isLoading;
  final String? error;
  final String? greeting;
  final SeasonCard? seasonCard;

  const HomeState({
    this.dailyInsight,
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
    this.greeting,
    this.seasonCard,
  });

  HomeState copyWith({
    DailyInsight? dailyInsight,
    List<GentleSuggestion>? suggestions,
    bool? isLoading,
    String? error,
    String? greeting,
    SeasonCard? seasonCard,
  }) {
    return HomeState(
      dailyInsight: dailyInsight ?? this.dailyInsight,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      greeting: greeting ?? this.greeting,
      seasonCard: seasonCard ?? this.seasonCard,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  String? _userId;

  HomeNotifier() : super(const HomeState()) {
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // Read user_id and hemisphere from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    await loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);

    final prefs = await SharedPreferences.getInstance();
    final hemisphere = prefs.getString('hemisphere') ?? 'north';
    final userId = _userId ?? 'anonymous';

    try {
      final response = await ApiService.instance.getHomeDashboard(
        userId: userId,
        hemisphere: hemisphere,
      );

      state = state.copyWith(
        dailyInsight: response.insight,
        suggestions: response.suggestions,
        greeting: response.greeting,
        seasonCard: response.seasonCard,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to hardcoded data on API failure
      state = state.copyWith(
        dailyInsight: _getDailyInsight(),
        suggestions: _getSuggestions(),
        greeting: _getGreeting(),
        seasonCard: _getSeasonCard(),
        isLoading: false,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  DailyInsight _getDailyInsight() {
    final season = _getCurrentSeason();

    final insights = {
      'spring': DailyInsight(
        id: 'spring-1',
        text: 'Spring energy is building inside you. Today is a wonderful day to start something new — even something small. A new habit, a new walking route, a new recipe. Let the season\'s momentum carry you forward.',
        season: 'spring',
        generatedAt: DateTime.now(),
      ),
      'summer': DailyInsight(
        id: 'summer-1',
        text: 'The long days of summer invite you to move your body and soak in the light. Stay hydrated, protect your energy in the midday heat, and make time for the people and activities that make you come alive.',
        season: 'summer',
        generatedAt: DateTime.now(),
      ),
      'autumn': DailyInsight(
        id: 'autumn-1',
        text: 'Autumn whispers: slow down. As the leaves let go, you too can release what you have been carrying. Today, try one small act of letting go — a lingering thought, an old habit, something that no longer fits.',
        season: 'autumn',
        generatedAt: DateTime.now(),
      ),
      'winter': DailyInsight(
        id: 'winter-1',
        text: 'Winter is not a season of emptiness — it is a season of depth. Beneath the quiet surface, roots are growing. Today, give yourself permission to rest deeply, even if just for five quiet minutes.',
        season: 'winter',
        generatedAt: DateTime.now(),
      ),
    };

    return insights[season] ?? const DailyInsight(
      id: 'default',
      text: 'Every day is a fresh start. Take a deep breath, check in with yourself, and choose one small thing that will make today a little better than yesterday.',
      season: 'all',
      generatedAt: null,
    );
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  SeasonCard _getSeasonCard() {
    final season = _getCurrentSeason();
    final cards = {
      'spring': const SeasonCard(name: 'Spring', emoji: '🌸', color: '#A8D5A2'),
      'summer': const SeasonCard(name: 'Summer', emoji: '☀️', color: '#FFE066'),
      'autumn': const SeasonCard(name: 'Autumn', emoji: '🍂', color: '#D4A373'),
      'winter': const SeasonCard(name: 'Winter', emoji: '❄️', color: '#A5C4D4'),
    };
    return cards[season] ?? const SeasonCard(name: 'Spring', emoji: '🌸', color: '#A8D5A2');
  }

  List<GentleSuggestion> _getSuggestions() {
    return [
      const GentleSuggestion(
        id: 's1',
        text: 'Take a short walk after lunch',
        category: 'movement',
        iconName: 'walk',
      ),
      const GentleSuggestion(
        id: 's2',
        text: 'Brew a cup of herbal tea',
        category: 'ritual',
        iconName: 'tea',
      ),
      const GentleSuggestion(
        id: 's3',
        text: 'Stretch your shoulders for 2 minutes',
        category: 'movement',
        iconName: 'stretch',
      ),
      const GentleSuggestion(
        id: 's4',
        text: 'Write down one thing you are grateful for',
        category: 'reflection',
        iconName: 'journal',
      ),
      const GentleSuggestion(
        id: 's5',
        text: 'Take 5 slow, deep breaths right now',
        category: 'breathing',
        iconName: 'breathe',
      ),
      const GentleSuggestion(
        id: 's6',
        text: 'Drink a full glass of water',
        category: 'wellness',
        iconName: 'water',
      ),
    ];
  }

  Future<void> refresh() async {
    await loadData();
  }

  void toggleSuggestion(String id) {
    final updated = state.suggestions.map((s) {
      if (s.id == id) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    state = state.copyWith(suggestions: updated);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
