/// Seasonal Shopping List — Reference: seasonal_shopping_list
/// "Seasonal Essentials — Curating your kitchen"
///
/// Structure:
/// 1. Header
/// 2. Import from recipe CTA
/// 3. Category sections with checkable items
/// 4. Add item FAB
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SeasonalShoppingPage extends StatefulWidget {
  const SeasonalShoppingPage({super.key});

  @override
  State<SeasonalShoppingPage> createState() => _SeasonalShoppingPageState();
}

class _SeasonalShoppingPageState extends State<SeasonalShoppingPage> {
  final _newItem = TextEditingController();

  static final _categories = [
    _ShoppingCategory('蔬果', '4件', [
      _ShoppingItem('胡萝卜', '应季', '一捆，带叶', true),
      _ShoppingItem('芦笋', '应季', '一把，细茎', false),
      _ShoppingItem('葱', '新鲜', '6-8根一捆', true),
      _ShoppingItem('樱桃萝卜', '应季', '一捆，红色', false),
    ]),
    _ShoppingCategory('香草', '2件', [
      _ShoppingItem('薄荷', '有机', '一小把', false),
      _ShoppingItem('罗勒', '本地', '盆栽或鲜切', true),
    ]),
    _ShoppingCategory('谷物', '3件', [
      _ShoppingItem('糙米', '国产', '500g袋装', false),
      _ShoppingItem('藜麦', '有机', '400g', true),
      _ShoppingItem('大麦', '去壳', '500g', false),
    ]),
  ];

  late List<_ShoppingCategory> _cats;

  @override
  void initState() {
    super.initState();
    _cats = _categories.map((c) => _ShoppingCategory(
      c.name, c.count,
      c.items.map((i) => _ShoppingItem(i.name, i.tag, i.desc, i.checked)).toList(),
    )).toList();
  }

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
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
                Text('时令好物', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
                )),
                const SizedBox(height: 4),
                Text(
                  "Curating your kitchen for the turning of the year.\nYour list is synced with the garden's natural rhythm.",
                  style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily, height: 1.5),
                ),
                const SizedBox(height: 16),
                // Import CTA
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ShunShiColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.eco, size: 20, color: ShunShiColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('来自你的厨房', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                    ))),
                    Text('添加6件物品', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _cats.length,
              itemBuilder: (context, catIndex) {
                final cat = _cats[catIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(cat.name, style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
                      )),
                      const SizedBox(width: 8),
                      Text('${cat.items.where((i) => i.checked).length}/${cat.items.length} Items', style: TextStyle(
                        fontSize: 13, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ]),
                    const SizedBox(height: 10),
                    ...cat.items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: Key('$catIndex-$idx'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => setState(() => cat.items.removeAt(idx)),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: ShunShiColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delete, color: ShunShiColors.error),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.checked
                                  ? ShunShiColors.surfaceContainerLow
                                  : ShunShiColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              GestureDetector(
                                onTap: () => setState(() => item.checked = !item.checked),
                                child: Icon(
                                  item.checked ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 22, color: item.checked ? ShunShiColors.primary : ShunShiColors.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item.name, style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500,
                                    color: item.checked ? ShunShiColors.textTertiary : ShunShiColors.textPrimary,
                                    fontFamily: ShunShiTypography.sansFamily,
                                    decoration: item.checked ? TextDecoration.lineThrough : null,
                                  )),
                                  Text('${item.tag} · ${item.desc}', style: TextStyle(
                                    fontSize: 12, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
                                  )),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: ShunShiColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShunShiColors.surface,
        title: Text('Add Item', style: TextStyle(fontFamily: ShunShiTypography.sansFamily, color: ShunShiColors.textPrimary)),
        content: TextField(
          controller: _newItem,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ingredient name...',
            hintStyle: TextStyle(color: ShunShiColors.textTertiary),
            filled: true,
            fillColor: ShunShiColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (_newItem.text.isNotEmpty) {
                setState(() {
                  _cats[0].items.add(_ShoppingItem(_newItem.text, 'Custom', '', false));
                });
                _newItem.clear();
                Navigator.pop(ctx);
              }
            },
            child: Text('Add', style: TextStyle(color: ShunShiColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _ShoppingCategory {
  final String name;
  final String count;
  final List<_ShoppingItem> items;
  const _ShoppingCategory(this.name, this.count, this.items);
}

class _ShoppingItem {
  final String name;
  final String tag;
  final String desc;
  bool checked;
  _ShoppingItem(this.name, this.tag, this.desc, this.checked);
}
