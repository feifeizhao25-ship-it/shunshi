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
  ConstitutionType(key: 'qixu', name: 'Qi Deficient', emoji: '😰', description: 'Weak Qi, prone to fatigue and shortness of breath'),
  ConstitutionType(key: 'yangxu', name: 'Yang Deficient', emoji: '🥶', description: 'Weak Yang, fear of cold and chills'),
  ConstitutionType(key: 'yinxu', name: 'Yin Deficient', emoji: '🔥', description: 'Yin deficiency, dry mouth and throat'),
  ConstitutionType(key: 'tanshi', name: 'Phlegm-Damp', emoji: '😪', description: 'Phlegm-damp accumulation, overweight'),
  ConstitutionType(key: 'shire', name: 'Damp-Heat', emoji: '🤢', description: 'Damp-heat accumulation, oily skin'),
  ConstitutionType(key: 'xueyu', name: 'Blood Stasis', emoji: '😣', description: 'Poor blood circulation, dull complexion'),
  ConstitutionType(key: 'qiyu', name: 'Qi Stagnant', emoji: '😔', description: 'Qi stagnation, prone to sadness'),
  ConstitutionType(key: 'tebing', name: 'Special', emoji: '🤧', description: 'Allergic/constitutional sensitivity'),
  ConstitutionType(key: 'pinghe', name: 'Balanced', emoji: '😊', description: 'Harmonious Yin-Yang, well-proportioned'),
];

const Map<String, String> kConstitutionEmoji = {
  'pinghe': '😊', 'qixu': '😰', 'yangxu': '🥶', 'yinxu': '🔥',
  'tanshi': '😪', 'shire': '🤢', 'xueyu': '😣', 'qiyu': '😔', 'tebing': '🤧',
};

const Map<String, String> kConstitutionDesc = {
  'pinghe': 'Harmonious Yin-Yang and Qi-Blood, well-proportioned body, radiant complexion, energetic, good sleep',
  'qixu': 'Weak Qi, prone to fatigue, shortness of breath, reluctance to speak, easily sweats, catches colds easily',
  'yangxu': 'Weak Yang, cold hands and feet, fear of cold and chills, low energy',
  'yinxu': 'Yin deficiency, dry mouth and throat, hot palms and soles, night sweats',
  'tanshi': 'Phlegm-damp accumulation, overweight, loose abdominal fat, sticky mouth',
  'shire': 'Damp-heat accumulation, oily face, bitter dry mouth, heavy sluggish body',
  'xueyu': 'Poor blood circulation, dull complexion, prone to bruising',
  'qiyu': 'Qi stagnation, sadness, worry, fragility',
  'tebing': 'Congenital deficiency or allergic constitution, prone to allergies',
};

const Map<String, List<String>> kConstitutionChars = {
  'pinghe': ['Well-proportioned strong body', 'Radiant ruddy complexion', 'Energetic', 'Good sleep', 'Normal appetite', 'Regular digestion'],
  'qixu': ['Prone to fatigue', 'Shortness of breath, reluctance to speak', 'Easily sweats', 'Catches colds easily', 'Weak voice', 'Pale red tongue, swollen body'],
  'yangxu': ['Cold hands and feet', 'Fear of cold', 'Low energy', 'Fair pale complexion', 'Prefers warm food', 'Pale swollen tender tongue'],
  'yinxu': ['Dry mouth and throat', 'Hot palms and soles', 'Slightly dry nose', 'Prefers cold drinks', 'Dry stool', 'Flushed complexion'],
  'tanshi': ['Overweight', 'Oily face', 'Heavy sticky sweat', 'Sticky mouth', 'Heavy sluggish feeling', 'Craves rich fatty food'],
  'shire': ['Oily shiny face', 'Prone to acne', 'Bitter dry mouth', 'Heavy sluggish body', 'Sticky loose stool', 'Dark yellow urine'],
  'xueyu': ['Dull complexion', 'Pigmentation', 'Prone to bruising', 'Dark lips', 'Dark eye circles', 'Dark tongue with spots'],
  'qiyu': ['Sad expression', 'Fragile emotions', 'Melancholy', 'Sentimental', 'Chest and rib distension', 'Frequent sighing'],
  'tebing': ['Allergic constitution', 'Prone to asthma', 'Sneezes easily', 'Nasal congestion and runny nose', 'Prone to hives'],
};

