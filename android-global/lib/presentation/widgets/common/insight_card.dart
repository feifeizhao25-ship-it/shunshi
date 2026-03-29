import 'package:seasons/design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../domain/entities/ai_response.dart';

class InsightCard extends StatelessWidget {
  final DailyInsight insight;
  
  const InsightCard({super.key, required this.insight});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SeasonsColors.primary.withValues(alpha: 0.1),
            SeasonsColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(SeasonsRadius.lg),
        border: Border.all(
          color: SeasonsColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: SeasonsColors.primary,
                size: 20,
              ),
              const SizedBox(width: SeasonsSpacing.sm),
              Text(
                'Daily Insight',
                style: SeasonsTypography.labelMedium.copyWith(
                  color: SeasonsColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            insight.text,
            style: SeasonsTypography.bodyLarge.copyWith(
              color: SeasonsColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SeasonsSpacing.sm,
              vertical: SeasonsSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: SeasonsColors.surface,
              borderRadius: BorderRadius.circular(SeasonsRadius.sm),
            ),
            child: Text(
              insight.season.toUpperCase(),
              style: SeasonsTypography.labelSmall.copyWith(
                color: SeasonsColors.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
