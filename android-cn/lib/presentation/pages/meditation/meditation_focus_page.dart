/// Meditation Focus Page — Reference: meditation_focus
/// "呼吸·变化" — 10 Min Grounding meditation player
///
/// Structure:
/// 1. Timer display with circular progress
/// 2. Play controls (replay 10s / play-pause / forward 10s)
/// 3. Atmosphere layer selector (Rain/Forest/Sanctuary/Season)
/// 4. Check-in CTA
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class MeditationFocusPage extends StatefulWidget {
  const MeditationFocusPage({super.key});

  @override
  State<MeditationFocusPage> createState() => _MeditationFocusPageState();
}

class _MeditationFocusPageState extends State<MeditationFocusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _timer;
  int _elapsedSeconds = 222; // 3:42 demo
  final int _totalSeconds = 600; // 10 min
  bool _isPlaying = false;
  int _selectedAtmosphere = 0;

  static const _atmospheres = [
    _Atmosphere('细雨', Icons.water_drop),
    _Atmosphere('Morning Forest', Icons.forest),
    _Atmosphere('Sanctuary', Icons.spa),
    _Atmosphere('节气', Icons.wb_sunny),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _progressController.value = _elapsedSeconds / _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_elapsedSeconds < _totalSeconds && mounted) {
          setState(() {
            _elapsedSeconds++;
            _progressController.value = _elapsedSeconds / _totalSeconds;
          });
        } else {
          _timer?.cancel();
          setState(() => _isPlaying = false);
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;
    final surfaceLow = isDark ? ShunShiColors.darkSurfaceContainerLow : ShunShiColors.surfaceContainerLow;

    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text('顺时', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: ShunShiColors.primary, fontFamily: ShunShiTypography.serifFamily,
                    )),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 22),
                    color: ShunShiColors.textSecondary,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ── Title ──
            Text('呼吸·变化', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 4),
            Text('10 Min · Grounding', style: TextStyle(
              fontSize: 14, color: ShunShiColors.textSecondary,
              fontFamily: ShunShiTypography.sansFamily,
            )),
            const SizedBox(height: 40),

            // ── Circular Progress ──
            SizedBox(
              width: 220, height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => CircularProgressIndicator(
                      value: _progressController.value,
                      strokeWidth: 4,
                      backgroundColor: surfaceLow,
                      color: ShunShiColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatTime(_elapsedSeconds), style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w300,
                        color: ShunShiColors.textPrimary,
                        fontFamily: ShunShiTypography.sansFamily,
                      )),
                      Text(_formatTime(_totalSeconds), style: TextStyle(
                        fontSize: 14, color: ShunShiColors.textTertiary,
                        fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlButton(Icons.replay_10, () {
                  setState(() {
                    _elapsedSeconds = (_elapsedSeconds - 10).clamp(0, _totalSeconds);
                    _progressController.value = _elapsedSeconds / _totalSeconds;
                  });
                }),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: ShunShiColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36, color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _controlButton(Icons.forward_10, () {
                  setState(() {
                    _elapsedSeconds = (_elapsedSeconds + 10).clamp(0, _totalSeconds);
                    _progressController.value = _elapsedSeconds / _totalSeconds;
                  });
                }),
              ],
            ),
            const SizedBox(height: 40),

            // ── Atmosphere Layer ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('氛围层', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: ShunShiColors.textSecondary,
                    fontFamily: ShunShiTypography.sansFamily,
                  )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_atmospheres.length, (i) => _atmosphereButton(i)),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ── Check-in CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.self_improvement, size: 18),
                  label: Text('打卡', style: TextStyle(
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

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: ShunShiColors.textSecondary),
      ),
    );
  }

  Widget _atmosphereButton(int index) {
    final a = _atmospheres[index];
    final selected = index == _selectedAtmosphere;
    return GestureDetector(
      onTap: () => setState(() => _selectedAtmosphere = index),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? ShunShiColors.primary.withValues(alpha: 0.12)
                  : ShunShiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(a.icon, size: 22,
              color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(a.name, style: TextStyle(
            fontSize: 10,
            color: selected ? ShunShiColors.primary : ShunShiColors.textTertiary,
            fontFamily: ShunShiTypography.sansFamily,
          )),
        ],
      ),
    );
  }
}

class _Atmosphere {
  final String name;
  final IconData icon;
  const _Atmosphere(this.name, this.icon);
}
