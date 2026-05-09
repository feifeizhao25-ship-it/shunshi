// Follow-up recommendation card for home page
import 'package:flutter/material.dart';
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
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ShunShiColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, fontFamily: 'sans')),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, fontFamily: 'sans')),
          ],
        ),
      ),
    );
  }
}
