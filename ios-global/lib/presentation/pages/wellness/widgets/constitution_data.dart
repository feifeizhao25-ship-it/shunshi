// Constitution data models and constants

class ConstitutionType {
  final String key;
  final String name;
  final String emoji;
  final String description;
  const ConstitutionType({required this.key, required this.name, required this.emoji, required this.description});
}

class QuestionOption {
  final int score;
  final String text;
  const QuestionOption({required this.score, required this.text});
}

class Question {
  final int id;
  final String text;
  final List<QuestionOption> options;
  const Question({required this.id, required this.text, required this.options});
}

class HealthAdvice {
  final String category;
  final String icon;
  final List<String> items;
  const HealthAdvice({required this.category, this.icon = '', required this.items});
}

class ConstitutionResult {
  final String resultId;
  final String typeKey;
  final String typeName;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final List<Map<String, dynamic>> scores;
  final String avoidList;
  final bool isPremium;
  const ConstitutionResult({
    required this.resultId, required this.typeKey, required this.typeName,
    required this.emoji, required this.description, required this.characteristics,
    required this.advice, required this.scores, this.avoidList = '', this.isPremium = false,
  });
}

class ConstitutionDetail {
  final String name;
  final String emoji;
  final String description;
  final List<String> characteristics;
  final List<HealthAdvice> advice;
  final String avoidList;
  const ConstitutionDetail({required this.name, required this.emoji, required this.description, required this.characteristics, required this.advice, required this.avoidList});
}

const List<ConstitutionType> kConstitutionTypes = [
  ConstitutionType(key: 'qixu', name: 'Qi Deficiency', emoji: '😰', description: 'Low vital energy, easily tired and short of breath'),
  ConstitutionType(key: 'yangxu', name: 'Yang Deficiency', emoji: '🥶', description: 'Insufficient yang, cold-prone'),
  ConstitutionType(key: 'yinxu', name: 'Yin Deficiency', emoji: '🔥', description: 'Low yin fluids, dry mouth and throat'),
  ConstitutionType(key: 'tanshi', name: 'Phlegm-Dampness', emoji: '😪', description: 'Phlegm and dampness gather, heavier build'),
  ConstitutionType(key: 'shire', name: 'Damp-Heat', emoji: '🤢', description: 'Damp-heat inside, oily face'),
  ConstitutionType(key: 'xueyu', name: 'Blood Stasis', emoji: '😣', description: 'Blood flows poorly, dull complexion'),
  ConstitutionType(key: 'qiyu', name: 'Qi Stagnation', emoji: '😔', description: 'Qi flow stuck, low mood'),
  ConstitutionType(key: 'tebing', name: 'Special Constitution', emoji: '🤧', description: 'Inherited irregularity, allergy-prone'),
  ConstitutionType(key: 'pinghe', name: 'Balanced', emoji: '😊', description: 'Yin and yang in harmony, moderate build'),
];

const Map<String, String> kConstitutionEmoji = {
  'pinghe': '😊', 'qixu': '😰', 'yangxu': '🥶', 'yinxu': '🔥',
  'tanshi': '😪', 'shire': '🤢', 'xueyu': '😣', 'qiyu': '😔', 'tebing': '🤧',
};

const Map<String, String> kConstitutionDesc = {
  'pinghe': 'Yin and yang, qi and blood in harmony; moderate build, glowing complexion, plenty of energy, good sleep',
  'qixu': 'Low vital energy, easily tired, short of breath and reluctant to talk, sweats easily, catches colds easily',
  'yangxu': 'Insufficient yang, cold hands and feet, dislikes cold, low spirits',
  'yinxu': 'Low yin fluids in the body, dry mouth and throat, warm palms and soles, night sweats',
  'tanshi': 'Phlegm and dampness gather, heavier build, soft full abdomen, sticky mouth',
  'shire': 'Damp-heat inside, oily face, bitter dry mouth, heavy and sleepy',
  'xueyu': 'Blood flows poorly, dull complexion, bruises easily',
  'qiyu': 'Qi flow stuck, low mood, anxious and fragile',
  'tebing': 'Inherited weakness or allergic constitution, allergy-prone',
};

const Map<String, List<String>> kConstitutionChars = {
  'pinghe': ['Well-proportioned and strong', 'Rosy, glowing complexion', 'Plenty of energy', 'Sleeps well', 'Normal appetite', 'Regular bowel and bladder'],
  'qixu': ['Easily tired', 'Short of breath, reluctant to talk', 'Sweats easily', 'Catches colds easily', 'Weak voice', 'Pale red, swollen tongue'],
  'yangxu': ['Cold hands and feet', 'Dislikes cold', 'Low spirits', 'Soft, pale complexion', 'Prefers warm food and drink', 'Pale, tender, swollen tongue'],
  'yinxu': ['Dry mouth and throat', 'Warm palms and soles', 'Slightly dry nose', 'Prefers cold drinks', 'Dry stools', 'Flushed face'],
  'tanshi': ['Heavier build', 'Oily face', 'Sweats a lot, sticky', 'Sticky mouth', 'Body feels heavy', 'Fond of rich, fatty food'],
  'shire': ['Oily face', 'Prone to acne', 'Bitter, dry mouth', 'Heavy and sleepy', 'Sticky, sluggish stools', 'Scanty, dark urine'],
  'xueyu': ['Dull complexion', 'Pigmentation', 'Bruises easily', 'Dull lips', 'Dark circles', 'Dark tongue with spots'],
  'qiyu': ['Low mood', 'Emotionally fragile', 'Restless and unhappy', 'Sentimental', 'Fullness in the chest and ribs', 'Frequent sighing'],
  'tebing': ['Allergic constitution', 'Prone to asthma', 'Sneezes easily', 'Stuffy, runny nose', 'Skin prone to hives'],
};

