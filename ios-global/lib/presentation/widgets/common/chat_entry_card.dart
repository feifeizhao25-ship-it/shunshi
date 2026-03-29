import 'package:seasons/design_system/design_system.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ChatEntryCard extends StatelessWidget {
  final VoidCallback? onTap;
  
  const ChatEntryCard({super.key, this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SeasonsRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SeasonsSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SeasonsColors.secondary.withValues(alpha: 0.15),
              SeasonsColors.secondaryLight.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(SeasonsRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SeasonsColors.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: SeasonsColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: SeasonsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk to your companion',
                    style: SeasonsTypography.titleMedium.copyWith(
                      color: SeasonsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SeasonsSpacing.xs),
                  Text(
                    'Share your thoughts, feelings, or anything on your mind',
                    style: SeasonsTypography.bodySmall.copyWith(
                      color: SeasonsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: SeasonsColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
