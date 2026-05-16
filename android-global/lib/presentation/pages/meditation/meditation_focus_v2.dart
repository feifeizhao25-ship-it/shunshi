/// Meditation Focus — 参考 meditation_focus
/// 播放器界面：Breathing/Meditation音频
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class MeditationFocusV2 extends StatefulWidget {
  const MeditationFocusV2({super.key});

  @override
  State<MeditationFocusV2> createState() => _MeditationFocusV2State();
}

class _MeditationFocusV2State extends State<MeditationFocusV2> {
  final double _progress = 0.37;
  String _atmosphere = 'Soft Rain';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Text('SEASONS', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF7c5cfc))),
                const Spacer(),
                Icon(Icons.settings, color: Colors.white54, size: 20),
              ]),
            ),
            const Spacer(),

            // Title
            Text(AppLocalizations.of(context).t('meditation_breathing'), style: TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).t('meditation_10min_grounding'), style: TextStyle(fontSize: 14, color: Colors.white54)),

            const SizedBox(height: 40),

            // Progress ring
            SizedBox(
              width: 200, height: 200,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 200, height: 200, child: CircularProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white12,
                  color: Color(0xFF7c5cfc),
                  strokeWidth: 4,
                )),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${(_progress * 10).toStringAsFixed(0)}:${((_progress * 600) % 60).toStringAsFixed(0).padLeft(2, '0')}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('10:00', style: TextStyle(fontSize: 14, color: Colors.white38)),
                ]),
              ]),
            ),

            const SizedBox(height: 30),

            // Controls
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.replay_10, color: Colors.white54, size: 28)),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  // Toggle play/pause meditation audio
                },
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Color(0xFF533afd), shape: BoxShape.circle),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(onPressed: () {}, icon: Icon(Icons.forward_10, color: Colors.white54, size: 28)),
            ]),

            const Spacer(),

            // Atmosphere Layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).t('meditation_atmosphere'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(spacing: 10, children: [
                  ('Soft Rain', Icons.water_drop),
                  ('Morning Forest', Icons.forest),
                  ('Sanctuary', Icons.spa),
                  ('Season', Icons.wb_sunny),
                ].map((a) => GestureDetector(
                  onTap: () => setState(() => _atmosphere = a.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _atmosphere == a.$1 ? Color(0xFF533afd).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _atmosphere == a.$1 ? Color(0xFF533afd) : Colors.white12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(a.$2, size: 16, color: _atmosphere == a.$1 ? Color(0xFF7c5cfc) : Colors.white38),
                      const SizedBox(width: 6),
                      Text(a.$1, style: TextStyle(fontSize: 12, color: _atmosphere == a.$1 ? Colors.white : Colors.white54)),
                    ]),
                  ),
                )).toList()),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
