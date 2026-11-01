// SEASONS Wellness Library Page — International Version
// Grid of wellness categories with tap-to-expand content

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';
import '../../../data/content/wellness_content.dart';

class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tintColor;
  final VoidCallback onTap;
  const _CategoryItem(this.icon, this.title, this.subtitle, this.tintColor, this.onTap);
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  void _showBodyTypes() {
    _showCategorySheet('Body Types', Icons.accessibility_new, AppColors.primary(context),
      WellnessContent.bodyTypes.map((b) => _ContentItem(
        emoji: b.emoji,
        title: b.name,
        subtitle: b.tagline,
        details: 'Traits: ${b.traits.join(', ')}\n\nRecommendations:\n${b.recommendations.map((r) => '• $r').join('\n')}',
      )).toList(),
    );
  }

  void _showRecipes() {
    _showCategorySheet('Seasonal Recipes', Icons.restaurant_menu, ShunShiColors.secondary,
      WellnessContent.recipes.map((r) => _ContentItem(
        emoji: r.emoji,
        title: r.name,
        subtitle: r.season,
        details: 'Ingredients: ${r.ingredients.join(', ')}\n\nSteps:\n${r.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}\n\n${r.benefits}',
      )).toList(),
    );
  }

  void _showHerbalTeas() {
    _showCategorySheet('Herbal Teas', Icons.local_cafe, ShunShiColors.blue,
      WellnessContent.herbalTeas.map((t) => _ContentItem(
        emoji: t.emoji,
        title: t.name,
        subtitle: t.subtitle,
        details: 'Benefits: ${t.benefits.join(', ')}\n\nBrewing: ${t.brewing}',
      )).toList(),
    );
  }

  void _showPressurePoints() {
    _showCategorySheet('Pressure Points', Icons.touch_app, ShunShiColors.apricot,
      WellnessContent.pressurePoints.map((p) => _ContentItem(
        emoji: '📍',
        title: p.name,
        subtitle: p.location,
        details: 'Technique: ${p.technique}\nDuration: ${p.duration}\n\nBenefits: ${p.benefits.join(', ')}\n\n⚠️ ${p.caution}',
      )).toList(),
    );
  }

  void _showMovement() {
    _showCategorySheet('Movement', Icons.fitness_center, ShunShiColors.goldLight,
      WellnessContent.movements.map((m) => _ContentItem(
        emoji: m.emoji,
        title: m.name,
        subtitle: '${m.subtitle} · ${m.duration}',
        details: m.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n'),
      )).toList(),
    );
  }

  void _showSleepSounds() {
    _showCategorySheet('Sleep Sounds', Icons.bedtime, AppColors.primaryLight(context),
      WellnessContent.sleepSounds.map((s) => _ContentItem(
        emoji: s.emoji,
        title: s.name,
        subtitle: '${s.subtitle} · ${s.duration}',
        details: 'Close your eyes and let ${s.name.toLowerCase()} carry you into restful sleep.',
      )).toList(),
    );
  }

  void _showCategorySheet(String title, IconData icon, Color color, List<_ContentItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGhost(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _ContentItemCard(item: items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryItem(Icons.accessibility_new, 'Body Types', 'Discover your wellness profile', AppColors.primary(context), _showBodyTypes),
      _CategoryItem(Icons.restaurant_menu, 'Seasonal Recipes', 'Fresh ingredients by season', ShunShiColors.secondary, _showRecipes),
      _CategoryItem(Icons.local_cafe, 'Herbal Teas', 'Chamomile, Peppermint, Ginger', ShunShiColors.blue, _showHerbalTeas),
      _CategoryItem(Icons.touch_app, 'Pressure Points', 'Reflexology & acupressure', ShunShiColors.apricot, _showPressurePoints),
      _CategoryItem(Icons.fitness_center, 'Movement', 'Yoga, Tai Chi & Stretching', ShunShiColors.goldLight, _showMovement),
      _CategoryItem(Icons.bedtime, 'Sleep Sounds', 'Nature, white noise & meditation', AppColors.primaryLight(context), _showSleepSounds),
    ];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness Library',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary(context),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your collection of calm',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 15,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
            sliver: SliverGrid(
              // mainAxisExtent grows with the text scale: a fixed 0.85 aspect clipped 2-3 line subtitles even at normal text on 375 dp.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 76 + 135 * (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.5),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CategoryCard(category: categories[index]),
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String details;
  const _ContentItem({required this.emoji, required this.title, required this.subtitle, required this.details});
}

class _ContentItemCard extends StatefulWidget {
  final _ContentItem item;
  const _ContentItemCard({required this.item});

  @override
  State<_ContentItemCard> createState() => _ContentItemCardState();
}

class _ContentItemCardState extends State<_ContentItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.item.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: TextStyle(
                          fontFamily: ShunShiTypography.sansFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.subtitle,
                        style: TextStyle(
                          fontFamily: ShunShiTypography.sansFamily,
                          fontSize: 13,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiary(context),
                  size: 20,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: ShunShiColors.borderGhost),
              const SizedBox(height: 12),
              Text(
                widget.item.details,
                style: TextStyle(
                  fontFamily: ShunShiTypography.sansFamily,
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: category.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: category.tintColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(category.icon, size: 36, color: category.tintColor),
                ),
              ),
            ),
            Flexible(
              flex: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 12,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: category.onTap,
                      child: Text(
                        'See All →',
                        style: TextStyle(
                          fontFamily: ShunShiTypography.sansFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: category.tintColor,
                        ),
                      ),
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
