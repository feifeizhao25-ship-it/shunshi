import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/components/components.dart';

/// 重新设计的 Onboarding 页面 — 3张核心价值展示
/// 使用 PageView + dots indicator + SharedPreferences 持久化
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

  static const _pages = <_OnboardingStep>[
    _OnboardingStep(
      icon: Icons.chat_bubble_rounded,
      iconBgGradient: [Color(0xFF4CAF50), Color(0xFF81C784)],
      title: '你的专属养生顾问',
      subtitle: '根据你的体质、节气、今日状态，每天给你最合适的养生建议',
      illustration: _IllustrationType.chat,
    ),
    _OnboardingStep(
      icon: Icons.trending_up_rounded,
      iconBgGradient: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
      title: '记录每天的变化',
      subtitle: '睡眠/心情/运动/饮水，追踪变化，AI帮你找到规律',
      illustration: _IllustrationType.diary,
    ),
    _OnboardingStep(
      icon: Icons.family_restroom_rounded,
      iconBgGradient: [Color(0xFFFF7043), Color(0xFFFFAB91)],
      title: '让全家更健康',
      subtitle: '关心父母体质，共享养生知识，安心守护',
      illustration: _IllustrationType.family,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await OnboardingPage.markCompleted();
    if (mounted) context.go('/home');
  }

  // ── 主题感知辅助 ──

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bg(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.background : ShunshiColors.background;
  Color _primary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.primary : ShunshiColors.primary;
  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textPrimary : ShunshiColors.textPrimary;
  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textSecondary : ShunshiColors.textSecondary;
  Color _textHint(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.textHint : ShunshiColors.textHint;
  Color _surfaceDim(BuildContext context) =>
      _isDark(context) ? ShunshiDarkColors.surfaceDim : ShunshiColors.surfaceDim;

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg(context),
        body: SafeArea(
          child: Column(
            children: [
              // 跳过按钮（最后一页不显示）
              if (!isLast)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(ShunshiSpacing.md),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        '跳过',
                        style: ShunshiTextStyles.caption.copyWith(
                          color: _textHint(context),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: ShunshiSpacing.md),

              // 页面内容
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _buildValuePage(context, _pages[index]),
                ),
              ),

              // 进度指示器
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: ShunshiSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 28 : 8,
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

              // 底部按钮
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ShunshiSpacing.pagePadding,
                  ShunshiSpacing.md,
                  ShunshiSpacing.pagePadding,
                  ShunshiSpacing.xl,
                ),
                child: GentleButton(
                  text: isLast ? '开始体验' : '下一步',
                  isPrimary: true,
                  onPressed: () {
                    if (isLast) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  horizontalPadding: ShunshiSpacing.xl * 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValuePage(BuildContext context, _OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShunshiSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 插图区域
          _buildIllustration(context, step),
          const SizedBox(height: ShunshiSpacing.xxl),

          // 标题
          Text(
            step.title,
            style: ShunshiTextStyles.greeting.copyWith(
              color: _textPrimary(context),
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ShunshiSpacing.md),

          // 副标题
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: ShunshiTextStyles.bodySecondary.copyWith(
              color: _textSecondary(context),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context, _OnboardingStep step) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.iconBgGradient[0].withValues(alpha: 0.12),
            step.iconBgGradient[1].withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: step.iconBgGradient[0].withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: step.iconBgGradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: step.iconBgGradient[0].withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(step.icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          // 模拟界面示意
          _buildMockUI(context, step.illustration),
        ],
      ),
    );
  }

  Widget _buildMockUI(BuildContext context, _IllustrationType type) {
    final primaryColor = _primary(context);
    switch (type) {
      case _IllustrationType.chat:
        return Column(
          children: [
            _mockBubble('你好，顺时', isUser: true, color: primaryColor),
            const SizedBox(height: 8),
            _mockBubble('清明时节，推荐疏肝理气…', isUser: false, color: primaryColor),
          ],
        );
      case _IllustrationType.diary:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mockMiniCard('😴', '睡眠', '7.5h', primaryColor),
            const SizedBox(width: 8),
            _mockMiniCard('😊', '心情', '良好', primaryColor),
            const SizedBox(width: 8),
            _mockMiniCard('💧', '饮水', '6杯', primaryColor),
          ],
        );
      case _IllustrationType.family:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mockAvatar('🧑', primaryColor),
            const SizedBox(width: 6),
            _mockAvatar('👩', primaryColor),
            const SizedBox(width: 6),
            _mockAvatar('👴', primaryColor),
            const SizedBox(width: 6),
            _mockAvatar('👵', primaryColor),
          ],
        );
    }
  }

  Widget _mockBubble(String text, {required bool isUser, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUser ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: isUser ? color : Colors.grey[700]),
      ),
    );
  }

  Widget _mockMiniCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _mockAvatar(String emoji, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    );
  }
}

enum _IllustrationType { chat, diary, family }

class _OnboardingStep {
  final IconData icon;
  final List<Color> iconBgGradient;
  final String title;
  final String subtitle;
  final _IllustrationType illustration;
  const _OnboardingStep({
    required this.icon,
    required this.iconBgGradient,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}
