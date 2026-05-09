class BodyType {
  final String id;
  final String name;
  final String emoji;
  final String tagline;
  final List<String> traits;
  final List<String> recommendations;

  const BodyType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.traits,
    required this.recommendations,
  });
}

class Recipe {
  final String name;
  final String season;
  final String emoji;
  final List<String> ingredients;
  final List<String> steps;
  final String benefits;

  const Recipe({
    required this.name,
    required this.season,
    this.emoji = '🍽️',
    required this.ingredients,
    required this.steps,
    required this.benefits,
  });
}

class PressurePoint {
  final String name;
  final String location;
  final String technique;
  final String duration;
  final List<String> benefits;
  final String caution;

  const PressurePoint({
    required this.name,
    required this.location,
    required this.technique,
    required this.duration,
    required this.benefits,
    required this.caution,
  });
}

class HerbalTea {
  final String name;
  final String emoji;
  final String subtitle;
  final List<String> benefits;
  final String brewing;

  const HerbalTea({
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.benefits,
    required this.brewing,
  });
}

class MovementItem {
  final String name;
  final String emoji;
  final String subtitle;
  final String duration;
  final List<String> steps;

  const MovementItem({
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.duration,
    required this.steps,
  });
}

class SleepSound {
  final String name;
  final String emoji;
  final String subtitle;
  final String duration;

  const SleepSound({
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.duration,
  });
}

class WellnessContent {
  static const bodyTypes = [
    BodyType(
      id: 'vital',
      name: 'Vital',
      emoji: '⚡',
      tagline: 'Energized & Balanced',
      traits: ['High energy levels', 'Strong digestion', 'Good sleep quality', 'Natural resilience'],
      recommendations: [
        'Maintain variety in diet and movement',
        'Practice regular digital detox',
        'Enjoy seasonal transitions mindfully',
        'Challenge yourself with new activities',
      ],
    ),
    BodyType(
      id: 'sensitive',
      name: 'Sensitive',
      emoji: '🌿',
      tagline: 'Perceptive & Responsive',
      traits: ['Quick to notice changes', 'Emotionally aware', 'Reacts to environment', 'Intuitive eater'],
      recommendations: [
        'Prioritize gentle, warming foods',
        'Build consistent daily routines',
        'Practice grounding meditation',
        'Protect your energy with boundaries',
      ],
    ),
    BodyType(
      id: 'grounded',
      name: 'Grounded',
      emoji: '🪨',
      tagline: 'Stable & Nurturing',
      traits: ['Calm demeanor', 'Strong endurance', 'Methodical approach', 'Naturally warm'],
      recommendations: [
        'Incorporate stimulating activities',
        'Try lighter, seasonal meals',
        'Add variety to your exercise routine',
        'Practice mindful eating',
      ],
    ),
    BodyType(
      id: 'radiant',
      name: 'Radiant',
      emoji: '☀️',
      tagline: 'Warm & Dynamic',
      traits: ['Natural leader', 'Sharp focus', 'Strong metabolism', 'Goal-oriented'],
      recommendations: [
        'Balance intensity with cooling activities',
        'Practice restorative yoga or tai chi',
        'Stay hydrated with herbal teas',
        'Schedule regular relaxation time',
      ],
    ),
    BodyType(
      id: 'calm',
      name: 'Calm',
      emoji: '🌙',
      tagline: 'Thoughtful & Restorative',
      traits: ['Deep thinker', 'Creative mind', 'Sensitive to beauty', 'Values quality rest'],
      recommendations: [
        'Add warming spices to meals',
        'Engage in moderate cardio exercise',
        'Practice gratitude journaling',
        'Connect with nature regularly',
      ],
    ),
  ];

