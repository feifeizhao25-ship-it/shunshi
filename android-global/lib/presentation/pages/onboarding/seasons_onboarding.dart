import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/app_localizations.dart';

/// SEASONS International Onboarding — Calm × AI Companion × Seasonal Living
/// 5-step, ~90s, zero TCM terminology.
class SeasonsOnboarding extends StatefulWidget {
  const SeasonsOnboarding({super.key});

  @override
  State<SeasonsOnboarding> createState() => _SeasonsOnboardingState();
}

class _SeasonsOnboardingState extends State<SeasonsOnboarding> {
  final _controller = PageController();
  int _currentPage = 0;

  // User selections
  String? _feeling;
  String? _supportGoal;
  String? _lifeStage;
  String? _timing;
  String? _style;

  // Gradient colors per step — from deep green to cream
  static const _gradientColors = <List<Color>>[
    [Color(0xFF144227), Color(0xFF2A6B3A)], // Step 0: deep green
    [Color(0xFF2A6B3A), Color(0xFF5A9A6A)], // Step 1
    [Color(0xFF5A9A6A), Color(0xFF8FBF8F)], // Step 2
    [Color(0xFF8FBF8F), Color(0xFFC8DFC0)], // Step 3
    [Color(0xFFC8DFC0), Color(0xFFFDF9F4)], // Step 4: cream
  ];

  static final _steps = <_OnboardingStep>[
    _OnboardingStep(
      question: 'How have you been feeling lately?',
      subtitle: 'There are no wrong answers.',
      options: ['Calm', 'Stressed', 'Tired', 'Overwhelmed', 'Curious'],
      prefKey: 'feeling',
    ),
    _OnboardingStep(
      question: 'What would you like help with?',
      subtitle: 'We\'ll tailor your experience around this.',
      options: [
        'Sleep better',
        'Unwind in the evening',
        'Feel calmer during the day',
        'Build a gentler rhythm',
        'Reflect more often',
      ],
      prefKey: 'support_goal',
    ),
    _OnboardingStep(
      question: 'What best describes you right now?',
      subtitle: 'This helps us personalise content.',
      options: [
        'Student',
        'Working professional',
        'Parent',
        'Midlife',
        'Retired',
      ],
      prefKey: 'life_stage',
    ),
    _OnboardingStep(
      question: 'When would you like support?',
      subtitle: 'We\'ll send gentle nudges at the right time.',
      options: ['Morning', 'Afternoon', 'Evening'],
      prefKey: 'timing',
      icons: [Icons.wb_sunny_outlined, Icons.wb_cloudy_outlined, Icons.nights_stay_outlined],
    ),
    _OnboardingStep(
      question: 'How should SEASONS feel?',
      subtitle: 'You can always change this.',
      options: [
        'Minimal and quiet',
        'Gentle daily support',
        'More active guidance',
      ],
      prefKey: 'style',
    ),
  ];

  String? _selectionFor(int index) {
    switch (index) {
      case 0: return _feeling;
      case 1: return _supportGoal;
      case 2: return _lifeStage;
      case 3: return _timing;
      case 4: return _style;
      default: return null;
    }
  }

  void _setSelectionFor(int index, String value) {
    setState(() {
      switch (index) {
        case 0: _feeling = value;
        case 1: _supportGoal = value;
        case 2: _lifeStage = value;
        case 3: _timing = value;
        case 4: _style = value;
      }
    });
  }

  bool get _canProceed => _selectionFor(_currentPage) != null;

  void _next() {
    if (_currentPage < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('feeling', _feeling ?? '');
    await prefs.setString('support_goal', _supportGoal ?? '');
    await prefs.setString('life_stage', _lifeStage ?? '');
    await prefs.setString('timing', _timing ?? '');
    await prefs.setString('style', _style ?? '');

    if (!mounted) return;
    context.go('/home');
  }

  String get _dailyInsight {
    final goal = _supportGoal ?? 'feel your best';
    return 'Based on your preferences, we\'ll help you $goal. Let\'s start with a gentle evening routine.';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors[_currentPage];
    final isLastStep = _currentPage == _steps.length - 1;
    final isDark = _currentPage < 3;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      GestureDetector(
                        onTap: _back,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : SeasonsColors.textPrimary.withValues(alpha: 0.8),
                        ),
                      )
                    else const SizedBox(width: 28),
                    const Spacer(),
                    // Progress dots
                    Row(
                      children: List.generate(_steps.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentPage ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _currentPage
                                ? (isDark ? Colors.white : SeasonsColors.primary)
                                : (isDark ? Colors.white.withValues(alpha: 0.25) : SeasonsColors.textHint),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    final selection = _selectionFor(index);
                    final dark = index < 3;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),

                          // Step indicator
                          Text(
                            'Step ${index + 1} of ${_steps.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                              color: dark ? Colors.white.withValues(alpha: 0.5) : SeasonsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Question
                          Text(
                            step.question,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              height: 1.3,
                              color: dark ? Colors.white : SeasonsColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              height: 1.5,
                              color: dark ? Colors.white.withValues(alpha: 0.6) : SeasonsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Options
                          ...List.generate(step.options.length, (i) {
                            final option = step.options[i];
                            final isSelected = selection == option;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _setSelectionFor(index, option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (dark ? Colors.white.withValues(alpha: 0.2) : SeasonsColors.primary.withValues(alpha: 0.15))
                                        : (dark ? Colors.white.withValues(alpha: 0.07) : SeasonsColors.surface),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? (dark ? Colors.white.withValues(alpha: 0.6) : SeasonsColors.primary)
                                          : (dark ? Colors.white.withValues(alpha: 0.12) : SeasonsColors.border),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (step.icons != null && i < step.icons!.length) ...[
                                        Icon(
                                          step.icons![i],
                                          size: 20,
                                          color: isSelected
                                              ? (dark ? Colors.white : SeasonsColors.primary)
                                              : (dark ? Colors.white.withValues(alpha: 0.5) : SeasonsColors.textSecondary),
                                        ),
                                        const SizedBox(width: 14),
                                      ],
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                                            color: isSelected
                                                ? (dark ? Colors.white : SeasonsColors.primary)
                                                : (dark ? Colors.white.withValues(alpha: 0.85) : SeasonsColors.textPrimary),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: dark ? Colors.white.withValues(alpha: 0.9) : SeasonsColors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Daily Insight preview on last step after selection
                          if (isLastStep && selection != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR FIRST DAILY INSIGHT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.0,
                                      color: dark ? Colors.white.withValues(alpha: 0.5) : SeasonsColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _dailyInsight,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                      height: 1.6,
                                      color: dark ? Colors.white.withValues(alpha: 0.85) : SeasonsColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _canProceed ? 1.0 : 0.4,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.95)
                            : SeasonsColors.primary,
                        foregroundColor: isDark
                            ? const Color(0xFF144227)
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isLastStep ? 'Begin' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String question;
  final String subtitle;
  final List<String> options;
  final String prefKey;
  final List<IconData>? icons;

  const _OnboardingStep({
    required this.question,
    required this.subtitle,
    required this.options,
    required this.prefKey,
    this.icons,
  });
}
