import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/components/components.dart';

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
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // User selections
  String? _selectedFeeling;
  String? _selectedGoal;
  String? _selectedStage;
  int? _selectedHour;
  String? _selectedStyle;
  String _selectedHemisphere = 'north'; // default — user can change in settings

  // Step 1: Feeling selection (NEW)
  final _feelings = [
    ('calm', '😌', 'Calm'),
    ('stressed', '😰', 'Stressed'),
    ('tired', '😴', 'Tired'),
    ('overwhelmed', '🥴', 'Overwhelmed'),
    ('curious', '🤔', 'Curious'),
  ];

  // Step 2: Goal selection (per PRD)
  final _goals = [
    ('sleep', '😴', 'Better Sleep'),
    ('unwind', '🧘', 'Reduce Stress'),
    ('calm', '🌿', 'Mindfulness'),
    ('ritual', '⏰', 'Daily Ritual'),
    ('reflect', '📝', 'Self Reflection'),
  ];

  // Step 3: Life stage (existing)
  final _stages = [
    ('20-30', 'Young Adult'),
    ('30-40', 'Balancing'),
    ('40-50', 'Mid-life'),
    ('50-60', 'Nurturing'),
    ('60+', 'Golden'),
  ];

  // Step 4: Time preference (existing)
  final _hours = [
    '6 AM', '7 AM', '8 AM', '9 AM',
    '12 PM', '3 PM', '6 PM', '8 PM', '9 PM',
  ];

  // Step 5: Style preference (NEW)
  final _styles = [
    ('minimal', '✨', 'Minimal', 'Clean, less is more'),
    ('gentle', '🌸', 'Gentle', 'Warm, nurturing'),
    ('more_active', '⚡', 'Active', 'Engaging, energetic'),
  ];

  // Maps hour index to API value
  String _hourToApiValue(int index) {
    const apiValues = ['6am', '7am', '8am', '9am', '12pm', '3pm', '6pm', '8pm', '9pm'];
    return apiValues[index];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0: return true;
      case 1: return _selectedFeeling != null;
      case 2: return _selectedGoal != null;
      case 3: return _selectedStage != null;
      case 4: return _selectedHour != null;
      case 5: return _selectedStyle != null;
      case 6: return true;
      default: return true;
    }
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Save to SharedPreferences
    if (_selectedFeeling != null) await prefs.setString('user_feeling', _selectedFeeling!);
    if (_selectedGoal != null) await prefs.setString('user_goal', _selectedGoal!);
    if (_selectedStage != null) await prefs.setString('user_stage', _selectedStage!);
    if (_selectedHour != null) await prefs.setInt('preferred_hour', _selectedHour!);
    if (_selectedStyle != null) await prefs.setString('style_preference', _selectedStyle!);
    await prefs.setString('hemisphere', _selectedHemisphere);
    await OnboardingPage.markCompleted();

    // Build API body
    final body = {
      'feeling': _selectedFeeling ?? 'calm',
      'help_goal': _selectedGoal ?? 'calm',
      'life_stage': _selectedStage ?? '20-30',
      'support_time': _hourToApiValue(_selectedHour ?? 0),
      'style_preference': _selectedStyle ?? 'gentle',
      'hemisphere': _selectedHemisphere,
    };

    // Call backend API — fallback to local storage on failure
    try {
      await ApiService.instance.post(
        '/seasons/onboarding/complete',
        data: body,
      );

      // Generate first daily insight on completion
      try {
        await ApiService.instance.post(
          '/api/v1/ai/generate-first-insight',
          data: {
            'hemisphere': _selectedHemisphere,
            'feeling': _selectedFeeling ?? 'calm',
            'goal': _selectedGoal ?? 'calm',
            'style': _selectedStyle ?? 'gentle',
          },
        );
      } catch (e) {
        debugPrint('First insight generation failed (non-critical): $e');
      }
    } catch (e) {
      // Fallback: data already saved to SharedPreferences above
      debugPrint('Onboarding API call failed, using local storage: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  // ── Theme感知辅助 ──

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.background : SeasonsColors.background;
  Color _primary(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.primary : SeasonsColors.primary;
  Color _primaryLight(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.primaryLight : SeasonsColors.primaryLight;
  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.textPrimary : SeasonsColors.textPrimary;
  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.textSecondary : SeasonsColors.textSecondary;
  Color _textHint(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.textHint : SeasonsColors.textHint;
  Color _border(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.border : SeasonsColors.border;
  Color _surfaceDim(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.surfaceDim : SeasonsColors.surfaceDim;
  Color _surface(BuildContext context) =>
      _isDark(context) ? SeasonsDarkColors.surface : SeasonsColors.surface;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(SeasonsSpacing.md),
                child: TextButton(
                  onPressed: _isLoading ? null : _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: SeasonsTextStyles.caption.copyWith(
                      color: _textHint(context),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 7,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildStep(context, index),
              ),
            ),

            // Progress dots (7 steps)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: SeasonsSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _primary(context)
                          : _surfaceDim(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.fromLTRB(
                SeasonsSpacing.pagePadding,
                SeasonsSpacing.md,
                SeasonsSpacing.pagePadding,
                SeasonsSpacing.xl,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 52,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : GentleButton(
                      text: _currentPage == 6 ? 'Get Started' : 'Next',
                      isPrimary: true,
                      onPressed: _canProceed ? _nextPage : null,
                      horizontalPadding: SeasonsSpacing.xl * 2,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step) {
    switch (step) {
      case 0: return _buildWelcomeStep(context);
      case 1: return _buildFeelingStep(context);
      case 2: return _buildGoalStep(context);
      case 3: return _buildStageStep(context);
      case 4: return _buildTimeStep(context);
      case 5: return _buildStyleStep(context);
      case 6: return _buildCompleteStep(context);
      default: return const SizedBox.shrink();
    }
  }

  // ==================== Step 0: Welcome ====================
  Widget _buildWelcomeStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary(context), _primaryLight(context)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.eco_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
          Text(
            "Hi, I'm SEASONS",
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeasonsSpacing.lg),
          Text(
            'Your gentle companion for\nmindful, seasonal living',
            textAlign: TextAlign.center,
            style: SeasonsTextStyles.body.copyWith(
              color: _textSecondary(context),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Step 1: Feeling (NEW) ====================
  Widget _buildFeelingStep(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SeasonsSpacing.xl),
          Text(
            'How have you been feeling?',
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'Take a moment to check in with yourself',
            style: SeasonsTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),
          ...List.generate(_feelings.length, (index) {
            final (value, emoji, label) = _feelings[index];
            final isSelected = _selectedFeeling == value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _feelings.length - 1
                    ? SeasonsSpacing.md
                    : 0,
              ),
              child: SoftCard(
                borderRadius: SeasonsSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: SeasonsSpacing.lg,
                  vertical: SeasonsSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedFeeling = value),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: SeasonsSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: SeasonsTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight: isSelected
                              ? FontWeight.w400
                              : FontWeight.w300,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 2: Goals ====================
  Widget _buildGoalStep(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SeasonsSpacing.xl),
          Text(
            'What would you like help with?',
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'Pick one area to focus on',
            style: SeasonsTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),
          ...List.generate(_goals.length, (index) {
            final (value, emoji, label) = _goals[index];
            final isSelected = _selectedGoal == value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _goals.length - 1
                    ? SeasonsSpacing.md
                    : 0,
              ),
              child: SoftCard(
                borderRadius: SeasonsSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: SeasonsSpacing.lg,
                  vertical: SeasonsSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedGoal = value),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: SeasonsSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: SeasonsTextStyles.body.copyWith(
                          color: isSelected
                              ? _primary(context)
                              : _textPrimary(context),
                          fontWeight: isSelected
                              ? FontWeight.w400
                              : FontWeight.w300,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 3: Life Stage ====================
  Widget _buildStageStep(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SeasonsSpacing.xl),
          Text(
            'Where are you now?',
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'Helps us personalize for you',
            style: SeasonsTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),
          ...List.generate(_stages.length, (index) {
            final (age, label) = _stages[index];
            final isSelected = _selectedStage == age;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _stages.length - 1
                    ? SeasonsSpacing.md
                    : 0,
              ),
              child: SoftCard(
                borderRadius: SeasonsSpacing.radiusLarge,
                borderColor: isSelected ? SeasonsColors.warm : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: SeasonsSpacing.lg,
                  vertical: SeasonsSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedStage = age),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        age,
                        style: SeasonsTextStyles.body.copyWith(
                          color: isSelected
                              ? SeasonsColors.warm
                              : _textPrimary(context),
                          fontWeight: isSelected
                              ? FontWeight.w400
                              : FontWeight.w300,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: SeasonsTextStyles.caption.copyWith(
                        color: isSelected
                            ? SeasonsColors.warm
                            : _textHint(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 4: Time Preference ====================
  Widget _buildTimeStep(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SeasonsSpacing.xl),
          Text(
            'When would you like support?',
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'We\'ll remind you at the right time',
            style: SeasonsTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),
          Wrap(
            spacing: SeasonsSpacing.sm,
            runSpacing: SeasonsSpacing.sm,
            children: _hours.map((hour) {
              final isSelected = _selectedHour == _hours.indexOf(hour);
              return InkWell(
                onTap: () => setState(
                    () => _selectedHour = _hours.indexOf(hour)),
                borderRadius:
                    BorderRadius.circular(SeasonsSpacing.radiusFull),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeasonsSpacing.lg,
                    vertical: SeasonsSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primary(context)
                        : _surface(context),
                    borderRadius:
                        BorderRadius.circular(SeasonsSpacing.radiusFull),
                    border: Border.all(
                      color: isSelected
                          ? _primary(context)
                          : _border(context),
                    ),
                  ),
                  child: Text(
                    hour,
                    style: SeasonsTextStyles.bodySecondary.copyWith(
                      color: isSelected
                          ? Colors.white
                          : _textPrimary(context),
                      fontWeight: isSelected
                          ? FontWeight.w400
                          : FontWeight.w300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== Step 5: Style Preference (NEW) ====================
  Widget _buildStyleStep(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: SeasonsSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SeasonsSpacing.xl),
          Text(
            'How should SEASONS feel?',
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            'Choose an experience that suits you',
            style: SeasonsTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xl),
          ...List.generate(_styles.length, (index) {
            final (value, emoji, label, description) = _styles[index];
            final isSelected = _selectedStyle == value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _styles.length - 1
                    ? SeasonsSpacing.md
                    : 0,
              ),
              child: SoftCard(
                borderRadius: SeasonsSpacing.radiusLarge,
                borderColor: isSelected ? _primary(context) : null,
                borderWidth: isSelected ? 1.5 : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: SeasonsSpacing.lg,
                  vertical: SeasonsSpacing.md + 4,
                ),
                onTap: () => setState(() => _selectedStyle = value),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: SeasonsSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: SeasonsTextStyles.body.copyWith(
                              color: isSelected
                                  ? _primary(context)
                                  : _textPrimary(context),
                              fontWeight: isSelected
                                  ? FontWeight.w400
                                  : FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: SeasonsTextStyles.caption.copyWith(
                              color: _textHint(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: _primary(context), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Step 6: Complete ====================
  Widget _buildCompleteStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 40,
              color: _primary(context),
            ),
          ),
          const SizedBox(height: SeasonsSpacing.xxl),
          Text(
            "You're all set",
            style: SeasonsTextStyles.greeting.copyWith(
              color: _textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SeasonsSpacing.lg),
          Text(
            'Your wellness journey begins now',
            textAlign: TextAlign.center,
            style: SeasonsTextStyles.body.copyWith(
              color: _textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
