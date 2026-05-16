/// Qigong教学Details页 — 参考UI _5
/// Baduanjin·第三式：Regulate Spleen-Stomach: Single-Arm Raise
/// 
/// 结构（从上到下）:
/// 1. 视频播放器 + 进度条
/// 2. Qigong简介
/// 3. Step-by-Step Guide（一～四）
/// 4. Breathing Rhythm Guide（Inhale/Hold）
/// 5. CTA: Start Full-Screen Teaching
/// 6. TCM Theory卡片
/// 7. Mind-Body Connection提示
/// 8. Common Mistakes纠正
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class ExerciseDetailPage extends StatefulWidget {
  final String? exerciseName;
  const ExerciseDetailPage({super.key, this.exerciseName});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  String _breathPhase = 'Preparation';
  bool _isBreathing = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() => _isBreathing = true);
    _breathCycle();
  }

  void _breathCycle() async {
    while (_isBreathing) {
      if (!mounted) break;
      setState(() => _breathPhase = 'Inhale for 4 seconds');
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = 'Hold for 2 seconds');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = 'Exhale for 6 seconds');
      await Future.delayed(const Duration(seconds: 6));
    }
    if (mounted) setState(() => _breathPhase = 'Preparation');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()), elevation: 0),
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: ShunShiColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Mountain landscape placeholder
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF3D5A80),
                          Color(0xFF2D5A3D),
                          Color(0xFF144227),
                        ],
                      ),
                    ),
                  ),
                  // Play button overlay
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, size: 36, color: ShunShiColors.primary),
                    ),
                  ),
                  // Progress bar
                  Positioned(
                    left: 20, right: 20, bottom: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + duration
                        Text(
                          'QI GONG TUTORIAL',
                          style: TextStyle(
                            fontFamily: ShunShiTypography.sansFamily,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.exerciseName ?? 'Baduanjin · Third Form',),
                        Text(
                          'Regulate Spleen-Stomach: Single-Arm Raise',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).t('exercise_12min'), style: TextStyle(
                          fontSize: 12, color: Colors.white70, fontFamily: ShunShiTypography.sansFamily,
                        )),
                        const Spacer(),
                        Text('3/8', style: TextStyle(
                          fontSize: 12, color: Colors.white70, fontFamily: ShunShiTypography.sansFamily,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 简介 ──
                  const Text(
                    'This movement fully stretches the abdominal cavity through up-down stretching, '
                    'providing a gentle massage to the internal organs. Long-term practice can improve indigestion, '
                    'poor appetite, bloating, and other Spleen-Stomach discomfort.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                      height: 1.7,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Step-by-Step Guide ──
                  _sectionTitle('Step-by-Step Guide'),
                  const SizedBox(height: 16),
                  _numberedStep('1', 'Starting Form', 'Stand naturally with feet shoulder-width apart, arms hanging at sides. Regulate breath three times, relax body and mind.'),
                  _numberedStep('2', 'Left Hand Raise', 'Flip left palm up and raise above head, palm facing up, fingers pointing right. Flip right palm down to hip level.'),
                  _numberedStep('3', 'Opposing Stretch', 'Arms stretch up and down like holding sky and pressing earth. Note: keep both arms straight, do not bend.'),
                  _numberedStep('4', 'Return and Switch', 'Return hands to sides, switch to right arm raise and left arm press. Alternate sides, 6 times each.'),
                  const SizedBox(height: 28),

                  // ── Breathing Rhythm Guide ──
                  _sectionTitle('Breathing Rhythm Guide'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ShunShiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Breathing circle
                        AnimatedBuilder(
                          animation: _breathController,
                          builder: (context, child) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ShunShiColors.primary.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: ShunShiColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _breathPhase,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ShunShiColors.primary,
                                    fontFamily: ShunShiTypography.sansFamily,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Timer bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _breathBar('Inhale', '4s', ShunShiColors.primary),
                            const SizedBox(width: 12),
                            _breathBar('Hold', '2s', ShunShiColors.gold),
                            const SizedBox(width: 12),
                            _breathBar('Exhale', '6s', ShunShiColors.apricot),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Start/stop button
                        GestureDetector(
                          onTap: () {
                            if (_isBreathing) {
                              setState(() => _isBreathing = false);
                            } else {
                              _startBreathing();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isBreathing
                                  ? ShunShiColors.error.withValues(alpha: 0.1)
                                  : ShunShiColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isBreathing ? 'Stop' : 'Start Practice Breathing',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isBreathing ? ShunShiColors.error : Colors.white,
                                fontFamily: ShunShiTypography.sansFamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShunShiColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fullscreen, size: 20),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context).t('exercise_start_fullscreen_teaching'), style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── TCM Theory ──
                  _infoCard(
                    'TCM Theory',
                    'The Spleen-Stomach is the foundation of postnatal life, the source of Qi and Blood production. When one arm raises, one side of the abdominal cavity stretches while the other compresses, '
                    'creating a massage effect on the Spleen-Stomach. This movement directly stimulates the Taiyin Spleen and Yangming Stomach meridian pathways.',
                    ShunShiColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // ── Mind-Body Connection ──
                  _infoCard(
                    'Mind-Body Connection',
                    'Keep your face relaxed during practice, corners of mouth slightly upturned. A tense face transmits tension throughout the body, '
                    'while a relaxed face makes movements smoother and more natural. Imagine yourself stretching in a morning garden.',
                    ShunShiColors.apricot,
                  ),
                  const SizedBox(height: 12),

                  // ── Common Mistakes ──
                  _infoCard(
                    'Common Mistakes',
                    '• Shrug shoulders: do not let shoulders rise when raising arms — keep them dropped and elbows relaxed\n'
                    '• Hold breath: coordinate movement with breathing, inhale on rise, exhale on fall\n'
                    '• Over-arching: keep the torso upright — do not over-arch for the sake of stretching',
                    ShunShiColors.textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // ── Morning Practice Tip:  ──
                  _infoCard(
                    'Morning Practice Tip: ',
                    'Best timing: 30 min after sunrise until Wu hour 9. Yang energy is rising, '
                    'complementing Baduanjin\'s lifting movements. Recommended: practice outdoors in fresh air.',
                    ShunShiColors.calm,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: ShunShiTypography.serifFamily,
    color: ShunShiColors.textPrimary,
  ));

  Widget _numberedStep(String num, String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: ShunShiColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(num, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
            )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary, fontFamily: ShunShiTypography.sansFamily,
              )),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(
                fontSize: 13, color: ShunShiColors.textSecondary, height: 1.6, fontFamily: ShunShiTypography.sansFamily,
              )),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _breathBar(String label, String time, Color color) => Column(
    children: [
      Container(
        width: 60, height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        fontSize: 11, color: color, fontWeight: FontWeight.w500, fontFamily: ShunShiTypography.sansFamily,
      )),
      Text(time, style: TextStyle(
        fontSize: 10, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
      )),
    ],
  );

  Widget _infoCard(String title, String content, Color accentColor) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ShunShiColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: accentColor, fontFamily: ShunShiTypography.sansFamily,
        )),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(
          fontSize: 13, color: ShunShiColors.textSecondary, height: 1.7, fontFamily: ShunShiTypography.sansFamily,
        )),
      ],
    ),
  );
}