  static const recipes = [
    Recipe(
      name: 'Spring Green Smoothie',
      season: 'Spring',
      emoji: '🥬',
      ingredients: ['1 cup spinach', '1/2 banana', '1/2 cup mango chunks', '1 tbsp honey', '1 cup almond milk'],
      steps: ['Add all ingredients to blender', 'Blend until smooth', 'Serve immediately over ice'],
      benefits: 'Rich in iron and vitamins, energizing and refreshing for spring renewal.',
    ),
    Recipe(
      name: 'Summer Berry Bowl',
      season: 'Summer',
      emoji: '🫐',
      ingredients: ['1 cup mixed berries', '1/2 cup Greek yogurt', '2 tbsp granola', '1 tsp chia seeds', 'Drizzle of honey'],
      steps: ['Layer yogurt in a bowl', 'Top with fresh berries', 'Sprinkle granola and chia seeds', 'Drizzle with honey'],
      benefits: 'Antioxidant-rich and cooling, perfect for hot summer days.',
    ),
    Recipe(
      name: 'Autumn Harvest Soup',
      season: 'Autumn',
      emoji: '🎃',
      ingredients: ['2 cups butternut squash', '1 apple diced', '1 onion', '2 cups vegetable broth', '1 tsp cinnamon', '1/2 tsp nutmeg'],
      steps: ['Sauté onion until soft', 'Add squash, apple, and broth', 'Simmer 20 minutes until tender', 'Blend until smooth', 'Season with cinnamon and nutmeg'],
      benefits: 'Warming and grounding, rich in beta-carotene and fiber.',
    ),
    Recipe(
      name: 'Winter Golden Latte',
      season: 'Winter',
      emoji: '☕',
      ingredients: ['1 cup oat milk', '1 tsp turmeric', '1/2 tsp cinnamon', 'Pinch of black pepper', '1 tsp honey'],
      steps: ['Warm milk in a saucepan', 'Whisk in turmeric, cinnamon, and pepper', 'Heat gently for 3 minutes', 'Sweeten with honey and serve'],
      benefits: 'Anti-inflammatory and warming, boosts immunity during cold months.',
    ),
    Recipe(
      name: 'Mediterranean Quinoa Salad',
      season: 'Spring',
      emoji: '🥗',
      ingredients: ['1 cup cooked quinoa', '1/2 cucumber diced', '1/2 cup cherry tomatoes', '1/4 cup feta cheese', 'Fresh mint', 'Lemon olive oil dressing'],
      steps: ['Cool cooked quinoa', 'Dice vegetables and herbs', 'Toss all ingredients together', 'Dress with lemon and olive oil'],
      benefits: 'High protein, refreshing, and packed with Mediterranean flavors.',
    ),
    Recipe(
      name: 'Overnight Oats with Seeds',
      season: 'Autumn',
      emoji: '🥣',
      ingredients: ['1/2 cup rolled oats', '1/2 cup milk', '1 tbsp flax seeds', '1 tbsp pumpkin seeds', '1/2 tsp vanilla extract', 'Fresh fruit topping'],
      steps: ['Combine oats and milk in a jar', 'Add seeds and vanilla', 'Refrigerate overnight', 'Top with fresh fruit in the morning'],
      benefits: 'Rich in omega-3s and fiber, supports digestion and sustained energy.',
    ),
    Recipe(
      name: 'Grilled Salmon with Herbs',
      season: 'Summer',
      emoji: '🐟',
      ingredients: ['1 salmon fillet', 'Fresh dill and thyme', '1 lemon', '2 cloves garlic', '1 tbsp olive oil'],
      steps: ['Marinate salmon with herbs and garlic', 'Preheat grill to medium-high', 'Grill 4-5 minutes per side', 'Squeeze fresh lemon before serving'],
      benefits: 'Rich in omega-3 fatty acids, supports heart and brain health.',
    ),
    Recipe(
      name: 'Roasted Root Vegetables',
      season: 'Winter',
      emoji: '🥕',
      ingredients: ['2 carrots', '1 parsnip', '1 sweet potato', '2 tbsp olive oil', 'Rosemary and thyme', 'Sea salt and pepper'],
      steps: ['Preheat oven to 400°F / 200°C', 'Chop vegetables into even pieces', 'Toss with oil and herbs', 'Roast 30-35 minutes until caramelized'],
      benefits: 'Warming, nutrient-dense, and naturally sweet — ideal winter comfort food.',
    ),
    Recipe(
      name: 'Avocado Toast with Egg',
      season: 'Spring',
      emoji: '🥑',
      ingredients: ['1 slice whole grain bread', '1/2 avocado', '1 poached egg', 'Red pepper flakes', 'Microgreens', 'Squeeze of lemon'],
      steps: ['Toast bread until golden', 'Mash avocado with lemon', 'Spread on toast', 'Top with poached egg and microgreens'],
      benefits: 'Balanced breakfast with healthy fats, protein, and fiber.',
    ),
    Recipe(
      name: 'Herbal Detox Water',
      season: 'Summer',
      emoji: '🍋',
      ingredients: ['1 lemon sliced', 'Fresh mint leaves', '1 cucumber sliced', '1 liter filtered water', 'Ice cubes'],
      steps: ['Add all ingredients to a pitcher', 'Fill with filtered water', 'Refrigerate for 2 hours', 'Serve over ice'],
      benefits: 'Hydrating, cleansing, and refreshing — supports natural detoxification.',
    ),
    Recipe(
      name: 'Warm Apple Cinnamon Porridge',
      season: 'Autumn',
      emoji: '🍎',
      ingredients: ['1/2 cup steel-cut oats', '1 apple diced', '1 tsp cinnamon', '1 cup milk', '1 tbsp maple syrup', 'Walnuts'],
      steps: ['Cook oats in milk according to package', 'Stir in diced apple and cinnamon', 'Top with walnuts and maple syrup', 'Serve warm'],
      benefits: 'Comforting, heart-healthy, and rich in soluble fiber.',
    ),
    Recipe(
      name: 'Chicken Ginger Bone Broth',
      season: 'Winter',
      emoji: '🍲',
      ingredients: ['Chicken bones', '2-inch fresh ginger', '3 cloves garlic', '1 onion', 'Bay leaves', 'Filtered water'],
      steps: ['Place bones in a large pot', 'Add ginger, garlic, onion, and bay leaves', 'Cover with water and bring to boil', 'Simmer on low for 8-12 hours', 'Strain and season to taste'],
      benefits: 'Deeply nourishing, supports gut health and immune function.',
    ),
  ];

