import 'package:flutter/material.dart';
import 'package:seasons/core/theme/seasons_colors.dart';
import 'package:seasons/core/theme/seasons_text_styles.dart';

/// Daily Personalized Recommendation Card
class DailyRecommendation extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final String? constitution;
  final String? season;
  final void Function(Map<String, dynamic> item)? onItemTap;

  const DailyRecommendation({super.key, required this.recommendations, this.constitution, this.season, this.onItemTap});

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
              Text('💡 Today for You', style: SeasonsTextStyles.heading),
              const SizedBox(width: 8),
              if (constitution != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: SeasonsColors.primaryLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                  child: Text(constitution!, style: SeasonsTextStyles.overline.copyWith(color: SeasonsColors.primaryDark)),
                ),
            ],
          ),
        ),
        ...recommendations.map((item) => _RecommendationItem(item: item, onTap: () => onItemTap?.call(item))),
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
          color: SeasonsColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SeasonsColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _getTypeColor(type).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
                      Expanded(child: Text(title, style: SeasonsTextStyles.body.copyWith(fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (difficulty.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: SeasonsColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(difficulty, style: SeasonsTextStyles.overline.copyWith(color: SeasonsColors.primaryDark)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (reason.isNotEmpty) Text(reason, style: SeasonsTextStyles.caption.copyWith(color: SeasonsColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (duration.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(children: [
                        Icon(Icons.schedule, size: 12, color: SeasonsColors.textHint),
                        const SizedBox(width: 2),
                        Text(duration, style: SeasonsTextStyles.overline.copyWith(color: SeasonsColors.textHint)),
                      ]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: SeasonsColors.textHint),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'recipe': return SeasonsColors.warm;
      case 'exercise': return SeasonsColors.success;
      case 'tea': return const Color(0xFF8D6E63);
      case 'sleep': return const Color(0xFF7E57C2);
      case 'acupoint': return SeasonsColors.sky;
      default: return SeasonsColors.primary;
    }
  }
}
