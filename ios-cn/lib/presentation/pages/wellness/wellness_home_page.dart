/// 养生馆首页 — 对齐UI参考 _14
/// TopBar(养生馆+通知) → 搜索栏 → 6宫格导航 → 精选编辑(3张横滑卡片)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/solar_term/solar_term_table.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';
import '../library/shunshi_reference_library.dart';

class WellnessHomePage extends StatelessWidget {
  const WellnessHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? ShunShiColors.darkBackground : AppColors.background(context);
    final title = isDark ? ShunShiColors.darkTextPrimary : AppColors.textPrimary(context);
    final accent = isDark ? ShunShiColors.darkPrimary : AppColors.primary(context);
    final muted = isDark ? ShunShiColors.darkTextSecondary : AppColors.textTertiary(context);
    final field = isDark ? ShunShiColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow(context);
    return Scaffold(
      backgroundColor: background,
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
                        border: Border.all(color: AppColors.textTertiary(context).withValues(alpha: 0.1)),
                      ),
                      child: Icon(Icons.person, size: 20, color: AppColors.textSecondary(context)),
                    ),
                    const SizedBox(width: 12),
                    Text('养生馆', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: -0.3,
                      color: accent,
                      fontFamily: ShunShiTypography.serifFamily,
                    )),
                    const Spacer(),
                    IconButton(
                      tooltip: '通知',
                      onPressed: () => context.push('/notifications'),
                      icon: Icon(Icons.notifications_outlined, size: 22, color: accent),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: AppColors.surfaceContainerLow(context), margin: const EdgeInsets.symmetric(horizontal: 20)),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  // ── 搜索栏 ──
                  Container(
                    decoration: BoxDecoration(
                      color: field,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      readOnly: true,
                      onTap: () => context.push('/search'),
                      style: TextStyle(color: title, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '搜索调理方案、节气食谱...',
                        hintStyle: TextStyle(color: muted, fontSize: 16),
                        prefixIcon: Icon(Icons.search, color: muted, size: 22),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 7宫格导航 ──
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: [
                      _gridIcon(context, Icons.health_and_safety, '体质调养', () => context.push('/constitution')),
                      _gridIcon(context, Icons.restaurant_menu, '节气食谱', () => context.push('/wellness-category/food_therapy')),
                      _gridIcon(context, Icons.emoji_food_beverage, '养生茶饮', () => context.push('/wellness-category/tea')),
                      _gridIcon(context, Icons.architecture, '经络穴位', () => context.push('/wellness-category/acupressure')),
                      _gridIcon(context, Icons.self_improvement, '传统功法', () => context.push('/wellness-category/exercise')),
                      _gridIcon(context, Icons.graphic_eq, '助眠音频', () => context.push('/wellness-category/sleep')),
                      _gridIcon(context, Icons.spa_outlined, '冥想音频', () => context.push('/meditation')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShunshiReferenceLibraryTile(onTap: () => context.push('/reference-library')),
                  const SizedBox(height: 32),

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
                              Text('时令精选', style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w700,
                                fontFamily: ShunShiTypography.serifFamily,
                                color: AppColors.primary(context), letterSpacing: -0.5,
                              )),
                              Text('按当前节气', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: AppColors.secondary(context), letterSpacing: 1.5,
                              )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 张入口卡片：都是真实页面，不带虚构的阅读时长或收藏数
                      _editorCard(
                        context: context,
                        tag: currentSolarTermName() ?? '时令',
                        title: '时令食谱：当下吃什么',
                        desc: '按节气整理的食材与做法，点开能看到每一道的用料和步骤。',
                        icon: Icons.restaurant_menu,
                        route: '/wellness-category/food_therapy',
                        gradient: [ShunShiColors.apricotLight, AppColors.secondary(context)],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        context: context,
                        tag: '功法',
                        title: '传统功法：八段锦、太极拳等',
                        desc: '动作舒缓的传统功法，附每次练习的时长和注意事项。',
                        icon: Icons.self_improvement,
                        route: '/wellness-category/exercise',
                        gradient: [ShunShiColors.primaryContainer, AppColors.primaryLight(context)],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        context: context,
                        tag: '茶饮',
                        title: '养生茶饮：材料与冲泡方法',
                        desc: '常见茶饮的材料、用量和冲泡时间，一看就能照着做。',
                        icon: Icons.emoji_food_beverage,
                        route: '/wellness-category/tea',
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

  Widget _gridIcon(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disc = isDark ? ShunShiColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest(context);
    final accent = isDark ? ShunShiColors.darkPrimary : AppColors.primary(context);
    final labelColor = isDark ? ShunShiColors.darkTextPrimary : AppColors.textPrimary(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disc,
              border: Border.all(color: (isDark ? ShunShiColors.darkBorder : AppColors.textTertiary(context)).withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 28, color: accent),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: labelColor,
          )),
        ],
      ),
    );
  }

  Widget _editorCard({
    required BuildContext context,
    required String tag,
    required String title,
    required String desc,
    required IconData icon,
    required String route,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
          border: Border.all(color: AppColors.textTertiary(context).withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // 左侧色块 + 图标
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
                child: Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.85)),
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
                                color: AppColors.textPrimary(context),
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(title, style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500,
                          fontFamily: ShunShiTypography.serifFamily,
                          color: AppColors.textPrimary(context), height: 1.3,
                        )),
                        const SizedBox(height: 6),
                        Text(desc, style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary(context),
                          height: 1.5,
                        ), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      children: [
                        Text('去看看', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.secondary(context),
                        )),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.secondary(context)),
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
