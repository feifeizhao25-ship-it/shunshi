/// Journal Reflection — 参考 journal_reflection
/// 内气候 + 感恩 + 反思
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class JournalReflectionV2 extends StatelessWidget {
  const JournalReflectionV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                const Icon(Icons.menu, color: Color(0xFF533afd)),
                const Spacer(),
                Text('SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
              const SizedBox(height: 16),

              Text(AppLocalizations.of(context).t('journal_late_summer_phase'), style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              Text(AppLocalizations.of(context).t('journal_harvesting_the_light'), style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 4),
              Text('Take a moment to center yourself. The earth is slowing, and so may you.',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
              const SizedBox(height: 24),

              // Current Internal Climate
              Text(AppLocalizations.of(context).t('journal_current_internal_climate'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
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
                  Text(AppLocalizations.of(context).t('journal_daily_gratitude'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildPromptRow(Icons.restore, 'A small thing today...'),
                  const SizedBox(height: 8),
                  _buildPromptRow(Icons.celebration, 'A person I cherish...'),
                ]),
              ),
              const SizedBox(height: 16),

              // Seasonal Reflection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppLocalizations.of(context).t('journal_seasonal_reflection'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).t('journal_prompt_what_are_you_shedding'), style: TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(AppLocalizations.of(context).t('journal_write_your_reflection'), style: TextStyle(color: Colors.white38)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Personal Intentions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF533afd), size: 20),
                  const SizedBox(width: 10),
                  Text(AppLocalizations.of(context).t('journal_personal_intentions'), style: TextStyle(fontSize: 15, color: ShunShiColors.textSecondary)),
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

  Widget _buildPromptRow(IconData icon, String prompt) {
    return Row(children: [
      Icon(icon, color: Color(0xFF533afd), size: 18),
      const SizedBox(width: 10),
      Text(prompt, style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary)),
    ]);
  }
}