const Map<String, Map<String, String>> kConstitutionAdvice = {
  'pinghe': {'Diet': 'Eat in moderation, no picky eating, mix coarse and fine grains, balance meat and vegetables', 'Tea': 'Mild teas such as green tea or chrysanthemum tea are fine in all seasons', 'Exercise': 'Moderate exercise — walking, tai chi or swimming'},
  'qixu': {'Diet': 'Eat more qi-tonifying, spleen-supporting foods: astragalus, ginseng, Chinese yam, red dates, millet, glutinous rice, hyacinth bean', 'Tea': 'Astragalus and red date tea, ginseng tea, codonopsis tea', 'Exercise': 'Favour gentle exercise: walking, tai chi, Baduanjin; avoid strenuous exercise'},
  'yangxu': {'Diet': 'Eat more warming foods: lamb, ginger, longan, chives, walnuts, chestnuts, red dates', 'Tea': 'Ginger-date tea, longan black tea, cinnamon tea', 'Exercise': 'Get more sun; outdoor exercise, tai chi, moxibustion at Zusanli suit you'},
  'yinxu': {'Diet': 'Eat more yin-nourishing, moistening foods: tremella, lily bulb, pear, goji, black sesame, duck, soft-shelled turtle', 'Tea': 'Lily bulb and tremella tea, goji and chrysanthemum tea, ophiopogon tea', 'Exercise': 'Light to moderate exercise — swimming, yoga, jogging; avoid heavy sweating'},
  'tanshi': {'Diet': 'Eat less rich, fatty food; eat more spleen-supporting, dampness-draining foods: coix seed, adzuki bean, winter melon, lotus leaf, tangerine peel', 'Tea': 'Lotus leaf tea, coix and adzuki tea, tangerine peel tea, hawthorn tea', 'Exercise': 'Do more aerobic exercise — brisk walking, jogging, swimming; manage weight'},
  'shire': {'Diet': 'Eat more heat-clearing, dampness-draining foods: mung bean, bitter melon, winter melon, cucumber, coix seed, lotus root', 'Tea': 'Honeysuckle tea, chrysanthemum tea, lotus leaf tea, mung bean soup', 'Exercise': 'Moderate aerobic exercise, swimming is best; good for summer outdoor activity'},
  'xueyu': {'Diet': 'Eat more blood-moving foods: hawthorn, safflower, rose, black beans, vinegar, wood ear', 'Tea': 'Rose tea, hawthorn tea, safflower tea, notoginseng tea', 'Exercise': 'Moderate exercise to keep qi and blood moving — tai chi, yoga, dance'},
  'qiyu': {'Diet': 'Eat more liver-soothing, qi-regulating foods: rose, finger citron, citrus, radish, buckwheat, enoki', 'Tea': 'Rose tea, jasmine tea, finger citron tea, silk-tree flower tea', 'Exercise': 'Take part in outdoor exercise and social activities — running, hiking, singing, dancing'},
  'tebing': {'Diet': 'Eat light food and avoid allergens. Eat more qi-securing foods: astragalus, red dates, Chinese yam, reishi', 'Tea': 'Astragalus and red date tea, reishi tea, saposhnikovia tea', 'Exercise': 'Moderate exercise to build resistance — swimming, walking, tai chi'},
};

const Map<String, List<String>> kConstitutionAvoid = {
  'pinghe': [], 'qixu': ['Overwork', 'Heavy sweating', 'Raw, cold food', 'Staying up late', 'Strenuous exercise'],
  'yangxu': ['Raw, cold food', 'Cold environments', 'Too much air conditioning', 'Iced drinks', 'Cold-natured fruits'],
  'yinxu': ['Spicy food', 'Fried food', 'Staying up late', 'Overexercise', 'Warming foods such as lamb'],
  'tanshi': ['Rich, fatty food', 'Sweets', 'Alcohol', 'Sitting for long periods', 'Raw, cold food'],
  'shire': ['Spicy food', 'Greasy food', 'Alcohol', 'Fried food', 'Staying up late'],
  'xueyu': ['Sitting for long periods', 'Cold environments', 'Suppressed emotions', 'Too much idleness'],
  'qiyu': ['Long-term suppressed emotions', 'Overthinking', 'Sitting for long periods', 'Being alone and silent'],
  'tebing': ['Known food allergens', 'Pollen', 'Cold air', 'Newly renovated spaces', 'Pet hair'],
};
