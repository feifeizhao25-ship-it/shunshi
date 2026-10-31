/// 养生馆首页 — 对齐UI参考 _14
/// TopBar(养生馆+通知) → 搜索栏 → 6宫格导航 → 精选编辑(3张横滑卡片)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class WellnessHomePage extends StatelessWidget {
  const WellnessHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
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
                        border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.person, size: 20, color: ShunShiColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Text('Wellness hall', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                      color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.notifications_outlined, size: 22, color: ShunShiColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: ShunShiColors.surfaceContainerLow, margin: const EdgeInsets.symmetric(horizontal: 20)),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  // ── 搜索栏 ──
                  Container(
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search plans, seasonal recipes...',
                        hintStyle: TextStyle(color: ShunShiColors.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: ShunShiColors.textTertiary, size: 22),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 6宫格导航 ──
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: [
                      _gridIcon(Icons.health_and_safety, 'Constitution care', () => context.push('/wellness/constitution')),
                      _gridIcon(Icons.restaurant_menu, 'Seasonal recipes', () => context.push('/wellness/food_therapy')),
                      _gridIcon(Icons.emoji_food_beverage, 'Wellness teas', () => context.push('/wellness/tea')),
                      _gridIcon(Icons.architecture, 'Meridians & acupoints', () => context.push('/wellness/acupressure')),
                      _gridIcon(Icons.self_improvement, 'Traditional practices', () => context.push('/wellness/exercise')),
                      _gridIcon(Icons.graphic_eq, 'Sleep audio', () => context.push('/wellness/sleep')),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── 精选编辑 ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 48, height: 4,
                                decoration: BoxDecoration(
                                  color: ShunShiColors.apricot, borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Editor\'s picks', style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w700,
                                fontFamily: ShunShiTypography.serifFamily,
                                color: ShunShiColors.primary, letterSpacing: -0.5,
                              )),
                              Text("Editor's Choice", style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: ShunShiColors.secondary, letterSpacing: 1.5,
                              )),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: const [
                                Text('View all', style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.primary,
                                )),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right, size: 18, color: ShunShiColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 Editor Cards
                      _editorCard(
                        tag: 'Awakening of Insects',
                        readTime: '5 min read',
                        title: 'Spring wellness: start by caring for the liver',
                        desc: 'At Awakening of Insects, yang energy begins to stir. This editor\'s pick brings three key acupoints and food-therapy ideas for protecting the liver in spring.',
                        likes: '1,208',
                        gradient: [ShunShiColors.apricotLight, ShunShiColors.secondary],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: 'Practice',
                        readTime: '8 min read',
                        title: 'Baduanjin: awaken the body\'s meridian energy',
                        desc: 'A simple traditional practice — ten minutes a day to ease neck and shoulder stiffness from sitting.',
                        likes: '3,450',
                        gradient: [ShunShiColors.primaryContainer, ShunShiColors.primaryLight],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: 'Food',
                        readTime: '4 min read',
                        title: 'The five flavours and the five organs: balance your daily meals',
                        desc: 'Sour enters the liver, pungent the lungs. Understanding a food\'s flavour is understanding what your body needs.',
                        likes: '892',
                        gradient: [ShunShiColors.apricotLight, ShunShiColors.apricot],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShunShiColors.surfaceContainerLowest,
              border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.1)),
              boxShadow: ShunShiShadows.sm,
            ),
            child: Icon(icon, size: 28, color: ShunShiColors.primary),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: ShunShiColors.textPrimary,
          )),
        ],
      ),
    );
  }

  Widget _editorCard({
    required String tag,
    required String readTime,
    required String title,
    required String desc,
    required String likes,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
          border: Border.all(color: ShunShiColors.textTertiary.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Left image placeholder
            Container(
              width: 110,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(Icons.article, size: 32, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ShunShiColors.apricotLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag, style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: ShunShiColors.textPrimary,
                              )),
                            ),
                            const SizedBox(width: 8),
                            Text(readTime, style: TextStyle(
                              fontSize: 10, color: ShunShiColors.textTertiary,
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: ShunShiColors.textPrimary, height: 1.3,
                        )),
                        const SizedBox(height: 6),
                        Text(desc, style: TextStyle(
                          fontSize: 12, color: ShunShiColors.textSecondary,
                          height: 1.5,
                        ), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: ShunShiColors.secondary),
                        const SizedBox(width: 4),
                        Text('$likes saved', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: ShunShiColors.secondary,
                        )),
                      ],
                    ),
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