  static const herbalTeas = [
    HerbalTea(
      name: 'Chamomile',
      emoji: '🌼',
      subtitle: 'Calm your mind before sleep',
      benefits: ['Reduces anxiety', 'Promotes sleep', 'Soothes digestion', 'Anti-inflammatory'],
      brewing: 'Steep 1–2 tsp dried flowers in 200ml boiling water for 5 minutes.',
    ),
    HerbalTea(
      name: 'Peppermint',
      emoji: '🌿',
      subtitle: 'Refresh and invigorate',
      benefits: ['Aids digestion', 'Relieves headaches', 'Boosts focus', 'Reduces bloating'],
      brewing: 'Steep 1 tbsp fresh or dried leaves in 200ml boiling water for 5–7 minutes.',
    ),
    HerbalTea(
      name: 'Ginger',
      emoji: '🫚',
      subtitle: 'Warm and energize your body',
      benefits: ['Fights nausea', 'Boosts immunity', 'Reduces inflammation', 'Aids circulation'],
      brewing: 'Simmer 1 tbsp sliced fresh ginger in 200ml water for 10 minutes. Add honey to taste.',
    ),
    HerbalTea(
      name: 'Lavender',
      emoji: '💜',
      subtitle: 'Unwind after a long day',
      benefits: ['Calms nervous system', 'Improves sleep quality', 'Reduces stress', 'Eases tension'],
      brewing: 'Steep 1–2 tsp dried lavender buds in 200ml boiling water for 5 minutes.',
    ),
    HerbalTea(
      name: 'Echinacea',
      emoji: '🌺',
      subtitle: 'Strengthen your immune defense',
      benefits: ['Boosts immunity', 'Shortens colds', 'Anti-inflammatory', 'Rich in antioxidants'],
      brewing: 'Steep 1–2 tsp dried echinacea in 200ml boiling water for 10–15 minutes.',
    ),
    HerbalTea(
      name: 'Lemon Balm',
      emoji: '🍋',
      subtitle: 'Lift your mood naturally',
      benefits: ['Reduces anxiety', 'Improves mood', 'Aids sleep', 'Supports cognition'],
      brewing: 'Steep 1–2 tsp dried leaves in 200ml boiling water for 5–7 minutes.',
    ),
  ];

  static const movements = [
    MovementItem(
      name: 'Morning Sun Salutation',
      emoji: '🌅',
      subtitle: 'Energize your day with flowing yoga',
      duration: '10 min',
      steps: ['Stand tall, arms overhead', 'Fold forward, relax your head', 'Step back to plank', 'Lower into cobra', 'Press back to downward dog', 'Step forward, rise up'],
    ),
    MovementItem(
      name: 'Tai Chi Flow',
      emoji: '🧘',
      subtitle: 'Slow, meditative movement for balance',
      duration: '15 min',
      steps: ['Stand with feet shoulder-width apart', 'Raise arms slowly, breathing in', 'Shift weight side to side', 'Circle arms in wave motion', 'Step and turn gracefully', 'Close: press palms together at heart'],
    ),
    MovementItem(
      name: 'Evening Stretch Routine',
      emoji: '🌙',
      subtitle: 'Release tension before bed',
      duration: '8 min',
      steps: ['Neck rolls — 5 each direction', 'Shoulder shrugs — 10 reps', 'Cat-cow stretch — 8 rounds', 'Child\'s pose — hold 30 seconds', 'Seated forward fold — hold 30 seconds', 'Legs up the wall — 2 minutes'],
    ),
    MovementItem(
      name: 'Walking Meditation',
      emoji: '🚶',
      subtitle: 'Mindful movement for clarity',
      duration: '20 min',
      steps: ['Find a quiet path', 'Walk slowly, notice each step', 'Breathe in for 4 steps, out for 6', 'Feel the ground beneath your feet', 'Observe nature without judgment', 'End with 1 minute of stillness'],
    ),
    MovementItem(
      name: 'Desk Release',
      emoji: '💺',
      subtitle: 'Quick relief from sitting all day',
      duration: '5 min',
      steps: ['Seated spinal twist — each side', 'Wrist circles — 10 each direction', 'Chest opener: clasp hands behind back', 'Figure-4 stretch for hips', 'Stand and reach for the sky', 'Shake it out — arms and legs'],
    ),
  ];

