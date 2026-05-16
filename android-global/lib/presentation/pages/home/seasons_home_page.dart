import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/typography.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class SeasonsHomePage extends StatefulWidget {
  const SeasonsHomePage({super.key});

  @override
  State<SeasonsHomePage> createState() => _SeasonsHomePageState();
}

class _SeasonsHomePageState extends State<SeasonsHomePage> {
  String _userName = '';
  bool _isLoading = true;

  // Brand colors per design spec
  static const Color _inkGreen = Color(0xFF144227);
  static const Color _warmCream = Color(0xFFFDF9F4);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_completed');
    if (onboarded != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/onboarding');
      });
      return;
    }
    final name = prefs.getString('user_name') ?? '';
    if (mounted) {
      setState(() {
        _userName = name;
        _isLoading = false;
      });
    }
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _currentSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  IconData get _seasonIcon {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Icons.local_florist;
    if (month >= 6 && month <= 8) return Icons.wb_sunny;
    if (month >= 9 && month <= 11) return Icons.eco;
    return Icons.ac_unit;
  }

  String get _seasonRitual {
    switch (_currentSeason) {
      case 'Spring':
        return 'Open a window for 5 minutes. Let the fresh air in.';
      case 'Summer':
        return 'Step outside briefly. Feel the warmth on your skin.';
      case 'Autumn':
        return 'Wrap your hands around something warm. Pause.';
      case 'Winter':
        return 'Light a candle. Sit quietly for a moment.';
      default:
        return 'Take a slow breath. Be here.';
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('home_coming_soon')),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _inkGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _warmCream,
        body: SafeArea(child: _buildSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: _warmCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _greeting(),
                    const SizedBox(height: 24),
                    _dailyInsightCard(),
                    const SizedBox(height: 24),
                    ..._gentleSuggestionCards(),
                    const SizedBox(height: 20),
                    _chatEntry(),
                    const SizedBox(height: 20),
                    _seasonCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. Greeting ───

  Widget _greeting() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greetingText,
            style: SeasonsTypography.h2Light.copyWith(
              color: _inkGreen,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (_userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _userName,
                style: SeasonsTypography.bodyLight.copyWith(
                  color: _inkGreen.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 2. Daily Insight ───

  Widget _dailyInsightCard() {
    return GestureDetector(
      onTap: _showComingSoon,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _inkGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _inkGreen.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.wb_twilight,
              color: _inkGreen.withValues(alpha: 0.5),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your body may need a slower evening today',
                    style: SeasonsTypography.bodyLight.copyWith(
                      color: _inkGreen,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily insight',
                    style: SeasonsTypography.captionLight.copyWith(
                      color: _inkGreen.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. Gentle Suggestions ───

  List<Widget> _gentleSuggestionCards() {
    final suggestions = [
      _Suggestion(
        icon: Icons.air,
        title: AppLocalizations.of(context).t('home_take_three_slower_breaths'),
        description: '1 min',
      ),
      _Suggestion(
        icon: Icons.coffee_outlined,
        title: AppLocalizations.of(context).t('home_make_a_warm_drink_tonight'),
        description: '3 min',
      ),
      _Suggestion(
        icon: Icons.light_mode_outlined,
        title: AppLocalizations.of(context).t('home_dim_the_lights_20_minutes_earlier'),
        description: '5 min',
      ),
    ];

    return [
      Text(
        'Gentle suggestions',
        style: SeasonsTypography.h4Light.copyWith(
          color: _inkGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      ...suggestions.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _showComingSoon,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _inkGreen.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _inkGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.icon, size: 20, color: _inkGreen.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: SeasonsTypography.bodyLight.copyWith(
                          color: _inkGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        s.description,
                        style: SeasonsTypography.captionLight.copyWith(
                          color: _inkGreen.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _inkGreen.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      )),
    ];
  }

  // ─── 4. AI Chat Entry (Frosted Glass) ───

  Widget _chatEntry() {
    return GestureDetector(
      onTap: () => context.push('/chat'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _inkGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _inkGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _inkGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: _inkGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Talk to Seasons',
                        style: SeasonsTypography.bodyLight.copyWith(
                          color: _inkGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your AI companion for seasonal living',
                        style: SeasonsTypography.captionLight.copyWith(
                          color: _inkGreen.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _inkGreen.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 5. Season Card ───

  Widget _seasonCard() {
    return GestureDetector(
      onTap: () => context.push('/seasons'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _inkGreen,
              _inkGreen.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_seasonIcon, color: Colors.white.withValues(alpha: 0.9), size: 24),
                const SizedBox(width: 10),
                Text(
                  _currentSeason,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _seasonRitual,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Explore seasonal rituals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton Loading ───

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _skeletonBox(height: 28, width: 180),
          const SizedBox(height: 24),
          _skeletonBox(height: 80),
          const SizedBox(height: 24),
          _skeletonBox(height: 18, width: 140),
          const SizedBox(height: 12),
          _skeletonBox(height: 56),
          const SizedBox(height: 10),
          _skeletonBox(height: 56),
          const SizedBox(height: 10),
          _skeletonBox(height: 56),
          const SizedBox(height: 20),
          _skeletonBox(height: 80),
          const SizedBox(height: 20),
          _skeletonBox(height: 140),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _skeletonBox({double height = 20, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _inkGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String title;
  final String description;

  const _Suggestion({
    required this.icon,
    required this.title,
    required this.description,
  });
}
