import 'package:seasons/design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../domain/entities/ai_response.dart';

class SuggestionCard extends StatelessWidget {
  final GentleSuggestion suggestion;
  final VoidCallback? onTap;
  
  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.onTap,
  });
  
  IconData _getIcon() {
    switch (suggestion.iconName) {
      case 'walk':
        return Icons.directions_walk_outlined;
      case 'tea':
        return Icons.coffee_outlined;
      case 'stretch':
        return Icons.self_improvement;
      default:
        return Icons.check_circle_outline;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SeasonsRadius.md),
      child: Container(
        padding: const EdgeInsets.all(SeasonsSpacing.md),
        decoration: BoxDecoration(
          color: SeasonsColors.surface,
          borderRadius: BorderRadius.circular(SeasonsRadius.md),
          boxShadow: SeasonsShadows.small,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: suggestion.isCompleted 
                  ? SeasonsColors.success.withValues(alpha: 0.1)
                  : SeasonsColors.surfaceVariant,
                borderRadius: BorderRadius.circular(SeasonsRadius.sm),
              ),
              child: Icon(
                suggestion.isCompleted 
                  ? Icons.check
                  : _getIcon(),
                color: suggestion.isCompleted 
                  ? SeasonsColors.success
                  : SeasonsColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: SeasonsSpacing.md),
            Expanded(
              child: Text(
                suggestion.text,
                style: SeasonsTypography.bodyMedium.copyWith(
                  color: suggestion.isCompleted 
                    ? SeasonsColors.textTertiary
                    : SeasonsColors.textPrimary,
                  decoration: suggestion.isCompleted 
                    ? TextDecoration.lineThrough
                    : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
