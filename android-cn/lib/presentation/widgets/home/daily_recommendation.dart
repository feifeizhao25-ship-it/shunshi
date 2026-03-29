import 'package:flutter/material.dart';
import 'package:shunshi/core/theme/shunshi_colors.dart';
import 'package:shunshi/core/theme/shunshi_text_styles.dart';

/// 每日个性化推荐卡片
class DailyRecommendation extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final String? constitution;
  final String? season;
  final void Function(Map<String, dynamic> item)? onItemTap;

  const DailyRecommendation({
    super.key,
    required this.recommendations,
    this.constitution,
    this.season,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('💡 今日推荐', style: ShunshiTextStyles.heading),
              const SizedBox(width: 8),
              if (constitution != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ShunshiColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    constitution!,
                    style: ShunshiTextStyles.overline.copyWith(color: ShunshiColors.primaryDark),
                  ),
                ),
            ],
          ),
        ),
        ...recommendations.map((item) => _RecommendationItem(
          item: item,
          onTap: () => onItemTap?.call(item),
        )),
      ],
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _RecommendationItem({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final emoji = item['emoji'] ?? '✨';
    final title = item['title'] ?? '';
    final reason = item['reason'] ?? '';
    final type = item['type'] ?? '';
    final duration = item['duration'] ?? '';
    final difficulty = item['difficulty'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunshiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ShunshiColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: ShunshiTextStyles.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (difficulty.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ShunshiColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(difficulty, style: ShunshiTextStyles.overline.copyWith(color: ShunshiColors.primaryDark)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (reason.isNotEmpty)
                    Text(reason, style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (duration.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: ShunshiColors.textHint),
                          const SizedBox(width: 2),
                          Text(duration, style: ShunshiTextStyles.overline.copyWith(color: ShunshiColors.textHint)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: ShunshiColors.textHint),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'recipe': return ShunshiColors.warm;
      case 'exercise': return ShunshiColors.success;
      case 'tea': return const Color(0xFF8D6E63);
      case 'sleep': return const Color(0xFF7E57C2);
      case 'acupoint': return ShunshiColors.calm;
      default: return ShunshiColors.primary;
    }
  }
}
