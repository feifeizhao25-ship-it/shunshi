/// SEASONS Onboarding — 5-step, 90-second target
/// Step 1: How have you been feeling?
/// Step 2: What would you like help with?
/// Step 3: Life stage
/// Step 4: When would you like support?
/// Step 5: How should SEASONS feel?
/// Output: user profile + first daily insight
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _current = 0;

  // Step 1 selections
  String? _feeling;
  // Step 2 selections
  final Set<String> _helpWith = {};
  // Step 3
  String? _lifeStage;
  // Step 4
  String? _supportTime;
  // Step 5
  String? _feelStyle;

  static const _feelings = [
    ('😌', 'Calm', 'Feeling balanced and at peace'),
    ('😤', 'Stressed', 'Under pressure or overwhelmed'),
    ('😴', 'Tired', 'Low energy, need rest'),
    ('😰', 'Anxious', 'Worried or on edge'),
    ('🤔', 'Curious', 'Open to exploring something new'),
  ];

  static const _helpOptions = [
    ('🛏️', 'Sleep', 'Better rest and evening wind-down'),
    ('🌅', 'Evening Unwind', 'Decompress after long days'),
    ('🧘', 'Daytime Calm', 'Stay centered during the day'),
    ('🌿', 'Seasonal Rhythm', 'Live in tune with nature'),
    ('📝', 'Reflection', 'Journal and process thoughts'),
  ];

  static const _lifeStages = [
    ('🎓', 'Student', 'Learning and growing'),
    ('💼', 'Working Professional', 'Career-focused'),
    ('👔', 'Senior Professional', 'Experienced and established'),
    ('👶', 'Parent', 'Raising a family'),
    ('🌟', 'Midlife Transition', 'Re-evaluating priorities'),
  ];

  static const _supportTimes = [
    ('🌅', 'Morning', 'Start the day right'),
    ('☀️', 'Afternoon', 'Midday reset'),
    ('🌙', 'Evening', 'Wind down and prepare for rest'),
  ];

  static const _feelStyles = [
    ('🍃', 'Minimal', 'Just the essentials, nothing extra'),
    ('🌊', 'Gentle Daily Support', 'Light guidance each day'),
    ('🗺️', 'More Active Guidance', 'Structured plans and check-ins'),
  ];

  bool get _canProceed {
    switch (_current) {
      case 0: return _feeling != null;
      case 1: return _helpWith.isNotEmpty;
      case 2: return _lifeStage != null;
      case 3: return _supportTime != null;
      case 4: return _feelStyle != null;
      default: return false;
    }
  }

  void _next() {
    if (_current < 4) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('onboarding_feeling', _feeling ?? '');
    await prefs.setStringList('onboarding_help', _helpWith.toList());
    await prefs.setString('onboarding_life_stage', _lifeStage ?? '');
    await prefs.setString('onboarding_support_time', _supportTime ?? '');
    await prefs.setString('onboarding_feel_style', _feelStyle ?? '');

    // Post to backend
    try {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.seasonsapp.com'));
      await dio.post('/api/v1/user/profile', data: {
        'feeling': _feeling?.toLowerCase(),
        'help_goal': _helpWith.toList(),
        'life_stage': _lifeStage?.toLowerCase(),
        'support_time': _supportTime?.toLowerCase(),
        'style_preference': _feelStyle?.toLowerCase(),
        'hemisphere': 'north',
        'timezone': 'Asia/Shanghai',
      });
    } catch (_) {}
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: Column(children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              if (_current > 0)
                GestureDetector(
                  onTap: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: ShunShiColors.surface, borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back, size: 18, color: ShunShiColors.textPrimary),
                  ),
                )
              else const SizedBox(width: 36),
              const Spacer(),
              Text('SEASONS', style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF533afd),
              )),
              const Spacer(),
              const SizedBox(width: 36),
            ]),
          ),
          
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: List.generate(5, (i) => Expanded(child: Container(
              height: 3, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _current ? const Color(0xFF533afd) : ShunShiColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            )))),
          ),
          
          // Pages
          Expanded(child: PageView.builder(
            controller: _controller,
            physics: _canProceed ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: 5,
            itemBuilder: (context, index) => _buildStep(index),
          )),
          
          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF533afd),
                  disabledBackgroundColor: const Color(0xFF533afd).withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _current == 4 ? 'Begin My Journey' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep(int step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_stepTitle(step), style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          fontSize: 26, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
        )),
        const SizedBox(height: 8),
        Text(_stepSubtitle(step), style: TextStyle(fontSize: 15, color: ShunShiColors.textSecondary, height: 1.5)),
        const SizedBox(height: 24),
        ..._buildOptions(step),
      ]),
    );
  }

  String _stepTitle(int step) {
    const titles = [
      'How have you\nbeen feeling?',
      'What would you\nlike help with?',
      'What stage of life\nare you in?',
      'When would you\nlike support?',
      'How should\nSEASONS feel?',
    ];
    return titles[step];
  }

  String _stepSubtitle(int step) {
    const subs = [
      'There are no wrong answers.',
      'Pick as many as you\'d like.',
      'This helps us personalize your experience.',
      'We\'ll adjust your daily rhythm accordingly.',
      'We\'ll match your preferred level of guidance.',
    ];
    return subs[step];
  }

  List<Widget> _buildOptions(int step) {
    switch (step) {
      case 0: return _feelings.map((f) => _optionCard(f.$1, f.$2, f.$3, _feeling == f.$2, () => setState(() => _feeling = f.$2))).toList();
      case 1: return _helpOptions.map((h) => _optionCard(h.$1, h.$2, h.$3, _helpWith.contains(h.$2), () => setState(() => _helpWith.contains(h.$2) ? _helpWith.remove(h.$2) : _helpWith.add(h.$2)))).toList();
      case 2: return _lifeStages.map((l) => _optionCard(l.$1, l.$2, l.$3, _lifeStage == l.$2, () => setState(() => _lifeStage = l.$2))).toList();
      case 3: return _supportTimes.map((t) => _optionCard(t.$1, t.$2, t.$3, _supportTime == t.$2, () => setState(() => _supportTime = t.$2))).toList();
      case 4: return _feelStyles.map((s) => _optionCard(s.$1, s.$2, s.$3, _feelStyle == s.$2, () => setState(() => _feelStyle = s.$2))).toList();
      default: return [];
    }
  }

  Widget _optionCard(String emoji, String title, String subtitle, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF533afd).withOpacity(0.08) : ShunShiColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFF533afd) : Colors.transparent, width: 1.5),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF533afd) : ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
            ])),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF533afd), size: 22),
          ]),
        ),
      ),
    );
  }
}
