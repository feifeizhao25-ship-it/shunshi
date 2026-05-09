import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../domain/entities/content.dart';
import '../../../core/constants/app_constants.dart';

class LibraryState {
  final List<Content> contents;
  final List<ContentCategory> categories;
  final bool isLoading;
  final String? error;
  
  const LibraryState({
    this.contents = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });
  
  LibraryState copyWith({
    List<Content>? contents,
    List<ContentCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      contents: contents ?? this.contents,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Dio _dio;
  
  LibraryNotifier()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        super(const LibraryState()) {
    loadContents();
  }
  
  Future<void> loadContents() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Fetch content types (categories) from backend
      final typesResp = await _dio.get(
        '/api/v1/contents/types',
        queryParameters: {'locale': 'en-US'},
      );
      final typesData = typesResp.data is Map
          ? (typesResp.data['data'] as List? ?? [])
          : typesResp.data as List;
      
      // Fetch all contents
      final contentResp = await _dio.get(
        '/api/v1/contents/',
        queryParameters: {'locale': 'en-US', 'limit': 100},
      );
      final respData = contentResp.data is Map ? contentResp.data : {};
      final contentItems = (respData['data'] as Map?)?['items'] as List? ?? [];
      
      // Map backend types to ContentType enum
      final typeMap = {
        'recipe': ContentType.food,
        'acupoint': ContentType.acupressure,
        'exercise': ContentType.stretch,
        'tips': ContentType.reflection,
      };
      
      // Parse content items from API
      final contents = <Content>[];
      for (final item in contentItems) {
        if (item is! Map<String, dynamic>) continue;
        final typeStr = item['type'] as String? ?? '';
        final ct = typeMap[typeStr] ?? ContentType.reflection;
        contents.add(Content(
          id: item['id']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          type: ct,
          imageUrl: item['image_url']?.toString(),
          durationSeconds: item['duration'] as int?,
          tags: (item['tags'] as List?)?.cast<String>() ?? [],
          steps: (item['steps'] as List?)?.cast<String>() ?? [],
          isPremium: item['is_premium'] == true,
        ));
      }
      
      // Parse categories
      final categories = <ContentCategory>[];
      for (final t in typesData) {
        if (t is! Map<String, dynamic>) continue;
        final typeId = t['id']?.toString() ?? '';
        final ct = typeMap[typeId] ?? ContentType.reflection;
        categories.add(ContentCategory(
          id: typeId,
          name: t['name']?.toString() ?? '',
          type: ct,
          iconUrl: null,
          contents: contents.where((c) => c.type == ct).toList(),
        ));
      }
      
      // If API returned no data, use fallback
      if (contents.isEmpty) {
        state = state.copyWith(
          contents: _fallbackContents,
          categories: _fallbackCategories,
          isLoading: false,
        );
      } else {
        // Merge with fallback for types not in backend
        _mergeFallback(contents, categories);
        state = state.copyWith(
          contents: contents,
          categories: categories,
          isLoading: false,
        );
      }
    } catch (e) {
      // Fallback to hardcoded data
      state = state.copyWith(
        contents: _fallbackContents,
        categories: _fallbackCategories,
        isLoading: false,
      );
    }
  }
  
  void _mergeFallback(List<Content> contents, List<ContentCategory> categories) {
    final existingTypes = categories.map((c) => c.type).toSet();
    for (final cat in _fallbackCategories) {
      if (!existingTypes.contains(cat.type)) {
        categories.add(cat);
        contents.addAll(cat.contents);
      }
    }
  }
  
  // ── Fallback Data ──────────────────────────────────────────────────────
  
