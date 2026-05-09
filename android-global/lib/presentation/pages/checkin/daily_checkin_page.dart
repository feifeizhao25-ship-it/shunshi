/// Daily Check-In Page — Reference: daily_check_in
/// "Morning Stillness" — Energy & mood check-in
///
/// Structure:
/// 1. Quote
/// 2. Weekly streak
/// 3. Energy level selector
/// 4. Current mood selector
/// 5. Submit
library;

import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';

class DailyCheckInPage extends StatefulWidget {
  const DailyCheckInPage({super.key});

  @override
  State<DailyCheckInPage> createState() => _DailyCheckInPageState();
}

class _DailyCheckInPageState extends State<DailyCheckInPage> {
  int _energyIndex = -1;
  int _moodIndex = -1;

  static const _energyLevels = [
    _Option('Stillness', Icons.bedtime),
    _Option('Gentle Flow', Icons.water),
    _Option('Vibrant', Icons.bolt),
  ];

  static const _moods = [
    _Option('Calm', Icons.filter_vintage),
    _Option('Bright', Icons.light_mode),
    _Option('Restless', Icons.air),
    _Option('Grounded', Icons.terrain),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(AppLocalizations.of(context).t('checkin_morning'), style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 8),
            Text(
              '"In the garden of the mind, every thought is a seed.\nChoose what you water today."',
              style: TextStyle(
                fontSize: 14, color: ShunShiColors.textSecondary,
                height: 1.7, fontStyle: FontStyle.italic,
                fontFamily: ShunShiTypography.sansFamily,
              ),
            ),
            const SizedBox(height: 20),

            // ── Weekly Streak ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department, size: 24, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context).t('checkin_12_day_flow'), style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B),
                  fontFamily: ShunShiTypography.sansFamily,
                )),
                const Spacer(),
                Text(AppLocalizations.of(context).t('checkin_streak_current'), style: TextStyle(
                  fontSize: 12, color: ShunShiColors.textTertiary,
                  fontFamily: ShunShiTypography.sansFamily,
                )),
              ]),
            ),
            const SizedBox(height: 28),

            // ── How is energy flowing ──
            Text(AppLocalizations.of(context).t('checkin_energy_question'), style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).t('checkin_take_a_quiet_moment_to_listen_to_your_interna'), style: TextStyle(
              fontSize: 13, color: ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 20),

            // ── Energy Level ──
            Text(AppLocalizations.of(context).t('checkin_energy_level'), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 12),
            Row(children: List.generate(_energyLevels.length, (i) => _optionChip(i, _energyLevels, _energyIndex, (v) => setState(() => _energyIndex = v)))),
            const SizedBox(height: 24),

            // ── Current Mood ──
            Text(AppLocalizations.of(context).t('checkin_current_mood'), style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: List.generate(_moods.length, (i) => _optionChip(i, _moods, _moodIndex, (v) => setState(() => _moodIndex = v))),
            ),
            const SizedBox(height: 32),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _energyIndex >= 0 && _moodIndex >= 0 ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('checkin_checkin_saved')), duration: Duration(seconds: 2)),
                  );
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ShunShiColors.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context).t('checkin_complete_checkin'), style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                )),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _optionChip(int index, List<_Option> options, int selectedIndex, ValueChanged<int> onTap) {
    final opt = options[index];
    final selected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ShunShiColors.primary.withValues(alpha: 0.1) : ShunShiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(opt.icon, size: 18,
              color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(opt.label, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: selected ? ShunShiColors.primary : ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
          ],
        ),
      ),
    );
  }
}

class _Option {
  final String label;
  final IconData icon;
  const _Option(this.label, this.icon);
}
