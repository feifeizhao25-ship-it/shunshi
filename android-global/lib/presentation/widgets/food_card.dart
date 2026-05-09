import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/theme_helper.dart';

/// 食疗卡片数据
class FoodCardData {
  final String name;
  final String seasonTag;
  final String seasonEmoji;
  final String description;
  final String difficulty;
  final String category;
  final String ingredients;
  final String effect;
  final String recipe;
  final IconData icon;

  const FoodCardData({
    required this.name,
    required this.seasonTag,
    required this.seasonEmoji,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.ingredients,
    required this.effect,
    required this.recipe,
    required this.icon,
  });
}

/// 食疗卡片 Widget
class FoodCard extends StatelessWidget {
  final FoodCardData food;
  final VoidCallback? onTap;

  const FoodCard({super.key, required this.food, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            // Food icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _seasonColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(food.icon, color: _seasonColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _seasonColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${food.seasonEmoji} ${food.seasonTag}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _seasonColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBadge(context, food.category, ShunShiColors.primary),
                      const SizedBox(width: 8),
                      _buildBadge(
                        context,
                        food.difficulty,
                        food.difficulty == 'Easy'
                            ? ShunShiColors.primary
                            : ShunShiColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary(context), size: 20),
          ],
        ),
      ),
    );
  }

  Color get _seasonColor {
    switch (food.seasonTag) {
      case 'Spring':
        return const Color(0xFF6B9E5E);
      case 'Summer':
        return const Color(0xFFE8A050);
      case 'Autumn':
        return const Color(0xFFC4956A);
      case 'Winter':
        return const Color(0xFF6B8EA0);
      default:
        return ShunShiColors.primary;
    }
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _seasonColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(food.icon, color: _seasonColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        food.name,
                        style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildBadge(context, '${food.seasonEmoji} ${food.seasonTag}', _seasonColor),
                    _buildBadge(context, food.category, ShunShiColors.primary),
                    _buildBadge(context, food.difficulty, ShunShiColors.secondary),
                  ],
                ),
                const SizedBox(height: 20),
                _section(context, 'Ingredients', food.ingredients),
                _section(context, 'Benefits', food.effect),
                _section(context, 'Recipe', food.recipe),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
