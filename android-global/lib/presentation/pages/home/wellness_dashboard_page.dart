/// 养生仪表盘页 — 对齐UI参考 _12
/// TopBar(昵称+时辰+通知) → 节气Hero → 时令仪式横滑 → 今日进度 → 为您推荐 + 今日阅读 → 疗愈之声 + 每日名言
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

class WellnessDashboardPage extends StatelessWidget {
  const WellnessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── TopAppBar ──
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ShunShiColors.surfaceContainerLow,
                        border: Border.all(color: ShunShiColors.borderGhost),
                      ),
                      child: const Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context).t('home_good_morning_seasons_friend'), style: ShunShiTypography.headlineSmall.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                          )),
                          const SizedBox(height: 2),
                          Text(_currentShiChenLabel(), style: ShunShiTypography.caption.copyWith(
                            fontSize: 11, letterSpacing: 1.5, color: ShunShiColors.secondary,
                          )),
                        ],
                      ),
                    ),
                    // Notification bell
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20, color: ShunShiColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Solar Term Hero ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ShunShiColors.primary.withValues(alpha: 0.06), ShunShiColors.primaryContainer.withValues(alpha: 0.12)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ShunShiColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(AppLocalizations.of(context).t('notification_solar'), style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: ShunShiColors.primary,
                        letterSpacing: 0.5,
                      )),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(AppLocalizations.of(context).t('st_chunfen'), style: TextStyle(
                      fontSize: 42, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      height: 1.1, letterSpacing: -1, fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const Text('Spring Equinox', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily, fontStyle: FontStyle.italic,
                    )),
                    const SizedBox(height: 12),
                    // Description
                    const Text('Yin and Yang in balance, all things revive. Feel the gentle warmth of the awakening earth.', style: TextStyle(
                      fontSize: 16, color: ShunShiColors.secondary, height: 1.6,
                    )),
                    const SizedBox(height: 16),
                    // Countdown
                    Row(
                      children: [
                        Container(width: 48, height: 1, color: ShunShiColors.textTertiary),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context).t('home_12_days_until_qingming'), style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: ShunShiColors.textTertiary, letterSpacing: 1,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 时令仪式 (Horizontal Scroll) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context).t('home_seasonal_rituals'), style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                    letterSpacing: -0.5, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  GestureDetector(
                    onTap: () {},
                    child: Text(AppLocalizations.of(context).t('view_all'), style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: ShunShiColors.secondary,
                    )),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _RitualCard(
                    icon: Icons.restaurant,
                    title: AppLocalizations.of(context).t('home_dietary_wisdom'),
                    desc: 'Eat more bean sprouts and chives to nourish Liver Qi during this energy transition.',
                    cta: 'Recipes',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.emoji_food_beverage,
                    title: AppLocalizations.of(context).t('home_seasonal_tea'),
                    desc: 'Jasmine tea soothes emotions and disperses stagnant Qi lingering from winter.',
                    cta: 'Shop',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.self_improvement,
                    title: AppLocalizations.of(context).t('home_meridian_clearing'),
                    desc: 'Press Taichong point for 5 minutes to release emotional tension.',
                    cta: 'Tutorial',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.directions_walk,
                    title: AppLocalizations.of(context).t('home_movement_practice'),
                    desc: 'Morning walks in sync with the sun\'s rhythm, breathing in the fresh and releasing the stale.',
                    cta: 'Log',
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 今日进度 (Daily Check-in) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: ShunShiColors.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text('Today\'s Progress', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2,
                      color: ShunShiColors.primary,
                    )),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context).t('home_3_habits_completed_today'), style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      letterSpacing: -0.5, fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context).t('home_consistency_bridges_intentions_and_health_kee'), style: TextStyle(
                      fontSize: 14, color: ShunShiColors.secondary,
                    )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 160, height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShunShiColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(AppLocalizations.of(context).t('home_check_in'), style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 为您推荐 + 今日阅读 (Bento Grid) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // For You
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).t('home_recommended_for_you'), style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                          fontFamily: ShunShiTypography.serifFamily,
                        )),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: ShunShiColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: ShunShiShadows.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image placeholder
                                Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    gradient: LinearGradient(
                                      colors: [ShunShiColors.primaryContainer, ShunShiColors.primaryLight],
                                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.restaurant_menu, size: 48, color: Colors.white54),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: ShunShiColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(AppLocalizations.of(context).t('food_recipe'), style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w700,
                                          color: ShunShiColors.primary, letterSpacing: 0.5,
                                        )),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(AppLocalizations.of(context).t('home_spring_vegetable_porridge'), style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700,
                                        fontFamily: ShunShiTypography.serifFamily,
                                        color: ShunShiColors.textPrimary,
                                      )),
                                      const SizedBox(height: 4),
                                      const Text('A light, warming meal designed for gentle detox after winter.', style: TextStyle(
                                        fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5,
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Daily Read
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Reading', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                          fontFamily: ShunShiTypography.serifFamily,
                        )),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ShunShiColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context).t('home_philosophy_balance'), style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: ShunShiColors.secondary, letterSpacing: 1.5,
                              )),
                              const SizedBox(height: 12),
                              const Text('Finding Balance in the New Season: Spring Equinox Living Guide', style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w400,
                                fontFamily: ShunShiTypography.serifFamily,
                                color: ShunShiColors.textPrimary, height: 1.3,
                              )),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(AppLocalizations.of(context).t('home_8_min_read'), style: TextStyle(
                                    fontSize: 12, color: ShunShiColors.textTertiary,
                                  )),
                                  Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(color: ShunShiColors.textTertiary, shape: BoxShape.circle),
                                  ),
                                  Text(AppLocalizations.of(context).t('home_traditional_wellness_arts'), style: TextStyle(
                                    fontSize: 12, color: ShunShiColors.textTertiary,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: ShunShiColors.primary.withValues(alpha: 0.2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(AppLocalizations.of(context).t('home_read_more'), style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                                  color: ShunShiColors.primary,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── 疗愈之声 + 每日名言 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nature Audio Player (2/3)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: ShunShiGlass.glassmorphism(
                        tintColor: ShunShiColors.surfaceContainerLow,
                      ),
                      child: Row(
                        children: [
                          // Cover
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [ShunShiColors.primaryContainer, ShunShiColors.primary],
                              ),
                            ),
                            child: const Icon(Icons.forest, size: 36, color: Colors.white54),
                          ),
                          const SizedBox(width: 20),
                          // Info + Controls
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).t('home_healing_sounds'), style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: ShunShiColors.secondary, letterSpacing: 1.5,
                                )),
                                const SizedBox(height: 4),
                                Text(AppLocalizations.of(context).t('home_mountain_streams_bamboo'), style: TextStyle(
                                  fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                                  color: ShunShiColors.primary,
                                )),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // Play button
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: ShunShiColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow, size: 22, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    // Progress bar
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: ShunShiColors.textTertiary.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: 0.27,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: ShunShiColors.primary,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('12:04 / 45:00', style: TextStyle(
                                            fontSize: 11, color: ShunShiColors.secondary,
                                          )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Daily Quote (1/3)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_quote, size: 28,
                            color: ShunShiColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text('"Nourish Yang in spring and summer,\nNourish Yin in autumn and winter."', textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
                              fontStyle: FontStyle.italic, color: ShunShiColors.primary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context).t('home_huangdi_neijing'), style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: ShunShiColors.secondary, letterSpacing: 2,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  String _currentShiChenLabel() {
    final hour = DateTime.now().hour;
    const data = [
      (0, 'Zi · Gallbladder'), (1, 'Chou · Liver'), (3, 'Yin · Lung'),
      (5, 'Mao · Large Intestine'), (7, 'Chen · Stomach'), (9, 'Si · Spleen'),
      (11, 'Wu · Heart'), (13, 'Wei · Small Intestine'), (15, 'Shen · Bladder'),
      (17, 'You · Kidney'), (19, 'Xu · Pericardium'), (21, 'Hai · Triple Burner'),
      (23, 'Zi · Gallbladder'),
    ];
    for (final (h, label) in data) {
      if (hour < h) return data[data.indexOf((h, label)) - 1].$2;
    }
    return 'Hai · Triple Burner';
  }
}

// ── 时令仪式横滑卡片 ──
class _RitualCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String cta;

  const _RitualCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShunShiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: ShunShiColors.primary),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500,
                fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(
                fontSize: 13, color: ShunShiColors.textSecondary,
                height: 1.6,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(cta, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: ShunShiColors.primary, letterSpacing: 1,
              )),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: ShunShiColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
