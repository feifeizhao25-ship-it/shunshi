/// 养生仪表盘页 — 对齐UI参考 _12
/// TopBar(昵称+时辰+通知) → 节气Hero → 时令仪式横滑 → 今日进度 → 为您推荐 + 今日阅读 → 疗愈之声 + 每日名言
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class WellnessDashboardPage extends StatelessWidget {
  const WellnessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
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
                          Text('早安，顺时小伙伴', style: ShunShiTypography.headlineSmall.copyWith(
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
                      child: const Text('节气提醒', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: ShunShiColors.primary,
                        letterSpacing: 0.5,
                      )),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    const Text('春分', style: TextStyle(
                      fontSize: 42, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      height: 1.1, letterSpacing: -1, fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const Text('Spring Equinox', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily, fontStyle: FontStyle.italic,
                    )),
                    const SizedBox(height: 12),
                    // Description
                    const Text('阴阳平衡，万物复苏。感受大地觉醒时的温润暖意。', style: TextStyle(
                      fontSize: 16, color: ShunShiColors.secondary, height: 1.6,
                    )),
                    const SizedBox(height: 16),
                    // Countdown
                    Row(
                      children: [
                        Container(width: 48, height: 1, color: ShunShiColors.textTertiary),
                        const SizedBox(width: 12),
                        const Text('距离 清明 还有 12 天', style: TextStyle(
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
                  const Text('时令仪式', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                    letterSpacing: -0.5, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('查看全部', style: TextStyle(
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
                children: const [
                  _RitualCard(
                    icon: Icons.restaurant,
                    title: '饮食之道',
                    desc: '多食豆芽与韭菜，在此能量转换之际护养肝气。',
                    cta: '食谱',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.emoji_food_beverage,
                    title: '时令茶饮',
                    desc: '茉莉花茶可舒缓情绪，化解冬日留存的陈郁之气。',
                    cta: '购买',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.self_improvement,
                    title: '经络通导',
                    desc: '按揉太冲穴 5 分钟，帮助宣泄情绪压力。',
                    cta: '教程',
                  ),
                  SizedBox(width: 16),
                  _RitualCard(
                    icon: Icons.directions_walk,
                    title: '功法运动',
                    desc: '清晨漫步，顺应日光节律，吐故纳新。',
                    cta: '记录',
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
                    const Text('今日进度', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2,
                      color: ShunShiColors.primary,
                    )),
                    const SizedBox(height: 8),
                    const Text('今日已完成 3 项习惯', style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w300, color: ShunShiColors.primary,
                      letterSpacing: -0.5, fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const SizedBox(height: 8),
                    const Text('持之以恒是连接心愿与健康的桥梁。继续加油。', style: TextStyle(
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
                        child: const Text('打卡', style: TextStyle(
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
                        const Text('为您推荐', style: TextStyle(
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
                                        child: const Text('食谱', style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w700,
                                          color: ShunShiColors.primary, letterSpacing: 0.5,
                                        )),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('春季鲜蔬粥', style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700,
                                        fontFamily: ShunShiTypography.serifFamily,
                                        color: ShunShiColors.textPrimary,
                                      )),
                                      const SizedBox(height: 4),
                                      const Text('清淡温润的一餐，旨在为冬日后的身体进行轻盈排毒。', style: TextStyle(
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
                        const Text('今日阅读', style: TextStyle(
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
                              const Text('哲学与平衡', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: ShunShiColors.secondary, letterSpacing: 1.5,
                              )),
                              const SizedBox(height: 12),
                              const Text('寻回新时节的平衡：春分生活指南', style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w400,
                                fontFamily: ShunShiTypography.serifFamily,
                                color: ShunShiColors.textPrimary, height: 1.3,
                              )),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text('阅读需8分钟', style: TextStyle(
                                    fontSize: 12, color: ShunShiColors.textTertiary,
                                  )),
                                  Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(color: ShunShiColors.textTertiary, shape: BoxShape.circle),
                                  ),
                                  Text('传统养生艺术', style: TextStyle(
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
                                child: const Text('阅读全文', style: TextStyle(
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
                                const Text('疗愈之声', style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: ShunShiColors.secondary, letterSpacing: 1.5,
                                )),
                                const SizedBox(height: 4),
                                const Text('山涧流泉与墨竹', style: TextStyle(
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
                          const Text('"春夏养阳，\n秋冬养阴。"', textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
                              fontStyle: FontStyle.italic, color: ShunShiColors.primary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('《黄帝内经》', style: TextStyle(
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
      (0, '子时 · 胆经当令'), (1, '丑时 · 肝经当令'), (3, '寅时 · 肺经当令'),
      (5, '卯时 · 大肠经当令'), (7, '辰时 · 胃经当令'), (9, '巳时 · 脾经当令'),
      (11, '午时 · 心经当令'), (13, '未时 · 小肠经当令'), (15, '申时 · 膀胱经当令'),
      (17, '酉时 · 肾经当令'), (19, '戌时 · 心包经当令'), (21, '亥时 · 三焦经当令'),
      (23, '子时 · 胆经当令'),
    ];
    for (final (h, label) in data) {
      if (hour < h) return data[data.indexOf((h, label)) - 1].$2;
    }
    return '亥时 · 三焦经当令';
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
