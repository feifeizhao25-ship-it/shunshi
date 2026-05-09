/// Journal Reflection — 参考 journal_reflection
/// 内气候 + 感恩 + 反思
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class JournalReflectionV2 extends StatelessWidget {
  const JournalReflectionV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? ShunShiColors.darkPrimary : Color(0xFF533afd);

    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Icon(Icons.menu, color: brandColor),
                const Spacer(),
                Text('顺时', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: brandColor)),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
              const SizedBox(height: 16),

              Text('长夏阶段', style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              Text('收获时光', style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 4),
              Text('静下心来，感受大地的节奏，让身心也随之放慢。',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
              const SizedBox(height: 24),

              // Current Internal Climate
              Text('当前身心状态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 10),
              Row(children: [
                _buildClimateChip(Icons.wb_sunny, 'Rising Sun', Color(0xFFFF9800)),
                const SizedBox(width: 8),
                _buildClimateChip(Icons.water_drop, 'Calm Water', Color(0xFF2196F3)),
                const SizedBox(width: 8),
                _buildClimateChip(Icons.air, 'Stormy Wind', Color(0xFF9C27B0)),
              ]),
              const SizedBox(height: 8),
              _buildClimateChip(Icons.filter_drama, 'Mist', Color(0xFF607D8B)),
              const SizedBox(height: 24),

              // Daily Gratitude
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('每日感恩', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildPromptRow(Icons.restore, 'A small thing today...', brandColor),
                  const SizedBox(height: 8),
                  _buildPromptRow(Icons.celebration, 'A person I cherish...', brandColor),
                ]),
              ),
              const SizedBox(height: 16),

              // Seasonal Reflection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isDark
                    ? [ShunShiColors.darkPrimary, ShunShiColors.darkPrimary.withValues(alpha: 0.7)]
                    : [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('节气感悟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? ShunShiColors.darkTextPrimary : Colors.white)),
                  const SizedBox(height: 8),
                  Text('提示：你在放下什么？', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.white70, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('写下你的感悟...', style: TextStyle(color: isDark ? Colors.white54 : Colors.white38)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Personal Intentions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? ShunShiColors.darkSurface : ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.add_circle_outline, color: brandColor, size: 20),
                  const SizedBox(width: 10),
                  Text('Personal Intentions', style: TextStyle(fontSize: 15, color: isDark ? ShunShiColors.darkTextSecondary : ShunShiColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPromptRow(IconData icon, String prompt, Color accentColor) {
    return Row(children: [
      Icon(icon, color: accentColor, size: 18),
      const SizedBox(width: 10),
      Text(prompt, style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
    ]);
  }
}
