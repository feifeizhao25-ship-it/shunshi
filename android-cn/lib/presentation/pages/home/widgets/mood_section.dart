import 'package:flutter/material.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/theme_helper.dart';

class MoodSection extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<String> onMoodSelected;
  final bool reflecting;
  const MoodSection({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    required this.reflecting,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      ('calm', '😌', '平静'), ('tired', '😴', '疲惫'), ('anxious', '😰', '焦虑'),
      ('peaceful', '🕊️', '安宁'), ('energetic', '⚡', '精力充沛'), ('overwhelmed', '🫧', '心烦'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你现在感觉怎么样？',
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 15, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: moods.map((m) {
            final sel = selectedMood == m.$1;
            return GestureDetector(
              onTap: reflecting ? null : () => onMoodSelected(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? ShunShiColors.primary.withValues(alpha: 0.08) : const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(20),
                  border: sel ? Border.all(color: ShunShiColors.primary, width: 1.5) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.$2, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(m.$3,
                      style: TextStyle(
                        fontFamily: ShunShiTypography.sansFamily,
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: sel ? ShunShiColors.primary : AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
