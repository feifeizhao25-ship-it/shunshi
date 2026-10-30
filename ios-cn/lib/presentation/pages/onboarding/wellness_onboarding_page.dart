import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';

/// 极速引导页 — 3步完成，每步2-5秒
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
    _Concern('睡眠', '😴', '改善睡眠质量'),
    _Concern('饮食', '🍵', '饮食调理养生'),
    _Concern('运动', '🏃', '增强体质功法'),
    _Concern('情绪', '🧘', '情绪管理减压'),
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

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  bool get _wide => MediaQuery.sizeOf(context).shortestSide >= 600;
  Color get _bg => _dark ? ShunShiColors.darkBackground : AppColors.background(context);
  Color get _text => _dark ? ShunShiColors.darkTextPrimary : AppColors.textPrimary(context);
  Color get _textSecondary => _dark ? ShunShiColors.darkTextSecondary : AppColors.textSecondary(context);
  Color get _textTertiary => _dark ? ShunShiColors.darkTextTertiary : AppColors.textTertiary(context);
  Color get _surface => _dark ? ShunShiColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest(context);
  Color get _border => _dark ? ShunShiColors.darkBorder : AppColors.border(context);
  Color get _accent => _dark ? ShunShiColors.darkPrimary : AppColors.primary(context);
  Color get _onButton => _dark ? const Color(0xFF121212) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(_wide ? 40 : 24),
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

  // ── Page 1: 欢迎 (2秒) ──
  Widget _page1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Container(
          width: _wide ? 120 : 88, height: _wide ? 120 : 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary(context), AppColors.primaryLight(context)],
            ),
            borderRadius: BorderRadius.circular(_wide ? 28 : 22),
          ),
          child: Icon(Icons.eco, size: _wide ? 60 : 44, color: Colors.white),
        ),
        SizedBox(height: _wide ? 40 : 32),
        Text(
          '顺时',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: _wide ? 52 : 36, fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '顺应天时，养身心',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: _wide ? 24 : 18, color: _textSecondary,
          ),
        ),
        SizedBox(height: _wide ? 72 : 56),
        SizedBox(
          width: double.infinity,
          height: _wide ? 68 : 54,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _dark ? ShunShiColors.darkPrimary : AppColors.primary(context),
              foregroundColor: _onButton,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('开始使用', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: _wide ? 22 : 17, fontWeight: FontWeight.w600)),
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
        Text(
          '你最关注什么？',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: _wide ? 36 : 26, fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '选择一项，我们为你定制方案',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: _wide ? 18 : 14, color: _textTertiary,
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
                    ? _accent.withValues(alpha: 0.18)
                    : _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedConcern == c.label
                      ? _accent
                      : _border,
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
                          fontSize: _wide ? 22 : 18, fontWeight: FontWeight.w600,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: _selectedConcern == c.label ? _accent : _text,
                        )),
                        const SizedBox(height: 2),
                        Text(c.desc, style: TextStyle(
                          fontSize: _wide ? 16 : 13, color: _textTertiary,
                        )),
                      ],
                    ),
                  ),
                  if (_selectedConcern == c.label)
                    Icon(Icons.check_circle, color: _accent, size: 24),
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
    final concern = _selectedConcern ?? '养生';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: _dark ? 0.22 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 44, color: _accent),
        ),
        const SizedBox(height: 28),
        Text(
          '准备就绪！',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: _wide ? 40 : 30, fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '我们将围绕「$concern」为你定制\n个性化养生方案',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: _wide ? 20 : 16, color: _textSecondary, height: 1.6,
          ),
        ),
        const SizedBox(height: 44),
        SizedBox(
          width: double.infinity,
          height: _wide ? 68 : 54,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: _dark ? ShunShiColors.darkPrimary : AppColors.primary(context),
              foregroundColor: _onButton,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('开始体验', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, fontSize: _wide ? 22 : 17, fontWeight: FontWeight.w600)),
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
          color: i == _page ? _accent : _border,
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
