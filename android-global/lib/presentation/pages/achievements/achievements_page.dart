import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

/// Achievements页
///
/// 参考: _6/code.html — Achievements + 进度统计 + 徽章收集
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACHIEVEMENTS',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.sansFamily,
                                fontSize: 13,
                                color: ShunShiColors.textTertiary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Achievements',
                              style: TextStyle(
                                fontFamily: ShunShiTypography.serifFamily,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: ShunShiColors.primary,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ShunShiColors.surfaceContainerLow,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: ShunShiColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track every step of your wellness journey',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 14,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _StatCard('Streak', '42', ' days', Icons.local_fire_department),
                    const SizedBox(width: 12),
                    _StatCard('Practices', '28', '', Icons.self_improvement),
                    const SizedBox(width: 12),
                    _StatCard('Points', '2560', '', Icons.stars),
                  ],
                ),
              ),
            ),

            // ── Progress Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Progress',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressCard(
                      title: AppLocalizations.of(context).t('achievements_100day_wellness_challenge'),
                      current: 42,
                      total: 100,
                      icon: Icons.emoji_events,
                    ),
                    const SizedBox(height: 12),
                    _ProgressCard(
                      title: AppLocalizations.of(context).t('achievements_complete_movement_set'),
                      current: 3,
                      total: 8,
                      icon: Icons.self_improvement,
                    ),
                    const SizedBox(height: 12),
                    _ProgressCard(
                      title: AppLocalizations.of(context).t('achievements_24_solar_terms_wellness'),
                      current: 6,
                      total: 24,
                      icon: Icons.filter_vintage,
                    ),
                  ],
                ),
              ),
            ),

            // ── Badges Grid ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Badges Earned',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _BadgeCard(icon: '🌅', label: AppLocalizations.of(context).t('achievements_early_riser'), unlocked: true),
                        _BadgeCard(icon: '🧘', label: AppLocalizations.of(context).t('achievements_practice_starter'), unlocked: true),
                        _BadgeCard(icon: '🍵', label: AppLocalizations.of(context).t('achievements_food_therapy_expert'), unlocked: true),
                        _BadgeCard(icon: '🏔️', label: AppLocalizations.of(context).t('achievements_100day_commitment'), unlocked: false),
                        _BadgeCard(icon: '🌿', label: AppLocalizations.of(context).t('achievements_solar_term_master'), unlocked: false),
                        _BadgeCard(icon: '⭐', label: AppLocalizations.of(context).t('achievements_community_star'), unlocked: false),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _StatCard(this.label, this.value, this.unit, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: ShunShiColors.primary, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ShunShiColors.primary,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 11,
                color: ShunShiColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final int current;
  final int total;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.current,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: ShunShiColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$current / $total',
                style: TextStyle(
                  fontFamily: ShunShiTypography.sansFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ShunShiColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: ShunShiColors.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(ShunShiColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool unlocked;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: ShunShiColors.goldLight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 32,
              color: unlocked ? null : ShunShiColors.textDisabled,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              fontSize: 12,
              color: unlocked ? ShunShiColors.textPrimary : ShunShiColors.textDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
