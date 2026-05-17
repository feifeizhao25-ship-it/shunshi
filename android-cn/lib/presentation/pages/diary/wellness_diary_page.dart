/// 养生日记页 — 对齐UI参考 _13
/// TopBar(昵称+通知) → Header(日期+节气+标题+引言) → 睡眠质量(入睡/醒来) → 情绪图谱(4种) → 每日仪式(饮茶/冥想/运动) → AI洞察(深绿卡片+shimmer)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class WellnessDiaryPage extends StatefulWidget {
  const WellnessDiaryPage({super.key});

  @override
  State<WellnessDiaryPage> createState() => _WellnessDiaryPageState();
}

class _WellnessDiaryPageState extends State<WellnessDiaryPage>
    with SingleTickerProviderStateMixin {
  // Mood selection: 0=开心, 1=平和, 2=疲劳, 3=忧郁
  int _selectedMood = 1;
  // Habit completion: 饮茶/冥想/运动
  final List<bool> _habits = [true, false, false];
  // Shimmer animation
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── TopAppBar ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ShunShiColors.surfaceVariant,
                      ),
                      child: const Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('早安, 顺时小伙伴', style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                        color: ShunShiColors.primary,
                        fontFamily: ShunShiTypography.serifFamily,
                      )),
                    ),
                    GestureDetector(
                      onTap: () { context.go('/notifications'); },
                      child: const Icon(Icons.notifications_outlined, size: 22, color: ShunShiColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Text('$month月$day日 \u2022 谷雨', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: ShunShiColors.secondary, letterSpacing: 1.5,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 1, color: ShunShiColors.textTertiary.withValues(alpha: 0.15))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('养生日记 今日记录', style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w400,
                    color: ShunShiColors.primary, height: 1.2,
                    fontFamily: ShunShiTypography.serifFamily,
                  )),
                  const SizedBox(height: 4),
                  const Text('"顺应四时节气，静听身体韵律。"', style: TextStyle(
                    fontSize: 14, color: ShunShiColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  )),
                  const SizedBox(height: 40),

                  // ── 睡眠质量 ──
                  _sectionHeader(Icons.bedtime, '睡眠质量'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _sleepCard('入睡时间', '22:45', 'PM')),
                      const SizedBox(width: 16),
                      Expanded(child: _sleepCard('醒来时间', '06:30', 'AM')),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── 情绪图谱 ──
                  _sectionHeader(Icons.self_improvement, '情绪图谱'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _moodButton(0, Icons.sentiment_satisfied, '开心'),
                        _moodButton(1, Icons.spa, '平和'),
                        _moodButton(2, Icons.bed, '疲劳'),
                        _moodButton(3, Icons.cloud, '忧郁'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── 每日仪式 ──
                  _sectionHeader(Icons.done_all, '每日仪式'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _habitCard(0, Icons.emoji_food_beverage, '饮茶')),
                      const SizedBox(width: 12),
                      Expanded(child: _habitCard(1, Icons.air, '冥想')),
                      const SizedBox(width: 12),
                      Expanded(child: _habitCard(2, Icons.directions_walk, '运动')),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── AI 洞察 ──
                  _buildAiInsight(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 22, color: ShunShiColors.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w400,
          fontFamily: ShunShiTypography.serifFamily,
          color: ShunShiColors.textPrimary,
        )),
      ],
    );
  }

  Widget _sleepCard(String label, String time, String period) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ShunShiColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: ShunShiColors.textSecondary, letterSpacing: 1.5,
          )),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w400,
                fontFamily: ShunShiTypography.serifFamily,
                color: ShunShiColors.primary,
              )),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(period, style: TextStyle(
                  fontSize: 13, color: ShunShiColors.textSecondary,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moodButton(int index, IconData icon, String label) {
    final selected = _selectedMood == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = index),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShunShiColors.surfaceContainerLowest,
              border: selected
                  ? Border.all(color: ShunShiColors.primary, width: 2)
                  : Border.all(color: Colors.transparent),
            ),
            child: Icon(icon, size: 28,
              color: selected ? ShunShiColors.primary : ShunShiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(
            fontSize: 11,
            color: selected ? ShunShiColors.primary : ShunShiColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          )),
        ],
      ),
    );
  }

  Widget _habitCard(int index, IconData icon, String label) {
    final checked = _habits[index];
    return GestureDetector(
      onTap: () => setState(() => _habits[index] = !_habits[index]),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 32, color: ShunShiColors.secondary),
                // Checkbox indicator
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: checked ? ShunShiColors.primary : ShunShiColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? Center(child: Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            color: ShunShiColors.primary, shape: BoxShape.circle,
                          ),
                        ))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(label, style: TextStyle(
              fontSize: 17, fontFamily: ShunShiTypography.serifFamily,
              color: checked ? ShunShiColors.primary : ShunShiColors.textPrimary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsight() {
    return Container(
      decoration: BoxDecoration(
        color: ShunShiColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ShunShiColors.primary.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _pulsingIcon(),
                    const SizedBox(width: 8),
                    const Text('AI 洞察', style: TextStyle(
                      fontSize: 18, fontFamily: ShunShiTypography.serifFamily,
                      color: Colors.white,
                    )),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('生成中...', style: TextStyle(
                    fontSize: 9, color: Colors.white70, letterSpacing: 1.5,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Shimmer lines
            _shimmerLine(0.75),
            const SizedBox(height: 12),
            _shimmerLine(0.50),
            const SizedBox(height: 20),
            // Insight text
            Text(
              '"你在\'谷雨\'期间的作息显示体内略有湿气。我正在为你调配一款完美的午后茶饮以协调身心..."',
              style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic, height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulsingIcon() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final opacity = 0.5 + 0.5 * (_shimmerController.value % 1);
        return Icon(Icons.smart_toy, size: 22, color: Colors.white.withValues(alpha: opacity));
      },
    );
  }

  Widget _shimmerLine(double widthFraction) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final dx = (2.0 * _shimmerController.value - 1.0);
            return FractionalTranslation(
              translation: Offset(dx, 0),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
