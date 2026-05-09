/// 成就勋章页 — 参考UI _6
/// 记录每一次健康修行
///
/// 结构:
/// 1. 积分/等级概览
/// 2. 进度条（下一级）
/// 3. 已获荣光（已解锁勋章网格）
/// 4. 待登峰造极（未解锁勋章）
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class AchievementBadge {
  final String icon;
  final String title;
  final String subtitle;
  final bool unlocked;
  final Color? color;
  const AchievementBadge({
    required this.icon, required this.title,
    required this.subtitle, this.unlocked = false, this.color,
  });
}

const _badges = [
  AchievementBadge(icon: '🌅', title: '早起达人', subtitle: '10天达成', unlocked: true, color: Color(0xFFF59E0B)),
  AchievementBadge(icon: '🌿', title: '节气使者', subtitle: '顺时而养', unlocked: true, color: Color(0xFF22C55E)),
  AchievementBadge(icon: '⚡', title: '养生先锋', subtitle: '初窥门径', unlocked: true, color: Color(0xFF3B82F6)),
  AchievementBadge(icon: '📚', title: '百日功成', subtitle: '进阶解锁'),
  AchievementBadge(icon: '👨‍👩‍👧', title: '家庭守护', subtitle: '待解锁'),
  AchievementBadge(icon: '🧘', title: '功法宗师', subtitle: '待解锁'),
  AchievementBadge(icon: '🍵', title: '茶道品鉴', subtitle: '待解锁'),
  AchievementBadge(icon: '🏆', title: '全能养生', subtitle: '待解锁'),
];

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = _badges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('成就勋章', style: ShunShiTypography.headlineSmall),
        backgroundColor: ShunShiColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Subtitle
            Text(
              '记录您的每一次健康修行',
              style: TextStyle(
                fontSize: 14, color: ShunShiColors.textSecondary,
                fontFamily: ShunShiTypography.sansFamily,
              ),
            ),
            const SizedBox(height: 24),

            // ── 积分概览 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunShiColors.primary.withValues(alpha: 0.12),
                    ShunShiColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '2560',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w700,
                      color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '积分',
                    style: TextStyle(
                      fontSize: 14, color: ShunShiColors.textSecondary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '当前等级：入门修行者',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '下一级：中级养生者',
                    style: TextStyle(
                      fontSize: 13, color: ShunShiColors.textSecondary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '距离升级还需 440 积分',
                    style: TextStyle(
                      fontSize: 12, color: ShunShiColors.textTertiary,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Stack(children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: ShunShiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 2560 / 3000,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: ShunShiColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── 已获荣光 ──
            Row(children: [
              Text('已获荣光', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
              )),
              const SizedBox(width: 8),
              Text('$unlocked / ${_badges.length} 已解锁', style: TextStyle(
                fontSize: 13, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
              )),
            ]),
            const SizedBox(height: 16),
            // Badge grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: _badges.map((badge) => _badgeCard(badge)).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _badgeCard(AchievementBadge badge) {
    final isUnlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? ShunShiColors.surfaceContainerLowest
            : ShunShiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.icon,
            style: TextStyle(
              fontSize: 28,
              color: isUnlocked ? null : ShunShiColors.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: isUnlocked ? ShunShiColors.textPrimary : ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isUnlocked ? (badge.color ?? ShunShiColors.primary) : ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily,
            ),
          ),
        ],
      ),
    );
  }
}
