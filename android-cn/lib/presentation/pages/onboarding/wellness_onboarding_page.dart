import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

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
  late AnimationController _breathAnim;
  late AnimationController _confettiAnim;
  late Animation<double> _scale;
  late Animation<double> _breath;
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

    // Logo breathing animation
    _breathAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breath = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathAnim, curve: Curves.easeInOutSine),
    );
    _breathAnim.repeat(reverse: true);

    // Confetti controller
    _confettiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _scaleAnim.dispose();
    _breathAnim.dispose();
    _confettiAnim.dispose();
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nextPage();
    });
  }

  Future<void> _finish() async {
    _confettiAnim.forward();
    final prefs = await SharedPreferences.getInstance();
    if (_selectedConcern != null) {
      await prefs.setStringList('user_concerns', [_selectedConcern!]);
    }
    await prefs.setBool('onboarding_completed', true);
    // Let confetti play briefly before navigating
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.go('/today');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
          ),
          backgroundColor: bg,
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
                  _buildProgressBar(),
                ],
              ),
            ),
          ),
        ),

        // Confetti overlay on page 3
        if (_page == 2 && _confettiAnim.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_confettiAnim.value),
              ),
            ),
          ),
      ],
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
        // Logo with breathing animation
        ScaleTransition(
          scale: _breath,
          child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: ShunShiColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.eco, size: 44, color: Colors.white),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '顺时',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 36, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '顺应天时，养身心',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 18, color: ShunShiColors.textSecondary,
          ),
        ),
        const SizedBox(height: 56),
        // "开始使用" button with gradient + shadow
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ShunShiColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('开始使用', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
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
          '你最关注什么？',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 26, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择一项，我们为你定制方案',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 14, color: ShunShiColors.textTertiary,
          ),
        ),
        const SizedBox(height: 36),
        ..._concerns.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _BounceSelectionCard(
            isSelected: _selectedConcern == c.label,
            onTap: () => _selectConcern(c.label),
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
            color: ShunShiColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 44, color: ShunShiColors.primary),
        ),
        const SizedBox(height: 28),
        const Text(
          '准备就绪！',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 30, fontWeight: FontWeight.w700,
            color: ShunShiColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '我们将围绕「$concern」为你定制\n个性化养生方案',
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ShunShiColors.primary, ShunShiColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ShunShiColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('开始体验', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress bar (replaces dots) ──
  Widget _buildProgressBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(3, (i) {
            final isActive = i <= _page;
            final isCurrent = i == _page;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: isCurrent ? 4 : 3,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ShunShiColors.primary
                        : ShunShiColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Bounce selection card — scales up slightly on selection
class _BounceSelectionCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _BounceSelectionCard({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_BounceSelectionCard> createState() => _BounceSelectionCardState();
}

class _BounceSelectionCardState extends State<_BounceSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant _BounceSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? ShunShiColors.primary.withValues(alpha: 0.08)
                : ShunShiColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? ShunShiColors.primary
                  : ShunShiColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Simple confetti painter — particle animation
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);
  static final _particles = List.generate(40, (i) => _Particle(_rng));

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = progress;
      final x = p.startX * size.width + p.vx * t * size.width;
      final y = p.startY * size.height * 0.3 + p.vy * t * size.height * 1.2;
      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);
      final scale = (p.size * (1.0 - t * 0.3)).clamp(2.0, 8.0);

      if (y > size.height || opacity <= 0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation * t * 6.28);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: scale, height: scale * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double size;
  final double rotation;
  final Color color;

  static const _colors = [
    ShunShiColors.primary,
    ShunShiColors.goldLight,
    ShunShiColors.apricot,
    ShunShiColors.calm,
    ShunShiColors.warm,
  ];

  _Particle(Random rng)
      : startX = rng.nextDouble(),
        startY = rng.nextDouble(),
        vx = (rng.nextDouble() - 0.5) * 0.3,
        vy = rng.nextDouble() * 0.5 + 0.3,
        size = rng.nextDouble() * 5 + 3,
        rotation = rng.nextDouble(),
        color = _colors[rng.nextInt(_colors.length)];
}

class _Concern {
  final String label;
  final String emoji;
  final String desc;
  const _Concern(this.label, this.emoji, this.desc);
}
