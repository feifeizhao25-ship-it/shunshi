// Follow-up recommendation card for home page
import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';

class FollowUpCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String type;
  final VoidCallback? onTap;
  const FollowUpCard({super.key, required this.title, required this.subtitle, required this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context), fontFamily: 'sans')),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context), fontFamily: 'sans')),
          ],
        ),
      ),
    );
  }
}
