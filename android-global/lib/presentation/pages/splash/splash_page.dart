import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../core/theme/seasons_spacing.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    // 总动画时长1.5s
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 缩放 0.85 → 1.0
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // 淡入 0.0 → 1.0
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // 呼吸缩放 0.95 → 1.05
    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.forward();

    // 1.5s后跳转
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      if (onboardingCompleted) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? SeasonsDarkColors.primary : SeasonsColors.primary;
    final primaryLight =
        isDark ? SeasonsDarkColors.primaryLight : SeasonsColors.primaryLight;
    final textPrimary =
        isDark ? SeasonsDarkColors.textPrimary : SeasonsColors.textPrimary;
    final textSecondary =
        isDark ? SeasonsDarkColors.textSecondary : SeasonsColors.textSecondary;
    final bg = isDark ? SeasonsDarkColors.background : SeasonsColors.background;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bg,
              primaryLight.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 呼吸动画logo
                    Transform.scale(
                      scale: _breathAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 32,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: SeasonsSpacing.lg),

                    // 品牌名
                    Text(
                      'SEASONS',
                      style: SeasonsTextStyles.greeting.copyWith(
                        color: textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: SeasonsSpacing.sm),

                    // Slogan
                    Text(
                      'Live in rhythm with nature',
                      style: SeasonsTextStyles.caption.copyWith(
                        color: textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
