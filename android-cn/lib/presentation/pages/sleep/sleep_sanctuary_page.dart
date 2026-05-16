/// Sleep Sanctuary Page — Reference: sleep_sanctuary
/// "Currently Playing: Midnight Rainfall"
///
/// Structure:
/// 1. Now playing with progress
/// 2. Nature layer selector (Rain/Forest/Waves)
/// 3. Bedtime Tales section
/// 4. More sleep content
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class SleepSanctuaryPage extends StatefulWidget {
  const SleepSanctuaryPage({super.key});

  @override
  State<SleepSanctuaryPage> createState() => _SleepSanctuaryPageState();
}

class _SleepSanctuaryPageState extends State<SleepSanctuaryPage> {
  bool _isPlaying = true;
  int _selectedLayer = 0;
  final double _progress = 0.645; // 12:45 / 20:00

  static const _layers = [
    _Layer('Rain', Icons.water_drop),
    _Layer('Forest', Icons.forest),
    _Layer('Waves', Icons.tsunami),
  ];

  static const _tales = [
    _Tale('The Moonlit Garden', '24m', Icons.nights_stay),
    _Tale('Whispers of the Wind', '18m', Icons.air),
    _Tale('The Quiet River', '32m', Icons.water),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white70),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置功能开发中'), duration: Duration(seconds: 1))),
                  ),
                  Text('数字净心', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: ShunShiTypography.sansFamily,
                  )),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Spacer(flex: 2),

            // ── Now Playing ──
            Text('正在播放', style: TextStyle(
              fontSize: 13, color: Colors.white54,
              fontFamily: ShunShiTypography.sansFamily, letterSpacing: 1,
            )),
            const SizedBox(height: 16),
            Text('午夜雨声', style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
            )),
            const SizedBox(height: 24),

            // Play/Pause
            GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 36, color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('12:45', style: TextStyle(
                        fontSize: 12, color: Colors.white38, fontFamily: ShunShiTypography.sansFamily,
                      )),
                      Text('20:00', style: TextStyle(
                        fontSize: 12, color: Colors.white38, fontFamily: ShunShiTypography.sansFamily,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sound wave icon
            const Icon(Icons.graphic_eq, size: 28, color: Color(0xFF8B5CF6)),

            const Spacer(),

            // ── Nature Layer ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nature's Layer", style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: Colors.white70, fontFamily: ShunShiTypography.sansFamily,
                  )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_layers.length, (i) {
                      final l = _layers[i];
                      final selected = i == _selectedLayer;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLayer = i),
                        child: Column(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(l.icon, size: 24,
                                color: selected ? const Color(0xFF8B5CF6) : Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(l.name, style: TextStyle(
                              fontSize: 11,
                              color: selected ? const Color(0xFF8B5CF6) : Colors.white38,
                              fontFamily: ShunShiTypography.sansFamily,
                            )),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Bedtime Tales ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('睡前故事', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  const SizedBox(height: 4),
                  Text('温柔地进入梦乡。', style: TextStyle(
                    fontSize: 13, color: Colors.white54, fontFamily: ShunShiTypography.sansFamily,
                  )),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/sleep-stories'),
                    child: Text('查看全部', style: TextStyle(
                      fontSize: 13, color: const Color(0xFF8B5CF6), fontFamily: ShunShiTypography.sansFamily,
                    )),
                  ),
                  const SizedBox(height: 16),
                  ..._tales.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(t.icon, size: 22, color: const Color(0xFF8B5CF6)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.title, style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500,
                            color: Colors.white, fontFamily: ShunShiTypography.sansFamily,
                          )),
                          Text(t.duration, style: TextStyle(
                            fontSize: 12, color: Colors.white38, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ]),
                      ),
                      const Icon(Icons.play_circle_outline, size: 28, color: Color(0xFF8B5CF6)),
                    ]),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Layer {
  final String name;
  final IconData icon;
  const _Layer(this.name, this.icon);
}

class _Tale {
  final String title;
  final String duration;
  final IconData icon;
  const _Tale(this.title, this.duration, this.icon);
}
