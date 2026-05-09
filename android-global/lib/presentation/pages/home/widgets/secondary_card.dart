import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/theme_helper.dart';

class SecondaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const SecondaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textTertiary(context).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary(context), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
              style: TextStyle(
                fontFamily: ShunShiTypography.sansFamily,
                fontSize: 15, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(subtitle,
            style: TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              color: AppColors.textTertiary(context), fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: AppColors.textTertiary(context).withValues(alpha: 0.5), size: 18),
        ],
      ),
    ),
  );
}
