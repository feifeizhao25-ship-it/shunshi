/// 养生馆首页 — 对齐UI参考 _14
/// TopBar(养生馆+通知) → 搜索栏 → 6宫格导航 → 精选编辑(3张横滑卡片)
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';

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
                    GestureDetector(
                      onTap: () {},
                      child: Icon(Icons.notifications_outlined, size: 22, color: accent),
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

                  // ── 6宫格导航 ──
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: [
                      _gridIcon(context, Icons.health_and_safety, '体质调养', () => context.push('/wellness/constitution')),
                      _gridIcon(context, Icons.restaurant_menu, '节气食谱', () => context.push('/wellness/food_therapy')),
                      _gridIcon(context, Icons.emoji_food_beverage, '养生茶饮', () => context.push('/wellness/tea')),
                      _gridIcon(context, Icons.architecture, '经络穴位', () => context.push('/wellness/acupressure')),
                      _gridIcon(context, Icons.self_improvement, '传统功法', () => context.push('/wellness/exercise')),
                      _gridIcon(context, Icons.graphic_eq, '助眠音频', () => context.push('/wellness/sleep')),
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
                              Text('精选编辑', style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w700,
                                fontFamily: ShunShiTypography.serifFamily,
                                color: AppColors.primary(context), letterSpacing: -0.5,
                              )),
                              Text('编辑精选', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500,
                                color: AppColors.secondary(context), letterSpacing: 1.5,
                              )),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text('查看全部', style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary(context),
                                )),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right, size: 18, color: AppColors.primary(context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 Editor Cards
                      _editorCard(
                        context: context,
                        tag: '惊蛰',
                        readTime: '5分钟阅读',
                        title: '春季养生：从调理肝气开始',
                        desc: '惊蛰时节，阳气初动。本期编辑精选为您带来春季护肝的三个关键穴位与食疗方案。',
                        likes: '1,208',
                        gradient: [ShunShiColors.apricotLight, AppColors.secondary(context)],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        context: context,
                        tag: '功法',
                        readTime: '8分钟阅读',
                        title: '八段锦：唤醒身体的经络能量',
                        desc: '简单易学的传统健身功法，每天十分钟，改善久坐带来的肩颈僵硬。',
                        likes: '3,450',
                        gradient: [ShunShiColors.primaryContainer, AppColors.primaryLight(context)],
                      ),
                      const SizedBox(height: 16),
                      _editorCard(
                        context: context,
                        tag: '食补',
                        readTime: '4分钟阅读',
                        title: '五味入五脏：平衡你的日常膳食',
                        desc: '酸入肝、辛入肺。理解食物的味道，就是理解身体的需求。',
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
          color: AppColors.surfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
          border: Border.all(color: AppColors.textTertiary(context).withValues(alpha: 0.05)),
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
                                color: AppColors.textPrimary(context),
                              )),
                            ),
                            const SizedBox(width: 8),
                            Text(readTime, style: TextStyle(
                              fontSize: 10, color: AppColors.textTertiary(context),
                            )),
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
                        Icon(Icons.favorite, size: 14, color: AppColors.secondary(context)),
                        const SizedBox(width: 4),
                        Text('$likes 收藏', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: AppColors.secondary(context),
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