  static const sleepSounds = [
    SleepSound(name: 'Gentle Rain', emoji: '🌧️', subtitle: 'Soft rainfall on a forest canopy', duration: '45 min'),
    SleepSound(name: 'Ocean Waves', emoji: '🌊', subtitle: 'Rolling waves on a sandy shore', duration: '60 min'),
    SleepSound(name: 'Forest Night', emoji: '🌲', subtitle: 'Crickets and rustling leaves', duration: '45 min'),
    SleepSound(name: 'White Noise', emoji: '☁️', subtitle: 'Consistent sound mask for focus', duration: '120 min'),
    SleepSound(name: 'Singing Bowls', emoji: '🔔', subtitle: 'Tibetan bowl resonance for deep rest', duration: '30 min'),
    SleepSound(name: 'Thunderstorm', emoji: '⛈️', subtitle: 'Distant rumble with steady rain', duration: '60 min'),
  ];

  static const pressurePoints = [
    PressurePoint(
      name: 'Third Eye Point (Yintang)',
      location: 'Between the eyebrows, at the glabella',
      technique: 'Apply gentle pressure with index and middle fingers in a circular motion',
      duration: '2-3 minutes',
      benefits: ['Relieves headache', 'Reduces eye strain', 'Calms the mind', 'Improves focus'],
      caution: 'Do not press too hard. Stop if you feel dizzy.',
    ),
    PressurePoint(
      name: 'Shoulder Well (Jianjing)',
      location: 'On the top of the shoulder, midway between the base of the neck and the shoulder tip',
      technique: 'Pinch firmly with thumb and index finger',
      duration: '1-2 minutes per side',
      benefits: ['Relieves shoulder tension', 'Reduces stress', 'Eases neck pain'],
      caution: 'Avoid during pregnancy.',
    ),
    PressurePoint(
      name: 'Union Valley (Hegu)',
      location: 'In the web between the thumb and index finger',
      technique: 'Pinch firmly with the opposite thumb and index finger',
      duration: '2-3 minutes per hand',
      benefits: ['Relieves headache and toothache', 'Reduces stress', 'Boosts immunity'],
      caution: 'Avoid during pregnancy — may stimulate contractions.',
    ),
    PressurePoint(
      name: 'Inner Gate (Neiguan)',
      location: 'On the inner forearm, about 3 finger-widths below the wrist crease',
      technique: 'Press with the thumb, applying moderate pressure',
      duration: '2-3 minutes per wrist',
      benefits: ['Relieves nausea', 'Reduces anxiety', 'Helps with insomnia'],
      caution: 'Apply gentle pressure; stop if numbness occurs.',
    ),
    PressurePoint(
      name: 'Sea of Tranquility (Shenzhu)',
      location: 'On the sternum (breastbone), at the level of the nipples, midline',
      technique: 'Press gently with the middle finger while breathing deeply',
      duration: '2-3 minutes',
      benefits: ['Calms emotional distress', 'Relieves chest tightness', 'Reduces anxiety'],
      caution: 'Do not press forcefully on the chest area.',
    ),
    PressurePoint(
      name: 'Bubbling Spring (Yongquan)',
      location: 'On the sole of the foot, in the depression near the ball of the foot',
      technique: 'Press firmly with the thumb in an upward motion',
      duration: '2-3 minutes per foot',
      benefits: ['Grounds and calms the mind', 'Improves sleep quality', 'Reduces fatigue'],
      caution: 'Best performed before bedtime for maximum benefit.',
    ),
    PressurePoint(
      name: 'Wind Pool (Fengchi)',
      location: 'At the base of the skull, in the hollows on either side of the neck muscles',
      technique: 'Apply gentle pressure with both thumbs, tilting head slightly forward',
      duration: '2-3 minutes',
      benefits: ['Relieves neck stiffness', 'Reduces headache', 'Clears mental fog'],
      caution: 'Move slowly and stop if you feel sharp pain.',
    ),
  ];
}
