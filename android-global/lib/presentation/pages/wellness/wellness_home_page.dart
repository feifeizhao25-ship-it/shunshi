/// 养生馆首页 — 对齐UI参考 _14
/// TopBar(养生馆+通知) → 搜索栏 → 6宫格导航 → 精选编辑(3张横滑卡片)
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../core/network/api_singleton.dart';

class WellnessHomePage extends StatelessWidget {
  const WellnessHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
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
                    Text(AppLocalizations.of(context).get('wellness_studio'), style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                      color: ShunShiColors.primary,
                      fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
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
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).t('wellness_home_search_wellness_plans_seasonal_recipes'),
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
                      _gridIcon(Icons.health_and_safety, 'Constitution', () => context.push('/constitution')),
                      _gridIcon(Icons.restaurant_menu, 'Seasonal Recipes', () => context.push('/wellness-category/diet')),
                      _gridIcon(Icons.emoji_food_beverage, 'Wellness Teas', () => context.push('/wellness-category/tea')),
                      _gridIcon(Icons.architecture, 'Acupoints', () => context.push('/wellness-category/acupoint')),
                      _gridIcon(Icons.self_improvement, 'Traditional Qigong', () => context.push('/wellness-category/exercise')),
                      _gridIcon(Icons.graphic_eq, 'Sleep Audio', () => context.push('/sleep-sanctuary')),
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
                              const Text('Editor\'s Picks', style: TextStyle(
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
                            onTap: () => context.push('/discover'),
                            child: Row(
                              children: [
                                Text(AppLocalizations.of(context).get('view_all'), style: TextStyle(
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
                        tag: 'Awakening',
                        readTime: '5 min read',
                        title: AppLocalizations.of(context).t('wellness_home_spring_wellness_start_with_liver'),
                        desc: 'During Awakening of Insects, Yang energy stirs. Three key acupoints and food therapy for spring liver care.',
                        likes: '1,208',
                        gradient: [ShunShiColors.apricotLight, ShunShiColors.secondary],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: 'Qigong',
                        readTime: '8 min read',
                        title: AppLocalizations.of(context).t('wellness_home_baduanjin_awaken_your_meridian_energy'),
                        desc: 'Simple traditional exercises. Just 10 minutes daily to relieve neck and shoulder stiffness from sitting.',
                        likes: '3,450',
                        gradient: [ShunShiColors.primaryContainer, ShunShiColors.primaryLight],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        tag: 'Food Therapy',
                        readTime: '4 min read',
                        title: AppLocalizations.of(context).t('wellness_home_five_flavors_five_organs_balance'),
                        desc: 'Sour enters Liver, Spicy enters Lung. Understanding food flavors means understanding your body\'s needs.',
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