  static List<ContentCategory> get _fallbackCategories => [
    const ContentCategory(id: 'breathing', name: 'Breathing', type: ContentType.breathing),
    const ContentCategory(id: 'stretch', name: 'Stretching', type: ContentType.stretch),
    const ContentCategory(id: 'tea', name: 'Tea Rituals', type: ContentType.teaRitual),
    const ContentCategory(id: 'sleep', name: 'Sleep', type: ContentType.sleep),
    const ContentCategory(id: 'meditation', name: 'Meditation', type: ContentType.meditation),
    const ContentCategory(id: 'reflection', name: 'Reflection', type: ContentType.reflection),
  ];
  
  static List<Content> get _fallbackContents => [
    // Breathing
    const Content(
      id: 'br1', title: '4-7-8 Breathing',
      description: 'A calming breath technique: inhale 4, hold 7, exhale 8. Activates parasympathetic nervous system.',
      type: ContentType.breathing, durationSeconds: 180,
      tags: ['beginner', 'calm', 'sleep-aid'],
      steps: ['Sit or lie down comfortably', 'Exhale completely through your mouth',
        'Inhale quietly through your nose for 4 counts', 'Hold your breath for 7 counts',
        'Exhale fully through your mouth for 8 counts', 'Repeat the cycle 4 times'],
    ),
    const Content(
      id: 'br2', title: 'Box Breathing',
      description: 'Equal phases of inhale, hold, exhale, hold. Used by Navy SEALs for calm focus.',
      type: ContentType.breathing, durationSeconds: 240,
      tags: ['focus', 'stress-relief', 'intermediate'],
      steps: ['Find a quiet place and sit upright', 'Breathe in slowly for 4 counts',
        'Hold for 4 counts', 'Exhale for 4 counts', 'Hold empty for 4 counts', 'Repeat 4-6 cycles'],
    ),
    const Content(
      id: 'br3', title: 'Diaphragmatic Breathing',
      description: 'Deep belly breathing to reduce stress and improve oxygen exchange.',
      type: ContentType.breathing, durationSeconds: 300,
      tags: ['beginner', 'relaxation', 'core'],
      steps: ['Lie on your back, knees bent', 'Place one hand on chest, one on belly',
        'Inhale through nose — belly rises', 'Exhale through mouth — belly falls',
        'Keep chest still throughout', 'Practice for 5-10 minutes'],
    ),
    // Stretching
    const Content(
      id: 'st1', title: 'Morning Sun Salutation',
      description: 'A flowing sequence to greet the day, combining breath and movement.',
      type: ContentType.stretch, durationSeconds: 600,
      tags: ['morning', 'full-body', 'energizing'],
      steps: ['Stand tall, arms at sides', 'Inhale — reach arms overhead',
        'Exhale — fold forward', 'Inhale — half lift, flat back',
        'Step back to plank', 'Lower to chaturanga', 'Upward dog', 'Downward dog', 'Repeat 3-5 rounds'],
    ),
    const Content(
      id: 'st2', title: 'Desk Stretch Routine',
      description: 'Quick stretches you can do at your desk to relieve tension.',
      type: ContentType.stretch, durationSeconds: 300,
      tags: ['office', 'quick', 'neck-shoulders'],
      steps: ['Neck rolls — 5 each direction', 'Shoulder shrugs — 10 reps',
        'Seated spinal twist — each side', 'Wrist circles — 10 each',
        'Chest opener — clasp hands behind back', 'Seated forward fold — hold 30s'],
    ),
    const Content(
      id: 'st3', title: 'Evening Wind-Down Stretch',
      description: 'Gentle stretches to release the day and prepare for sleep.',
      type: ContentType.stretch, durationSeconds: 480,
      tags: ['evening', 'relaxation', 'sleep-prep'],
      steps: ['Child\'s pose — 1 min', 'Cat-cow — 10 rounds',
        'Supine twist — each side 30s', 'Happy baby — 1 min',
        'Legs up the wall — 3 min', 'Savasana — 2 min'],
    ),
    // Tea Rituals
    const Content(
      id: 'te1', title: 'Morning Green Tea Ritual',
      description: 'Start your day with mindful tea preparation and appreciation.',
      type: ContentType.teaRitual, durationSeconds: 600,
      tags: ['morning', 'green-tea', 'mindfulness'],
      steps: ['Heat water to 175F (80C)', 'Warm your cup with hot water',
        'Add 1 tsp loose leaf green tea', 'Pour water, steep 2-3 min',
        'Observe the color and aroma', 'Sip slowly, noticing each flavor note'],
    ),
    const Content(
      id: 'te2', title: 'Afternoon Oolong Break',
      description: 'A midday pause with oolong tea to reset focus and energy.',
      type: ContentType.teaRitual, durationSeconds: 480,
      tags: ['afternoon', 'oolong', 'focus'],
      steps: ['Prepare gaiwan or small teapot', 'Heat water to 195F (90C)',
        'Quick rinse the leaves', 'First infusion — 30 seconds',
        'Second infusion — 45 seconds', 'Notice how flavor evolves'],
    ),
    const Content(
      id: 'te3', title: 'Evening Chamomile Calm',
      description: 'Wind down with a soothing herbal infusion before bed.',
      type: ContentType.teaRitual, durationSeconds: 420,
      tags: ['evening', 'herbal', 'sleep-aid'],
      steps: ['Boil fresh water', 'Add 1 tbsp dried chamomile flowers',
        'Steep covered for 5 minutes', 'Add honey if desired',
        'Find a quiet corner', 'Sip slowly, letting go of the day'],
    ),
    // Sleep
    const Content(
      id: 'sl1', title: 'Progressive Muscle Relaxation',
      description: 'Systematically tense and release muscle groups for deep relaxation.',
      type: ContentType.sleep, durationSeconds: 900,
      tags: ['sleep', 'relaxation', 'body-scan'],
      steps: ['Lie in bed, eyes closed', 'Tense feet — 5s, release — 10s',
        'Tense calves — 5s, release — 10s', 'Work up through each muscle group',
        'Thighs, abdomen, hands, arms, shoulders, face', 'Finish with full body awareness'],
    ),
    const Content(
      id: 'sl2', title: 'Guided Sleep Visualization',
      description: 'A calming journey through a peaceful landscape to drift off.',
      type: ContentType.sleep, durationSeconds: 1200,
      tags: ['sleep', 'visualization', 'guided'],
      steps: ['Close your eyes and take 3 deep breaths', 'Imagine walking through a peaceful garden',
        'Notice the flowers, trees, and sounds', 'Find a comfortable bench by a stream',
        'Listen to the gentle water flowing', 'Let yourself rest here as sleep comes'],
    ),
    const Content(
      id: 'sl3', title: 'Body Scan for Sleep',
      description: 'A mindful body scan to release tension and prepare for rest.',
      type: ContentType.sleep, durationSeconds: 720,
      tags: ['sleep', 'mindfulness', 'body-scan'],
      steps: ['Lie comfortably in bed', 'Bring attention to your toes',
        'Notice any tension, then let it go', 'Slowly move attention up your body',
        'Feet, legs, hips, belly, chest, arms, neck, head', 'Rest in whole-body awareness'],
    ),
    // Meditation
    const Content(
      id: 'md1', title: '5-Minute Mindfulness',
      description: 'A short meditation to center yourself in the present moment.',
      type: ContentType.meditation, durationSeconds: 300,
      tags: ['beginner', 'mindfulness', 'quick'],
      steps: ['Sit comfortably, close your eyes', 'Take 3 deep breaths',
        'Let breathing return to natural', 'Notice thoughts without judgment',
        'Return focus to breath when distracted', 'Gently open your eyes'],
    ),
    const Content(
      id: 'md2', title: 'Loving-Kindness Meditation',
      description: 'Cultivate compassion for yourself and others through guided phrases.',
      type: ContentType.meditation, durationSeconds: 600,
      tags: ['compassion', 'heart-opening', 'intermediate'],
      steps: ['Sit quietly, close your eyes', 'Repeat: May I be happy, may I be healthy',
        'Extend to a loved one', 'Extend to a neutral person',
        'Extend to all beings everywhere', 'Rest in feelings of warmth and connection'],
    ),
    const Content(
      id: 'md3', title: 'Walking Meditation',
      description: 'Bring meditation into movement with slow, mindful walking.',
      type: ContentType.meditation, durationSeconds: 480,
      tags: ['movement', 'outdoor', 'mindfulness'],
      steps: ['Find a quiet path, 10-20 paces long', 'Stand still, take 3 breaths',
        'Lift, move, place — one slow step at a time', 'Feel each part of the foot',
        'Turn slowly at the end', 'Continue for 5-10 minutes'],
    ),
    // Reflection
    const Content(
      id: 'rf1', title: 'Evening Gratitude Journal',
      description: 'Reflect on your day with gratitude prompts for a peaceful close.',
      type: ContentType.reflection, durationSeconds: 300,
      tags: ['evening', 'gratitude', 'journaling'],
      steps: ['Find a quiet spot with your journal', 'Write 3 things you are grateful for today',
        'Recall one moment of joy', 'Note one thing you learned',
        'Set an intention for tomorrow', 'Close with a deep breath'],
    ),
    const Content(
      id: 'rf2', title: 'Weekly Reflection',
      description: 'A deeper weekly practice to review growth and set intentions.',
      type: ContentType.reflection, durationSeconds: 600,
      tags: ['weekly', 'growth', 'planning'],
      steps: ['Review your week — what stood out?', 'Celebrate 3 wins, however small',
        'What challenged you? What did you learn?', 'Rate your wellness: body, mind, spirit',
        'Set 1-2 intentions for next week', 'Close with appreciation for yourself'],
    ),
    const Content(
      id: 'rf3', title: 'Seasonal Intention Setting',
      description: 'Align your goals with the energy of the current season.',
      type: ContentType.reflection, durationSeconds: 480,
      tags: ['seasonal', 'intention', 'alignment'],
      steps: ['Reflect on the current season\'s energy', 'What wants to be born in you now?',
        'Choose one word as your seasonal anchor', 'Identify 3 aligned actions',
        'Write your intention where you can see it', 'Revisit at each solar term'],
    ),
    // Story
    const Content(
      id: 'sr1', title: 'The Wisdom of Water',
      description: 'A Taoist tale about flexibility, persistence, and inner strength.',
      type: ContentType.story, durationSeconds: 300,
      tags: ['taoist', 'wisdom', 'philosophy'],
      steps: ['Find a comfortable position', 'Listen or read the story of water and rock',
        'Water is soft yet carves canyons', 'It takes the shape of any container',
        'Yet nothing can withstand its persistence', 'Reflect: where can you be more like water?'],
    ),
    const Content(
      id: 'sr2', title: 'The Bamboo and the Oak',
      description: 'A story about resilience — bending vs breaking in lifes storms.',
      type: ContentType.story, durationSeconds: 240,
      tags: ['resilience', 'nature', 'parable'],
      steps: ['Settle in and take a breath', 'The great oak stood proud and rigid',
        'The bamboo swayed with every wind', 'When the hurricane came, the oak fell',
        'But the bamboo bent and survived', 'Reflect: when did bending serve you better than resisting?'],
    ),
    const Content(
      id: 'sr3', title: 'The Empty Cup',
      description: 'A Zen story about the importance of beginner\'s mind and humility.',
      type: ContentType.story, durationSeconds: 180,
      tags: ['zen', 'humility', 'learning'],
      steps: ['A scholar visited a Zen master', 'The master poured tea until it overflowed',
        '"Like this cup, you are full of your own opinions"', '"How can I show you Zen unless you first empty your cup?"',
        'The scholar was humbled', 'Reflect: what do you need to empty to learn something new?'],
    ),
  ];
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

final selectedContentTypeProvider = StateProvider<ContentType?>((ref) => null);
