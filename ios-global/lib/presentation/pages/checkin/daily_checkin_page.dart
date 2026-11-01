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
import '../../../design_system/app_colors.dart';
import '../../../design_system/theme.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text('Morning Stillness', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context), fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 8),
            Text(
              '"In the garden of the mind, every thought is a seed.\nChoose what you water today."',
              style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary(context),
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
                Icon(Icons.local_fire_department, size: 24, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Text('12 Day Flow', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B),
                  fontFamily: ShunShiTypography.sansFamily,
                )),
                const Spacer(),
                Text('Current Streak', style: TextStyle(
                  fontSize: 12, color: AppColors.textTertiary(context),
                  fontFamily: ShunShiTypography.sansFamily,
                )),
              ]),
            ),
            const SizedBox(height: 28),

            // ── How is energy flowing ──
            Text('How is your energy flowing today?', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context), fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 4),
            Text('Take a quiet moment to listen to your internal landscape.', style: TextStyle(
              fontSize: 13, color: AppColors.textSecondary(context),
              fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 20),

            // ── Energy Level ──
            Text('Energy Level', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context), fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 12),
            Row(children: List.generate(_energyLevels.length, (i) => _optionChip(i, _energyLevels, _energyIndex, (v) => setState(() => _energyIndex = v)))),
            const SizedBox(height: 24),

            // ── Current Mood ──
            Text('Current Mood', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context), fontFamily: ShunShiTypography.sansFamily,
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
                    const SnackBar(content: Text('Check-in saved'), duration: Duration(seconds: 2)),
                  );
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceContainerLow(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Complete Check-in', style: TextStyle(
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
          color: selected ? AppColors.primary(context).withValues(alpha: 0.1) : AppColors.surfaceContainerLow(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(opt.icon, size: 18,
              color: selected ? AppColors.primary(context) : AppColors.textTertiary(context),
            ),
            const SizedBox(width: 8),
            Text(opt.label, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: selected ? AppColors.primary(context) : AppColors.textSecondary(context),
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
