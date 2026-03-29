import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/content.dart';
import '../../../domain/entities/ai_response.dart';

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
  SeasonsNotifier() : super(const SeasonsState()) {
    loadSeasonInsights();
  }
  
  Future<void> loadSeasonInsights() async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    final insights = {
      Season.spring: const SeasonInsight(
        season: 'spring',
        insight: 'Spring is a season of renewal and awakening. Like the earth after winter, this is your time to plant seeds for new habits, embrace fresh beginnings, and let rising energy carry you forward. Move more, eat lighter, and open your windows to the world.',
        foodSuggestions: [
          'Asparagus — tender, nutrient-rich, and at its peak',
          'Spinach and leafy greens — iron-rich for renewed energy',
          'Strawberries — sweet, antioxidant-packed spring gems',
          'Green tea — a clean, focusing brew for fresh mornings',
          'Lemon water — start each day with warmth and vitamin C',
          'Sprouts and microgreens — vibrant, living nutrition',
          'Radishes — crisp, peppery, and perfect for salads',
        ],
        stretchRoutines: [
          'Morning sun salutation — greet the new day with your whole body',
          'Gentle neck rolls — release overnight tension',
          'Hip opening sequence — unblock stored energy from winter',
          'Side stretches — create space for deeper breathing',
        ],
        sleepRituals: [
          'Open your window for cool, fresh spring air',
          'Light stretching before bed to release the day',
          'Herbal tea with lavender and chamomile',
          'Set a consistent wind-down time as days grow longer',
        ],
      ),
      Season.summer: const SeasonInsight(
        season: 'summer',
        insight: 'Summer radiates energy and vitality. This is the season to move your body, connect with nature, and embrace the warmth. Balance the heat with cooling foods, stay hydrated, and protect your energy by allowing time for rest between activities.',
        foodSuggestions: [
          'Watermelon — nature\'s perfect hydrator on hot days',
          'Cucumber salads — cool, crisp, and refreshing',
          'Fresh berries — blueberries, raspberries, blackberries galore',
          'Coconut water — electrolyte-rich natural refreshment',
          'Mint tea over ice — cool your body from the inside out',
          'Light summer gazpacho — nourishing without weighing you down',
          'Stone fruits — peaches, plums, and nectarines at their best',
        ],
        stretchRoutines: [
          'Cool morning yoga — greet the day before the heat sets in',
          'Evening walk — gentle movement as the air cools down',
          'Heart-opening poses — chest expanders and gentle backbends',
          'Swimming or water movement — full-body exercise that keeps you cool',
        ],
        sleepRituals: [
          'Keep your room cool — use a fan or air conditioning',
          'Light cotton or linen sheets for breathability',
          'Enjoy the evening outdoor breeze before bed',
          'Freeze a damp washcloth for a cooling eye compress',
        ],
      ),
      Season.autumn: const SeasonInsight(
        season: 'autumn',
        insight: 'Autumn is a season of transition and introspection. Like the trees releasing their leaves, this is your time to let go of what no longer serves you. Ground yourself with warming foods, reflective practices, and deeper connections to the people and things you cherish.',
        foodSuggestions: [
          'Sweet potatoes and squash — grounding, warm, and nourishing',
          'Nuts and seeds — walnuts, almonds, and pumpkin seeds for healthy fats',
          'Ginger and cinnamon tea — warming spices that comfort from within',
          'Hearty vegetable soups — slow-cooked goodness for cooler evenings',
          'Apples and pears — fiber-rich autumn staples',
          'Mushrooms — immune-supporting and deeply savory',
          'Oatmeal with honey — a warming, grounding breakfast ritual',
        ],
        stretchRoutines: [
          'Grounding standing poses — feel your roots in the earth',
          'Spinal twists — wring out tension and aid digestion',
          'Gentle forward folds — turn your attention inward',
          'Restorative poses with bolsters — deeply restful and warming',
        ],
        sleepRituals: [
          'Warm bath with Epsom salts and lavender oil',
          'Read a physical book before bed — no screens',
          'Journaling practice — reflect on your day with gratitude',
          'Adjust your bedtime earlier as daylight shortens',
        ],
      ),
      Season.winter: const SeasonInsight(
        season: 'winter',
        insight: 'Winter invites introspection and deep rest. In a world that glorifies constant productivity, winter reminds us that stillness is productive too. This is the season to nourish deeply, rest intentionally, and tend to your inner landscape with kindness and patience.',
        foodSuggestions: [
          'Slow-cooked bone broth — deeply nourishing and warming',
          'Root vegetables — carrots, parsnips, beets, and turnips',
          'Hearty stews and casseroles — comfort in every spoonful',
          'Herbal infusions — ginger, echinacea, and elderberry',
          'Dark leafy greens — kale and collard greens for winter immunity',
          'Citrus fruits — oranges and grapefruits for vitamin C',
          'Warm oatmeal with cinnamon and nuts — a cozy morning ritual',
        ],
        stretchRoutines: [
          'Gentle indoor yoga — slow, intentional movement',
          'Self-massage with warm oil — nourish your skin and calm your nerves',
          'Breathing exercises — alternate nostril breathing for balance',
          'Seated twists and gentle forward folds — stay flexible indoors',
        ],
        sleepRituals: [
          'Embrace an earlier bedtime — honor the shorter days',
          'Meditation practice — 10 minutes of stillness before sleep',
          'Warm compress on your eyes — release the day\'s screen fatigue',
          'Extra blankets and warm socks — comfort signals safety to your body',
        ],
      ),
    };
    
    state = state.copyWith(
      seasonInsights: insights,
      isLoading: false,
    );
  }
}

final seasonsProvider = StateNotifierProvider<SeasonsNotifier, SeasonsState>((ref) {
  return SeasonsNotifier();
});
