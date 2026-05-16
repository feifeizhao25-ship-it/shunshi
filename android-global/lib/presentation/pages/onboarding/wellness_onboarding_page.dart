import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

/// 极速引导页 — 3步Done，每步2-5秒
class WellnessOnboardingPage extends StatefulWidget {
  const WellnessOnboardingPage({super.key});

  @override
  State<WellnessOnboardingPage> createState() => _WellnessOnboardingPageState();
}

class _WellnessOnboardingPageState extends State<WellnessOnboardingPage>
    with TickerProviderStateMixin {
  int _page = 0;
  String? _selectedConcern;
  late AnimationController _pageAnim;
  late AnimationController _scaleAnim;
  late Animation<double> _scale;
  late Animation<Offset> _slideAnim;

  static const _concerns = [
    _Concern('Sleep', '😴', 'Improve Sleep Quality'),
    _Concern('Diet', '🍵', 'DietConditioningWellness'),
    _Concern('Exercise', '🏃', 'Strengthen Body Type Qigong'),
    _Concern('Emotions', '🧘', 'Emotion Management & Stress Relief'),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _scaleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _scale = CurvedAnimation(parent: _scaleAnim, curve: Curves.easeOutBack);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _scaleAnim.dispose();
    super.dispose();
  }

  void _animateToPage(VoidCallback onPageChanged) {
    _pageAnim.reverse().then((_) {
      onPageChanged();
      _scaleAnim.forward(from: 0.8);
      _pageAnim.forward();
    });
  }

  void _nextPage() => _animateToPage(() => setState(() => _page++));

  void _selectConcern(String concern) {
    setState(() => _selectedConcern = concern);
    // 自动跳转下一页
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nextPage();
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedConcern != null) {
      await prefs.setStringList('user_concerns', [_selectedConcern!]);
    }
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _pageAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scale,
                      child: _buildPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0: return _page1();
      case 1: return _page2();
      case 2: return _page3();
      default: return _page1();
    }
  }

  // ── Page 1: Welcome (2秒) ──
  Widget _page1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.eco, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 32),
        const Text(
          'SEASONS',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 36, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Live in harmony with the seasons, nurture body and heart',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 18, color: ShunShiColors.textSecondary,
          ),
        ),
        const SizedBox(height: 56),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: ShunShiColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context).t('exercise_start'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Page 2: 关注选择 (3秒) ──
  Widget _page2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'What do you care most about?',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 26, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose one — we will customize a plan for you',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 14, color: ShunShiColors.textTertiary,
          ),
        ),
        const SizedBox(height: 36),
        ..._concerns.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () => _selectConcern(c.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: _selectedConcern == c.label
                    ? ShunShiColors.primary.withValues(alpha: 0.08)
                    : ShunShiColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedConcern == c.label
                      ? ShunShiColors.primary
                      : ShunShiColors.border,
                  width: _selectedConcern == c.label ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label, style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: _selectedConcern == c.label
                              ? ShunShiColors.primary
                              : ShunShiColors.textPrimary,
                        )),
                        const SizedBox(height: 2),
                        Text(c.desc, style: const TextStyle(
                          fontSize: 13, color: ShunShiColors.textTertiary,
                        )),
                      ],
                    ),
                  ),
                  if (_selectedConcern == c.label)
                    const Icon(Icons.check_circle, color: ShunShiColors.primary, size: 24),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  // ── Page 3: 准备就绪 (5秒) ──
  Widget _page3() {
    final concern = _selectedConcern ?? 'Wellness';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: ShunShiColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 44, color: ShunShiColors.primary),
        ),
        const SizedBox(height: 28),
        const Text(
          'Ready!',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 30, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ll create a personalized wellness plan focused on \"$concern\"',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 16, color: ShunShiColors.textSecondary, height: 1.6,
          ),
        ),
        const SizedBox(height: 44),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: ShunShiColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context).t('onboarding_start_experience'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── 进度指示器 (3个点) ──
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: i == _page ? 28 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: i == _page ? ShunShiColors.primary : ShunShiColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }
}

class _Concern {
  final String label;
  final String emoji;
  final String desc;
  const _Concern(this.label, this.emoji, this.desc);
}
