/// 食疗详情页 — 参考UI _4
/// 黄芪炖鸡汤 — 春季·食疗
///
/// 结构（从上到下）:
/// 1. Hero: 标题 + 季节标签 + 功效摘要
/// 2. 康养洞察卡片（AI个性化推荐）
/// 3. 食材配比表
/// 4. 烹饪步骤（1-4）
/// 5. 营养与能量数据条
/// 6. 适宜/不宜人群标签
/// 7. CTA: 开始烹饪
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class FoodDetailPage extends StatelessWidget {
  final String? foodName;
  const FoodDetailPage({super.key, this.foodName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: ShunShiColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Warm gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4A6741),
                          Color(0xFF2D5A3D),
                          Color(0xFF144227),
                        ],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    right: -30, top: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40, bottom: 20,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    left: 20, right: 20, bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Season tag
                        Row(children: [
                          _heroTag('SPRING · 春'),
                          const SizedBox(width: 8),
                          _heroTag('MEAL · 食疗'),
                        ]),
                        const SizedBox(height: 12),
                        Text(
                          foodName ?? '黄芪炖鸡汤',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '益气固表，温中补虚',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quick info
                        Row(children: [
                          _infoChip('适合体质', '气虚质'),
                          const SizedBox(width: 16),
                          _infoChip('烹饪时长', '120 分钟'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 康养洞察（AI卡片）──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ShunShiColors.goldLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.auto_awesome, size: 18, color: ShunShiColors.gold),
                          const SizedBox(width: 8),
                          Text('康养洞察', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: ShunShiColors.gold, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ]),
                        const SizedBox(height: 12),
                        const Text(
                          '基于您近期的步数下降及心率监测，我们察觉到您可能处于"气虚"状态。'
                          '此方中黄芪为补气圣药，配合温中的母鸡，能从根源固本。建议在辰时（早7-9点）饮用，效果最佳。',
                          style: TextStyle(
                            fontSize: 13, color: ShunShiColors.textSecondary,
                            height: 1.7, fontFamily: ShunShiTypography.sansFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: ShunShiColors.goldLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            const Icon(Icons.auto_awesome, size: 14, color: ShunShiColors.gold),
                            const SizedBox(width: 6),
                            Text('AI 指点："春季多风，固表防感。"', style: TextStyle(
                              fontSize: 12, color: ShunShiColors.gold,
                              fontFamily: ShunShiTypography.sansFamily, fontStyle: FontStyle.italic,
                            )),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 食材配比 ──
                  _sectionTitle('食材配比'),
                  const SizedBox(height: 12),
                  _ingredientRow('老母鸡', '1 只'),
                  _ingredientRow('黄芪', '30g'),
                  _ingredientRow('红枣', '5 枚'),
                  _ingredientRow('生姜', '3 片'),
                  const SizedBox(height: 8),
                  Text(
                    '* 请选用一年以上老母鸡，药效更佳。黄芪建议提前浸泡15分钟。',
                    style: TextStyle(
                      fontSize: 12, color: ShunShiColors.textTertiary,
                      fontFamily: ShunShiTypography.sansFamily, fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 烹饪步骤 ──
                  _sectionTitle('烹饪步骤'),
                  const SizedBox(height: 12),
                  _cookingStep(1, '鸡肉切成适口块状，冷水入锅焯水，捞出洗净。'),
                  _cookingStep(2, '放入砂锅，加入足量清水，投入黄芪、红枣与姜片。'),
                  _cookingStep(3, '大火烧开，撇去浮沫，转极小火慢炖2小时。'),
                  _cookingStep(4, '关火前加入少许盐调味即可，保持汤品原味清甜。'),
                  const SizedBox(height: 24),

                  // ── 营养与能量 ──
                  _sectionTitle('营养与能量'),
                  const SizedBox(height: 8),
                  const Text(
                    '本食谱富含优质蛋白质与多种微量元素，特有的黄芪多糖能显著增强免疫应答。'
                    '每百毫升含热量约为 85kcal。',
                    style: TextStyle(
                      fontSize: 13, color: ShunShiColors.textSecondary,
                      height: 1.6, fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nutrition bars
                  _nutritionBar('Protein', '28g', 0.7, ShunShiColors.primary),
                  const SizedBox(height: 8),
                  _nutritionBar('Fat', '12g', 0.3, ShunShiColors.gold),
                  const SizedBox(height: 8),
                  _nutritionBar('Carbs', '8g', 0.2, ShunShiColors.apricot),
                  const SizedBox(height: 8),
                  _nutritionBar('Fiber', '3g', 0.15, ShunShiColors.calm),
                  const SizedBox(height: 24),

                  // ── 适宜人群 ──
                  _sectionTitle('适宜人群'),
                  const SizedBox(height: 8),
                  _tagList(['气虚质', '阳虚质', '易感冒', '免疫力低下', '疲劳乏力']),
                  const SizedBox(height: 16),

                  // ── 不宜人群 ──
                  _sectionTitle('不宜人群'),
                  const SizedBox(height: 8),
                  _tagList(['阴虚火旺', '感冒发热', '高血压急症'], isWarning: true),
                  const SizedBox(height: 24),

                  // ── CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShunShiColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 20),
                          const SizedBox(width: 8),
                          Text('开始烹饪', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── AI咨询入口 ──
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ShunShiColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome, size: 20, color: ShunShiColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('想了解更多？', style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
                            )),
                            const SizedBox(height: 2),
                            const Text('向AI顺时助手咨询个性化饮食建议', style: TextStyle(
                              fontSize: 12, color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily,
                            )),
                          ]),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: ShunShiColors.primary),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _heroTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9),
      letterSpacing: 0.5, fontFamily: ShunShiTypography.sansFamily,
    )),
  );

  Widget _infoChip(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
        fontSize: 11, color: Colors.white60, fontFamily: ShunShiTypography.sansFamily,
      )),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: ShunShiTypography.sansFamily,
      )),
    ],
  );

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary,
  ));

  Widget _ingredientRow(String name, String amount) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: ShunShiColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(name, style: const TextStyle(
          fontSize: 14, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
        )),
      ),
      Text(amount, style: TextStyle(
        fontSize: 14, color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily, fontWeight: FontWeight.w500,
      )),
    ]),
  );

  Widget _cookingStep(int num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: ShunShiColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('$num', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.sansFamily,
          ))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(
          fontSize: 14, color: ShunShiColors.textSecondary, height: 1.6, fontFamily: ShunShiTypography.sansFamily,
        ))),
      ],
    ),
  );

  Widget _nutritionBar(String label, String value, double percent, Color color) => Row(
    children: [
      SizedBox(
        width: 60,
        child: Text(label, style: TextStyle(
          fontSize: 12, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
        )),
      ),
      Expanded(
        child: Stack(children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: percent,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 36,
        child: Text(value, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: color, fontFamily: ShunShiTypography.sansFamily,
        ), textAlign: TextAlign.right),
      ),
    ],
  );

  Widget _tagList(List<String> tags, {bool isWarning = false}) => Wrap(
    spacing: 8, runSpacing: 8,
    children: tags.map((t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning
            ? ShunShiColors.error.withValues(alpha: 0.08)
            : ShunShiColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(t, style: TextStyle(
        fontSize: 13,
        color: isWarning ? ShunShiColors.error : ShunShiColors.primary,
        fontFamily: ShunShiTypography.sansFamily,
      )),
    )).toList(),
  );
}