const Map<String, Map<String, String>> kConstitutionAdvice = {
  'pinghe': {'Diet': 'Eat in moderation, avoid extremes, balance whole grains and refined foods, mix meat and vegetables', 'Tea': 'Drink green tea, chrysanthemum tea or other mild teas in all seasons', 'Exercise': 'Moderate exercise—walking, Tai Chi, swimming are all suitable'},
  'qixu': {'Diet': 'Eat Qi-boosting and spleen-strengthening foods: astragalus, ginseng, yam, jujube, millet, glutinous rice, hyacinth bean', 'Tea': 'Astragalus jujube tea, ginseng tea, codonopsis tea', 'Exercise': 'Gentle exercises: walking, Tai Chi, Baduanjin; avoid intense workouts'},
  'yangxu': {'Diet': 'Eat Yang-warming foods: lamb, ginger, longan, leek, walnuts, chestnuts, jujube', 'Tea': 'Ginger jujube tea, longan black tea, cinnamon tea', 'Exercise': 'Get plenty of sunlight, outdoor activities, Tai Chi, moxibustion at Zusanli'},
  'yinxu': {'Diet': 'Eat Yin-nourishing foods that also moisten dryness: tremella, lily bulb, pear, goji berry, black sesame, duck, turtle', 'Tea': 'Lily bulb tremella tea, goji chrysanthemum tea, ophiopogon tea', 'Exercise': 'Light to moderate exercise: swimming, yoga, jogging; avoid heavy sweating'},
  'tanshi': {'Diet': 'Reduce rich fatty foods, eat more spleen-strengthening dampness-eliminating foods: coix seed, adzuki bean, winter melon, lotus leaf, tangerine peel', 'Tea': 'Lotus leaf tea, coix seed red bean tea, tangerine peel tea, hawthorn tea', 'Exercise': 'Increase aerobic exercise—brisk walking, jogging, swimming, control weight'},
  'shire': {'Diet': 'Eat heat-clearing dampness-eliminating foods: mung bean, bitter melon, winter melon, cucumber, coix seed, lotus root', 'Tea': 'Honeysuckle tea, chrysanthemum tea, lotus leaf tea, mung bean soup', 'Exercise': 'Moderate aerobic exercise, swimming is best; suitable for outdoor summer activities'},
  'xueyu': {'Diet': 'Eat blood-circulation-promoting foods: hawthorn, safflower, rose, black bean, vinegar, black fungus', 'Tea': 'Rose tea, hawthorn tea, safflower tea, notoginseng tea', 'Exercise': 'Appropriate exercise to promote Qi-Blood circulation: Tai Chi, yoga, dancing — any activity that moves the body freely'},
  'qiyu': {'Diet': 'Eat liver-soothing Qi-regulating foods: rose, bergamot, citrus, radish, buckwheat, enoki mushroom', 'Tea': 'Rose tea, jasmine tea, bergamot tea, mimosa tea', 'Exercise': 'More outdoor activities and social engagement: running, hiking, singing, dancing'},
  'tebing': {'Diet': 'Light diet, avoid allergens. Eat Qi-boosting exterior-strengthening foods: astragalus, jujube, yam, reishi mushroom', 'Tea': 'Astragalus jujube tea, reishi tea, saposhnikovia tea', 'Exercise': 'Moderate exercise to strengthen constitution: swimming, walking, Tai Chi'},
};

/// 12-question body type quiz (TCM 9-constitution simplified)
/// Each question targets 1-2 constitution types.
/// Scoring: Yes(3) | Sometimes(2) | No(1)
const List<Question> kBodyTypeQuestions = [
  Question(id: 1, text: 'Do you often feel tired or lack energy?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 2, text: 'Do you often feel cold, especially hands and feet?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 3, text: 'Do you have a dry mouth or throat, even after drinking water?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 4, text: 'Is your body type on the heavier side, with a tendency to feel sluggish?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 5, text: 'Do you often have oily skin or a bitter taste in your mouth?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 6, text: 'Do you bruise easily or have dark spots/pigmentation on your face?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 7, text: 'Do you often feel sad, worried, or emotionally fragile?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 8, text: 'Do you suffer from allergies, sneezing, or skin sensitivities?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 9, text: 'Do you have trouble falling asleep or often wake up during the night?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 10, text: 'Do you catch colds easily or take longer than others to recover?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 11, text: 'Do you often experience bloating, indigestion, or poor appetite?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
  Question(id: 12, text: 'Is your complexion generally radiant and do you feel energetic most days?', options: [
    QuestionOption(score: 3, text: 'Yes'),
    QuestionOption(score: 2, text: 'Sometimes'),
    QuestionOption(score: 1, text: 'No'),
  ]),
];

/// Question → constitution type mapping for scoring
/// Q1→qixu, Q2→yangxu, Q3→yinxu, Q4→tanshi, Q5→shire, Q6→xueyu,
/// Q7→qiyu, Q8→tebing, Q9→yinxu, Q10→qixu, Q11→qixu, Q12→pinghe
const Map<int, String> kQuestionTypeMap = {
  1: 'qixu', 2: 'yangxu', 3: 'yinxu', 4: 'tanshi', 5: 'shire', 6: 'xueyu',
  7: 'qiyu', 8: 'tebing', 9: 'yinxu', 10: 'qixu', 11: 'qixu', 12: 'pinghe',
};

const Map<String, List<String>> kConstitutionAvoid = {
  'pinghe': [], 'qixu': ['Overwork', 'Heavy sweating', 'Raw cold food', 'Staying up late', 'Intense exercise'],
  'yangxu': ['Raw cold food', 'Cold environments', 'Excessive AC', 'Iced drinks', 'Cold-natured fruits'],
  'yinxu': ['Spicy food', 'Fried foods', 'Staying up late', 'Over-exercise', 'Warm-natured foods like lamb'],
  'tanshi': ['Rich fatty foods', 'Sweet foods', 'Alcohol', 'Sedentary lifestyle', 'Raw cold food'],
  'shire': ['Spicy food', 'Oily foods', 'Alcohol', 'Fried foods', 'Staying up late'],
  'xueyu': ['Sedentary lifestyle', 'Cold environments', 'Emotional suppression', 'Excessive idleness'],
  'qiyu': ['Chronic emotional suppression', 'Over-thinking', 'Sedentary lifestyle', 'Social isolation'],
  'tebing': ['Known food allergens', 'Pollen environments', 'Cold air', 'Newly renovated environments', 'Pet dander'],
};
