import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../widgets/paywall_banner.dart';
import '../../../core/theme/app_localizations.dart';

/// Mindful Breathing Guide Data
final List<Map<String, String>> _breathingSteps = [
  {'title': 'Adjust Posture', 'desc': 'Find a comfortable sitting or lying position, gently close your eyes'},
  {'title': 'Natural Breathing', 'desc': 'Don\'t force it, just feel the natural rhythm of your breath'},
  {'title': 'Inhale 4 Seconds', 'desc': 'Slowly inhale through your nose, feel your abdomen gently rise'},
  {'title': 'Hold 4 Seconds', 'desc': 'Gently hold your breath, feel the stillness of your body'},
  {'title': 'Exhale 6 Seconds', 'desc': 'Slowly exhale through your mouth, feel your body relax'},
  {'title': 'Stay Aware', 'desc': 'Repeat the breathing cycle, maintaining awareness of each breath'},
];

/// Mood Support Page
class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  String? _selectedMood;

  final Map<String, Map<String, dynamic>> _moodResponses = {
    'happy': {
      'icon': '😊',
      'color': Colors.amber,
      'title': 'Keep Smiling',
      'description': 'Happiness is the best state for body and mind. TCM believes "joy harmonizes Qi" — moderate delight promotes smooth Qi and blood flow.',
      'tips': [
        {'title': 'Share Joy', 'desc': 'Share your happiness with those around you. TCM says "joy eases Qi" — sharing makes joy last longer and strengthens relationships'},
        {'title': 'Record Moments', 'desc': 'Capture beautiful moments with words or photos. Positive reinforcement helps cultivate a grateful mindset'},
        {'title': 'Light Exercise', 'desc': 'Take advantage of your good mood with a walk or yoga. Let happiness and vitality reinforce each other'},
        {'title': 'Savor the Present', 'desc': 'Mindfully enjoy this moment without judgment. Fully feel the joy flowing through your body'},
      ],
    },
    'sad': {
      'icon': '😢',
      'color': Colors.blue,
      'title': 'I\'m Here for You',
      'description': 'TCM says "grief consumes Qi" — excessive sadness depletes vitality. Allow yourself to feel, but also take care to regulate and not let sadness linger too long.',
      'tips': [
        {'title': 'Allow Feelings', 'desc': 'Don\'t suppress sadness. Give yourself 10-15 minutes to quietly feel your emotions. TCM believes emotions need appropriate expression'},
        {'title': 'Acupressure: Taichong', 'desc': 'Press the Taichong point (between big toe and second toe on top of foot) for 3-5 minutes. It soothes the Liver and relieves stagnation'},
        {'title': 'Outdoor Walk', 'desc': 'Step outside and connect with nature. TCM believes "humans resonate with heaven and earth" — natural environments help regulate Qi'},
        {'title': 'Warm Drinks', 'desc': 'Have a warm cup of longan and jujube tea. Sweet flavors nourish the Spleen and ease sorrow. Avoid cold, raw foods'},
        {'title': 'Express Yourself', 'desc': 'Call someone you trust or write in a journal. Suppressed emotions block Qi flow — healthy expression supports wellbeing'},
      ],
    },
    'anxious': {
      'icon': '😰',
      'color': Colors.orange,
      'title': 'Relax, Everything Will Be Okay',
      'description': 'TCM links anxiety to restless Heart Spirit and Liver Qi stagnation. "Overthinking knots Qi." Relaxing body and mind is the first step to easing anxiety.',
      'tips': [
        {'title': '4-7-8 Breathing', 'desc': 'Inhale 4 seconds, hold 7 seconds, exhale 8 seconds. This activates the parasympathetic nervous system, slowing heart rate and lowering blood pressure'},
        {'title': 'Acupressure: Neiguan', 'desc': 'Press the Neiguan point (three finger-widths above wrist crease between tendons) with thumb for 3-5 minutes. It calms the mind and opens the chest'},
        {'title': 'Write It Down', 'desc': 'List your worries on paper, then assess which ones you can control. Externalizing thoughts helps untangle mental knots'},
        {'title': 'Warming Tea', 'desc': 'Brew Pinellia 10g, Bamboo Shavings 10g, Aged Tangerine Peel 6g as tea. It warms the Gallbladder and harmonizes the Stomach, great for anxiety-related insomnia'},
        {'title': 'Mindful Meditation', 'desc': 'Sit quietly for 5-10 minutes, focusing on your breath or body sensations. Let go of anxious thoughts as they arise'},
      ],
    },
    'angry': {
      'icon': '😤',
      'color': Colors.red,
      'title': 'Take a Moment to Cool Down',
      'description': 'TCM says "anger drives Qi upward" — rage sends Liver Qi surging up, causing headaches, flushed face, or even fainting. Managing anger is key to protecting your health.',
      'tips': [
        {'title': 'Step Away', 'desc': 'Temporarily leave the situation making you angry. Physical distance helps Qi settle and calm down'},
        {'title': 'Acupressure: Taichong', 'desc': 'Press firmly in the depression between big toe and second toe for 3-5 minutes. It pacifies Liver Yang and subdues rising Qi'},
        {'title': 'Deep Breaths x10', 'desc': 'Breathe slowly and deeply. With each exhale, imagine anger leaving your body. Deep breathing directly regulates the autonomic nervous system'},
        {'title': 'Exercise It Out', 'desc': 'Do aerobic exercise (brisk walking, jogging) to transform anger into physical energy. Exercise burns stress hormones generated by rage'},
        {'title': 'Chrysanthemum Tea', 'desc': 'Brew 5 chrysanthemum flowers and 10g cassia seeds as tea. It clears Liver heat, brightens eyes, and reduces fire — perfect for lingering anger'},
      ],
    },
    'tired': {
      'icon': '😴',
      'color': Colors.purple,
      'title': 'Take a Good Rest',
      'description': 'Fatigue is your body signaling for help. TCM attributes tiredness to Qi-blood deficiency or Spleen weakness with dampness. Proper rest and nourishment restore vitality.',
      'tips': [
        {'title': 'Brief Nap', 'desc': 'Rest 15-20 minutes during Wu hour (11am-1pm). TCM considers this the Heart meridian peak — rest now best nourishes Heart Spirit'},
        {'title': 'Acupressure: Zusanli', 'desc': 'Press below the kneecap, four finger-widths down on the outer side for 5-10 minutes. Zusanli is the "longevity point" that tonifies Qi and blood'},
        {'title': 'Goji & Astragalus Tea', 'desc': 'Brew Astragalus 10g and Goji berries 10g as tea. It tonifies Qi and nourishes blood — ideal for fatigue and low energy'},
        {'title': 'Gentle Stretching', 'desc': 'Do 5-10 minutes of simple stretches for neck, shoulders, and back. It promotes Qi-blood circulation and relieves muscle tension'},
        {'title': 'Nourishing Diet', 'desc': 'Eat Qi-boosting foods (jujube, yam, millet porridge), reduce cold and greasy foods. The Spleen is the foundation of postnatal health'},
      ],
    },
    'lonely': {
      'icon': '😔',
      'color': Colors.teal,
      'title': 'You Are Not Alone',
      'description': 'TCM links loneliness to Heart Qi deficiency and Liver Qi stagnation. "Sorrow and worry agitate the Heart, and when the Heart is agitated, all organs are shaken." Social connection and self-care can help.',
      'tips': [
        {'title': 'Reach Out', 'desc': 'Send a message or call a friend you haven\'t spoken to in a while. Social interaction promotes Qi flow and lifts your mood'},
        {'title': 'Rose Petal Tea', 'desc': 'Brew 5 rose petals and 3g aged tangerine peel as tea. It soothes the Liver, regulates Qi, and the aroma lifts the spirits'},
        {'title': 'Join Activities', 'desc': 'Join interest groups or volunteer. Social engagement promotes Qi circulation and reduces Liver Qi stagnation'},
        {'title': 'Grow a Plant', 'desc': 'Caring for plants provides companionship and a sense of achievement. TCM emphasizes harmony with nature to soothe emotions'},
        {'title': 'Gratitude Journal', 'desc': 'Write 3 things you\'re grateful for each day. Focusing on what you have reduces the feeling of isolation'},
      ],
    },
    'stressed': {
      'icon': '😫',
      'color': Colors.deepOrange,
      'title': 'Learn to Release Pressure',
      'description': 'TCM believes excessive stress causes Liver Qi stagnation and Heart-Spleen deficiency. Chronic stress is the root of many illnesses — learning to manage it is essential.',
      'tips': [
        {'title': 'Ear Acupressure', 'desc': 'Rub both ears until warm, then press the earlobe center, ear tip, and Shenmen point for 30 seconds each. The ear contains points for the entire body'},
        {'title': 'Baduanjin Practice', 'desc': 'Do a 15-minute Baduanjin routine, especially "Two Hands Hold Up the Heavens" and "Draw Bow to Both Sides." It quickly relieves stress'},
        {'title': 'Sour Jujube Tea', 'desc': 'Brew Sour Jujube Seed 15g, Lily Bulb 10g, Poria 10g as tea. It nourishes the Heart, calms the Spirit — ideal for stress-induced insomnia'},
        {'title': 'Set Boundaries', 'desc': 'Learn to say "no" and carve out time for solitude and rest. Over-committing depletes Qi — letting go helps you move forward better'},
      ],
    },
    'irritable': {
      'icon': '😤',
      'color': Colors.redAccent,
      'title': 'Calm Your Mind',
      'description': 'Irritability often relates to excessive Heart Fire and rising Liver Yang. TCM says "the Heart houses the Spirit" — when Heart Fire flares, the Spirit becomes restless. Clearing heat and calming fire is key.',
      'tips': [
        {'title': 'Lotus Heart Tea', 'desc': 'Brew 3-5g lotus plumule in hot water. Excellent for clearing Heart Fire. Though bitter, it quickly soothes restlessness'},
        {'title': 'Acupressure: Yongquan', 'desc': 'Rub the front third of your sole until warm. Yongquan point draws fire back to its source, guiding rising empty fire down to the Kidneys'},
        {'title': 'Cold Water Face Splash', 'desc': 'Gently splash cold water on your face several times. Cold stimulation activates the parasympathetic nervous system for quick calming'},
        {'title': 'Sitting Meditation', 'desc': 'Sit quietly for 5 minutes, focusing on your breath. Let irritable thoughts drift by like clouds — don\'t chase or fight them'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => safePop(context)),
        title: Text(AppLocalizations.of(context).t('wellness_emotional_support')),
        backgroundColor: isDark ? ShunShiColors.darkSurface : Colors.pink[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PaywallBanner(message: 'Upgrade to unlock mood tracking and AI mood analysis', icon: Icons.favorite),
            // AI Chat Entry
            Card(
              color: Colors.pink[50],
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.pink[100],
                        child: const Text('🤖', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).t('wellness_chat_with_seasons'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(AppLocalizations.of(context).t('wellness_always_here_to_listen'), style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chat),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Mindful Breathing Entry
            Card(
              color: Colors.teal[50],
              child: InkWell(
                onTap: () => _showBreathingGuide(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal[100],
                        child: const Text('🌬️', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context).t('wellness_mindful_breathing_guide'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(AppLocalizations.of(context).t('wellness_follow_the_rhythm_relax_body_and_mind'), style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context).t('home_how_are_you_feeling_right_now'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _moodResponses.entries.map((entry) {
                return _buildMoodChip(entry.key, entry.value);
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_selectedMood != null) _buildSuggestions(),
          ],
        ),
      ),
    );
  }

  void _showBreathingGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('wellness_mindful_breathing_guide_2')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _breathingSteps.map((step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${_breathingSteps.indexOf(step) + 1}',
                      style: TextStyle(fontSize: 12, color: Colors.teal[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(step['desc']!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/chat');
            },
            child: Text(AppLocalizations.of(context).t('wellness_start_guide')),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String key, Map<String, dynamic> data) {
    final isSelected = _selectedMood == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? data['color'] : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? data['color'] : ShunShiColors.borderGhost!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data['icon'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              _getMoodLabel(key),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodLabel(String key) {
    const labels = {
      'happy': 'Happy',
      'sad': 'Sad',
      'anxious': 'Anxious',
      'angry': 'Angry',
      'tired': 'Tired',
      'lonely': 'Lonely',
      'stressed': 'Stressed',
      'irritable': 'Irritable',
    };
    return labels[key] ?? key;
  }

  Widget _buildSuggestions() {
    final data = _moodResponses[_selectedMood]!;
    final tips = data['tips'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: (data['color'] as Color).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data['icon'], style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(data['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(data['description'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).t('wellness_relief_methods'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tips.map((tip) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: data['color'] as Color),
                    const SizedBox(width: 8),
                    Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tip['desc'], style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}
