/// Daily Check-in — 参考 daily_check_in
/// Morning Stillness, energy + mood check-in
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class DailyCheckinV2 extends StatefulWidget {
  const DailyCheckinV2({super.key});

  @override
  State<DailyCheckinV2> createState() => _DailyCheckinV2State();
}

class _DailyCheckinV2State extends State<DailyCheckinV2> {
  String _energy = '';
  String _mood = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
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
                Text('数字净心', style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF533afd),
                )),
                const Spacer(),
                const SizedBox(width: 24),
              ]),
              const SizedBox(height: 24),

              // Morning Stillness
              Text('晨间静心', style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 8),
              Text('"In the garden of the mind, every thought is a seed. Choose what you water today."',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, fontStyle: FontStyle.italic, height: 1.5)),
              const SizedBox(height: 20),

              // Weekly Rhythm
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('12 Day Flow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Spacer(),
                  Text('当前连续', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 24),

              // Energy Level
              Text('今天你的能量如何？', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary,
              )),
              const SizedBox(height: 4),
              Text('静心片刻，倾听内在的声音。',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary)),
              const SizedBox(height: 12),
              Text('Energy Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['和缓流动', 'Stillness', '活力'].map((e) =>
                GestureDetector(
                  onTap: () => setState(() => _energy = e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _energy == e ? Color(0xFF533afd).withOpacity(0.1) : ShunShiColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _energy == e ? Color(0xFF533afd) : ShunShiColors.borderGhost),
                    ),
                    child: Text(e, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: _energy == e ? Color(0xFF533afd) : ShunShiColors.textSecondary,
                    )),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 20),

              // Mood
              Text('Current Mood', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ('Calm', Icons.filter_vintage, Color(0xFF533afd)),
                ('Bright', Icons.light_mode, Color(0xFFFF9800)),
                ('Reflective', Icons.water_drop, Color(0xFF2196F3)),
              ].map((m) =>
                GestureDetector(
                  onTap: () => setState(() => _mood = m.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _mood == m.$1 ? m.$3.withOpacity(0.1) : ShunShiColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _mood == m.$1 ? m.$3 : ShunShiColors.borderGhost),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(m.$2, size: 16, color: _mood == m.$1 ? m.$3 : ShunShiColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(m.$1, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: _mood == m.$1 ? m.$3 : ShunShiColors.textSecondary,
                      )),
                    ]),
                  ),
                ),
              ).toList()),
              const SizedBox(height: 32),

              // Complete button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _energy.isNotEmpty && _mood.isNotEmpty ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF533afd),
                    disabledBackgroundColor: ShunShiColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('完成打卡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Skip for now', style: TextStyle(color: ShunShiColors.textTertiary)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
