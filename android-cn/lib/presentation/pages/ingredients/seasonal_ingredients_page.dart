/// Seasonal Ingredients Guide — Reference: seasonal_ingredients_guide
/// "Late Summer Harvest — The Seasonal Directory"
///
/// Structure:
/// 1. Header
/// 2. Filter tabs (All/Vegetables/Fruits/Herbs)
/// 3. Ingredient cards with wellness benefits + body type alignment
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SeasonalIngredientsPage extends StatefulWidget {
  const SeasonalIngredientsPage({super.key});

  @override
  State<SeasonalIngredientsPage> createState() => _SeasonalIngredientsPageState();
}

class _SeasonalIngredientsPageState extends State<SeasonalIngredientsPage> {
  int _filterIndex = 0;
  static const _filters = ['All Items', 'Vegetables', 'Fruits', 'Herbs'];

  static const _ingredients = [
    _Ingredient('芦笋', 'Vegetables', '富含叶酸和铬，支持排毒和血糖调节。', ['Vata Cooling', 'Kapha Light']),
    _Ingredient('大黄', 'Fruits', '高纤维和抗氧化，促进消化健康。', ['Pitta Cooling']),
    _Ingredient('Mint', 'Herbs', '舒缓消化，具有清凉特性。', ['Pitta Cooling', 'Kapha Light']),
    _Ingredient('豌豆', 'Vegetables', '富含蛋白质的春季食材，帮助肌肉恢复。', ['Vata Grounding', 'Kapha Light']),
    _Ingredient('草莓', 'Fruits', '维C宝库。抗炎护心。', ['Pitta Cooling', 'Vata Nourishing']),
    _Ingredient('罗勒', 'Herbs', '适应原草本，帮助应对压力。', ['Vata Warming']),
  ];

  List<_Ingredient> get _filtered {
    if (_filterIndex == 0) return _ingredients;
    return _ingredients.where((i) => i.category == _filters[_filterIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('晚夏收获', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily)),
                Text('时令食材指南', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily)),
                const SizedBox(height: 6),
                Text('让你的餐盘顺应自然的节律。', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily)),
                const SizedBox(height: 16),
                // Search
                Container(
                  height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.search, size: 20, color: ShunShiColors.textTertiary),
                    const SizedBox(width: 10),
                    Text('Search ingredients...', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily)),
                  ]),
                ),
                const SizedBox(height: 16),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: List.generate(_filters.length, (i) => _filterTab(i))),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (context, index) => _ingredientCard(_filtered[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(int i) {
    final selected = i == _filterIndex;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_filters[i], style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: selected ? Colors.white : ShunShiColors.textSecondary,
            fontFamily: ShunShiTypography.sansFamily,
          )),
        ),
      ),
    );
  }

  Widget _ingredientCard(_Ingredient ing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('In Peak', style: TextStyle(fontSize: 11, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily)),
              const Spacer(),
              const Icon(Icons.favorite_outline, size: 20, color: ShunShiColors.textTertiary),
            ]),
            const SizedBox(height: 8),
            Text(ing.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily)),
            const SizedBox(height: 10),
            Text('Wellness Benefits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily)),
            const SizedBox(height: 4),
            Text(ing.benefits, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5, fontFamily: ShunShiTypography.sansFamily)),
            const SizedBox(height: 10),
            Text('Body Type Alignment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: ing.types.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: ShunShiColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(t, style: TextStyle(fontSize: 12, color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily)),
            )).toList()),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Row(children: [
                Text('View Rituals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16, color: ShunShiColors.primary),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ingredient {
  final String name;
  final String category;
  final String benefits;
  final List<String> types;
  const _Ingredient(this.name, this.category, this.benefits, this.types);
}
