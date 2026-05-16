import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../data/storage/storage_manager.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _progressController;

  // Logo animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _growthAnimation; // hand-drawn growth feel
  late Animation<double> _breathAnimation;

  // Progress bar
  late Animation<double> _progressAnimation;

  static const _sloganChars = ['顺', '时', '而', '养', ' ', '·', ' ', '自', '然', '而', '安'];

  @override
  void initState() {
    super.initState();

    // Main animation: 2s total
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Progress bar controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Scale bounce: 0.6 → 1.05 → 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5),
      ),
    );

    // Growth animation: simulates a hand-drawn "drawing" effect
    // Uses rotation wobble + scale micro-oscillation
    _growthAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6),
      ),
    );

    // Breathing: subtle pulse after landing
    _breathAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    // Progress bar
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _progressController.forward();
    });

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final token = StorageManager.user.getToken();
      final profileCompleted = prefs.getBool('profile_completed') ?? false;

      if (!onboardingCompleted) {
        context.go('/onboarding-wellness');
      } else if (token == null) {
        context.go('/login');
      } else if (!profileCompleted) {
        context.go('/profile-setup');
      } else {
        context.go('/today');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunshiDarkColors.background : ShunshiColors.background;
    final primary = ShunshiColors.primary;
    final primaryLight = ShunshiColors.primaryLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bg,
                primaryLight.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _progressController]),
            builder: (context, child) {
              return Stack(
                children: [
                  // Center content
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with growth + breath animation
                          Transform.scale(
                            scale: _breathAnimation.value * _scaleAnimation.value,
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: CustomPaint(
                                painter: _GrowthLogoPainter(
                                  progress: _growthAnimation.value,
                                  primaryColor: primary,
                                  primaryLightColor: primaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: ShunshiSpacing.lg),

                          // Brand name with serif gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primary, primaryLight],
                            ).createShader(bounds),
                            child: Text(
                              '顺时',
                              style: TextStyle(
                                fontFamily: 'NotoSerifSC',
                                fontSize: 34,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: ShunshiSpacing.sm + 4),

                          // Slogan: character-by-character fade-in
                          _buildSlogan(isDark),
                        ],
                      ),
                    ),
                  ),

                  // Bottom progress bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primary.withValues(alpha: 0.6),
                        ),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build slogan with per-character staggered fade
  Widget _buildSlogan(bool isDark) {
    final textSecondary =
        isDark ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;

    // Each char fades in sequentially
    final charDelay = 0.08; // 8% per char
    final startAt = 0.35; // start at 35% of main animation

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_sloganChars.length, (i) {
        final charStart = startAt + (i * charDelay);
        final charEnd = (charStart + 0.15).clamp(0.0, 1.0);
        final opacity = _mainController.value >= charEnd
            ? 1.0
            : _mainController.value > charStart
                ? ((_mainController.value - charStart) / (charEnd - charStart))
                    .clamp(0.0, 1.0)
                : 0.0;

        final ch = _sloganChars[i];
        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 100),
          child: Text(
            ch,
            style: TextStyle(
              fontFamily: 'NotoSansSC',
              fontSize: 15,
              color: textSecondary,
              letterSpacing: ch == '·' ? 2 : 1,
            ),
          ),
        );
      }),
    );
  }
}

/// Custom painter that simulates a Lottie-style hand-drawn growth effect
/// for the logo icon (leaf/eco shape)
class _GrowthLogoPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color primaryLightColor;

  _GrowthLogoPainter({
    required this.progress,
    required this.primaryColor,
    required this.primaryLightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (progress <= 0) return;

    // Background rounded rect with gradient
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      Radius.circular(20 * progress),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, primaryLightColor],
      ).createShader(rect.outerRect);

    // Scale the drawing area with progress for "growth" feel
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(progress);
    canvas.translate(-center.dx, -center.dy);

    // Draw rounded rect background
    canvas.drawRRect(rect, paint);

    // Draw shadow glow
    final shadowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRRect(rect, shadowPaint);

    // Draw eco icon (leaf shape) at current progress
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    // Draw a stylized leaf that "grows"
    _drawGrowingLeaf(canvas, center, 44 * progress, iconPaint, fillPaint);

    canvas.restore();
  }

  void _drawGrowingLeaf(
      Canvas canvas, Offset center, double size, Paint stroke, Paint fill) {
    final leafProgress = (progress * 1.2).clamp(0.0, 1.0);
    if (leafProgress <= 0) return;

    final path = Path();
    // Main leaf body
    path.moveTo(center.dx, center.dy + size * 0.35);
    path.quadraticBezierTo(
      center.dx + size * 0.45 * leafProgress,
      center.dy - size * 0.1,
      center.dx,
      center.dy - size * 0.4 * leafProgress,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.45 * leafProgress,
      center.dy - size * 0.1,
      center.dx,
      center.dy + size * 0.35,
    );

    canvas.drawPath(path, stroke);

    // Stem
    final stemPath = Path();
    stemPath.moveTo(center.dx, center.dy + size * 0.35);
    stemPath.lineTo(center.dx, center.dy - size * 0.4 * leafProgress);
    canvas.drawPath(stemPath, stroke);

    // Small veins
    if (leafProgress > 0.5) {
      final veinProgress = (leafProgress - 0.5) * 2;
      final veinStroke = Paint()
        ..color = Colors.white.withValues(alpha: 0.6 * veinProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Left vein
      canvas.drawLine(
        Offset(center.dx, center.dy),
        Offset(center.dx - size * 0.15 * veinProgress, center.dy - size * 0.1 * veinProgress),
        veinStroke,
      );
      // Right vein
      canvas.drawLine(
        Offset(center.dx, center.dy - size * 0.15),
        Offset(center.dx + size * 0.15 * veinProgress, center.dy - size * 0.25 * veinProgress),
        veinStroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
