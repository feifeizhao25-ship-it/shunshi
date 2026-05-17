import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/content.dart';
import '../../../domain/entities/ai_response.dart';
import '../../../core/constants/app_constants.dart';

class SeasonsState {
  final Map<Season, SeasonInsight> seasonInsights;
  final bool isLoading;
  final String? error;
  
  const SeasonsState({
    this.seasonInsights = const {},
    this.isLoading = false,
    this.error,
  });
  
  SeasonsState copyWith({
    Map<Season, SeasonInsight>? seasonInsights,
    bool? isLoading,
    String? error,
  }) {
    return SeasonsState(
      seasonInsights: seasonInsights ?? this.seasonInsights,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SeasonsNotifier extends StateNotifier<SeasonsState> {
  final Dio _dio;
  
  SeasonsNotifier()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        super(const SeasonsState()) {
    loadSeasonInsights();
  }
  
  Future<void> loadSeasonInsights() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Fetch current season from backend
      final prefs = await SharedPreferences.getInstance();
      final hemisphere = prefs.getString('hemisphere') ?? 'north';
      
      final Map<Season, SeasonInsight> insights = {};
      
      try {
        final seasonResp = await _dio.get(
          '/api/v1/solar-terms/current',
          queryParameters: {
            'user_id': 'seasons-user',
            'hemisphere': hemisphere,
          },
        );
        final data = seasonResp.data is Map
            ? (seasonResp.data['data'] as Map<String, dynamic>? ?? seasonResp.data)
            : seasonResp.data as Map<String, dynamic>;
        
        final name = (data['name'] ?? '').toString().toLowerCase();
        final season = _parseSeason(name);
        if (season != null) {
          insights[season] = SeasonInsight(
            season: name,
            insight: data['insight'] ?? '',
            foodSuggestions: (data['food_suggestions'] as List?)?.cast<String>() ?? [],
            stretchRoutines: (data['stretch_routines'] as List?)?.cast<String>() ?? [],
            sleepRituals: (data['sleep_rituals'] as List?)?.cast<String>() ?? [],
          );
        }
      } catch (_) {}
      
      // Fill any missing seasons with fallback data
      _ensureAllSeasons(insights);
      
      state = state.copyWith(
        seasonInsights: insights,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to hardcoded data on error
      final fallback = _getFallbackInsights();
      state = state.copyWith(
        seasonInsights: fallback,
        isLoading: false,
      );
    }
  }
  
  void _ensureAllSeasons(Map<Season, SeasonInsight> insights) {
    final fallback = _getFallbackInsights();
    for (final entry in fallback.entries) {
      insights.putIfAbsent(entry.key, () => entry.value);
    }
  }
  
  Season? _parseSeason(String name) {
    switch (name) {
      case 'spring': return Season.spring;
      case 'summer': return Season.summer;
      case 'autumn': return Season.autumn;
      case 'winter': return Season.winter;
      default: return null;
    }
  }
  
  Map<Season, SeasonInsight> _getFallbackInsights() {
    return {
      Season.spring: const SeasonInsight(
        season: 'spring',
        insight: 'Spring is a season of renewal and awakening. Like the earth after winter, this is your time to plant seeds for new habits, embrace fresh beginnings, and let rising energy carry you forward.',
        foodSuggestions: [
          'Asparagus — tender, nutrient-rich, and at its peak',
          'Spinach and leafy greens — iron-rich for renewed energy',
          'Strawberries — sweet, antioxidant-packed spring gems',
          'Green tea — a clean, focusing brew for fresh mornings',
          'Lemon water — start each day with warmth and vitamin C',
        ],
        stretchRoutines: [
          'Morning sun salutation — greet the new day with your whole body',
          'Gentle neck rolls — release overnight tension',
          'Hip opening sequence — unblock stored energy from winter',
        ],
        sleepRituals: [
          'Open your window for cool, fresh spring air',
          'Light stretching before bed to release the day',
          'Herbal tea with lavender and chamomile',
        ],
      ),
      Season.summer: const SeasonInsight(
        season: 'summer',
        insight: 'Summer radiates energy and vitality. This is the season to move your body, connect with nature, and embrace the warmth. Balance the heat with cooling foods and stay hydrated.',
        foodSuggestions: [
          'Watermelon — nature\'s perfect hydrator on hot days',
          'Cucumber salads — cool, crisp, and refreshing',
          'Fresh berries — blueberries, raspberries, blackberries galore',
          'Coconut water — electrolyte-rich natural refreshment',
          'Mint tea over ice — cool your body from the inside out',
        ],
        stretchRoutines: [
          'Cool morning yoga — greet the day before the heat sets in',
          'Evening walk — gentle movement as the air cools down',
          'Heart-opening poses — chest expanders and gentle backbends',
        ],
        sleepRituals: [
          'Keep your room cool — use a fan or air conditioning',
          'Light cotton or linen sheets for breathability',
          'Enjoy the evening outdoor breeze before bed',
        ],
      ),
      Season.autumn: const SeasonInsight(
        season: 'autumn',
        insight: 'Autumn is a season of transition and introspection. Like the trees releasing their leaves, this is your time to let go of what no longer serves you. Ground yourself with warming foods and reflective practices.',
        foodSuggestions: [
          'Sweet potatoes and squash — grounding, warm, and nourishing',
          'Nuts and seeds — walnuts, almonds, and pumpkin seeds',
          'Ginger and cinnamon tea — warming spices that comfort from within',
          'Hearty vegetable soups — slow-cooked goodness for cooler evenings',
          'Apples and pears — fiber-rich autumn staples',
        ],
        stretchRoutines: [
          'Grounding standing poses — feel your roots in the earth',
          'Spinal twists — wring out tension and aid digestion',
          'Gentle forward folds — turn your attention inward',
        ],
        sleepRituals: [
          'Warm bath with Epsom salts and lavender oil',
          'Read a physical book before bed — no screens',
          'Journaling practice — reflect on your day with gratitude',
        ],
      ),
      Season.winter: const SeasonInsight(
        season: 'winter',
        insight: 'Winter invites introspection and deep rest. In a world that glorifies constant productivity, winter reminds us that stillness is productive too. Nourish deeply, rest intentionally, and tend to your inner landscape.',
        foodSuggestions: [
          'Slow-cooked bone broth — deeply nourishing and warming',
          'Root vegetables — carrots, parsnips, beets, and turnips',
          'Hearty stews and casseroles — comfort in every spoonful',
          'Herbal infusions — ginger, echinacea, and elderberry',
          'Dark leafy greens — kale and collard greens for winter immunity',
        ],
        stretchRoutines: [
          'Gentle indoor yoga — slow, intentional movement',
          'Self-massage with warm oil — nourish your skin and calm your nerves',
          'Breathing exercises — alternate nostril breathing for balance',
        ],
        sleepRituals: [
          'Embrace an earlier bedtime — honor the shorter days',
          'Meditation practice — 10 minutes of stillness before sleep',
          'Warm compress on your eyes — release the day\'s screen fatigue',
        ],
      ),
    };
  }
}

final seasonsProvider = StateNotifierProvider<SeasonsNotifier, SeasonsState>((ref) {
  return SeasonsNotifier();
});
