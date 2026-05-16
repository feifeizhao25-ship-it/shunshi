/// Movement Player Page — Reference: movement_player
/// "Late Summer Transition · Gentle Flow Ritual"
///
/// Structure:
/// 1. Session header with season + type
/// 2. Timer
/// 3. Guided audio toggle
/// 4. Quote
/// 5. Save to Rituals CTA
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class MovementPlayerPage extends StatefulWidget {
  const MovementPlayerPage({super.key});

  @override
  State<MovementPlayerPage> createState() => _MovementPlayerPageState();
}

class _MovementPlayerPageState extends State<MovementPlayerPage> {
  bool _isPlaying = false;
  bool _guidedAudio = true;
  bool _rainTexture = false;
  int _elapsedSeconds = 522; // 8:42
  final int _totalSeconds = 900; // 15 min
  Timer? _timer;

  String _formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsedSeconds < _totalSeconds && mounted) {
          setState(() => _elapsedSeconds++);
        } else {
          _timer?.cancel();
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text('顺时', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: ShunShiColors.primary, fontFamily: ShunShiTypography.serifFamily,
                )),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),
            const Spacer(),

            // ── Session Info ──
            Text('练习进行中', style: TextStyle(
              fontSize: 13, color: ShunShiColors.textTertiary,
              fontFamily: ShunShiTypography.sansFamily, letterSpacing: 1,
            )),
            const SizedBox(height: 16),
            Text('晚夏过渡', style: TextStyle(
              fontSize: 14, color: ShunShiColors.primary,
              fontFamily: ShunShiTypography.sansFamily, fontWeight: FontWeight.w500,
            )),
            Text('Gentle Flow Ritual', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoChip(Icons.schedule, '15 mins'),
                const SizedBox(width: 16),
                _infoChip(Icons.energy_savings_leaf, 'Restorative'),
              ],
            ),
            const SizedBox(height: 8),
            if (_isPlaying)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spatial_audio_off, size: 16, color: ShunShiColors.primary),
                  const SizedBox(width: 4),
                  Text('Spatial Audio Active', style: TextStyle(
                    fontSize: 12, color: ShunShiColors.primary,
                    fontFamily: ShunShiTypography.sansFamily,
                  )),
                ],
              ),
            const SizedBox(height: 32),

            // ── Timer + Controls ──
            Text(_formatTime(_elapsedSeconds), style: TextStyle(
              fontSize: 48, fontWeight: FontWeight.w300,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _isPlaying ? ShunShiColors.primary.withValues(alpha: 0.1) : ShunShiColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 36, color: _isPlaying ? ShunShiColors.primary : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Quote ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '"In this practice, we focus on the element of earth. Find stability through the soles of your feet and let the breath move through your spine like wind through the reeds."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, color: ShunShiColors.textSecondary,
                  height: 1.7, fontStyle: FontStyle.italic,
                  fontFamily: ShunShiTypography.sansFamily,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Toggles ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _toggleRow('Guided Audio', 'Voice instructions', _guidedAudio, (v) => setState(() => _guidedAudio = v)),
                  const SizedBox(height: 8),
                  _toggleRow('Rain Texture', 'Ambient layer', _rainTexture, (v) => setState(() => _rainTexture = v)),
                ],
              ),
            ),

            const Spacer(),

            // ── Save CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: Text('收藏', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                  )),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShunShiColors.primary,
                    side: BorderSide(color: ShunShiColors.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: ShunShiColors.textTertiary),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, fontFamily: ShunShiTypography.sansFamily)),
    ],
  );

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: ShunShiColors.primary),
      ],
    );
  }
}
