import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';

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

    // 呼吸缩放 0.95 → 1.05（品牌特色）
    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.forward();

    // 1.5秒后跳转
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
    final primary = isDark ? ShunshiDarkColors.primary : ShunshiColors.primary;
    final primaryLight =
        isDark ? ShunshiDarkColors.primaryLight : ShunshiColors.primaryLight;
    final textPrimary =
        isDark ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;
    final textSecondary =
        isDark ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;
    final bg = isDark ? ShunshiDarkColors.background : ShunshiColors.background;

    return PopScope(
      canPop: false, // Splash 页面按返回键直接退出 app，不黑屏
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 可以退出 app
        }
      },
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
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primary, primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: ShunshiSpacing.lg),

                    // 品牌名
                    Text(
                      '顺时',
                      style: ShunshiTextStyles.greeting.copyWith(
                        color: textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: ShunshiSpacing.sm),

                    // Slogan
                    Text(
                      '顺时而养 · 自然而安',
                      style: ShunshiTextStyles.caption.copyWith(
                        color: textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
