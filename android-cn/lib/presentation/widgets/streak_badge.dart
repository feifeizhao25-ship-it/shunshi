import 'package:flutter/material.dart';
import '../../design_system/theme.dart';

class StreakBadge extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const StreakBadge({super.key, required this.streakDays, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (streakDays <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streakDays >= 30
                ? [Colors.amber, Colors.orange]
                : streakDays >= 7
                    ? [ShunShiColors.primary, ShunShiColors.secondary]
                    : [Colors.grey.shade300, Colors.grey.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              streakDays >= 30 ? '🏆' : streakDays >= 7 ? '🔥' : '🌱',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              '$streakDays天',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
