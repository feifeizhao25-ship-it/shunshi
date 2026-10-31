/// 功法教学详情页 — 参考UI _5
/// 八段锦·第三式：调理脾胃须单举
/// 
/// 结构（从上到下）:
/// 1. 视频播放器 + 进度条
/// 2. 功法简介
/// 3. 步骤详解（一～四）
/// 4. 呼吸节拍指导（吸气/屏气）
/// 5. CTA: 开始全屏教学
/// 6. 中医原理卡片
/// 7. 心身连接提示
/// 8. 常见错误纠正
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class ExerciseDetailPage extends StatefulWidget {
  final String? exerciseName;
  const ExerciseDetailPage({super.key, this.exerciseName});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  String _breathPhase = 'Get ready';
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
      setState(() => _breathPhase = 'Inhale 4s');
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = 'Hold 2s');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = 'Exhale 6s');
      await Future.delayed(const Duration(seconds: 6));
    }
    if (mounted) setState(() => _breathPhase = 'Get ready');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
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
                          '${widget.exerciseName ?? 'Baduanjin'}· Form 3',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        Text(
                          'Regulate the spleen and stomach: single-arm lift',
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
                        Text('12 min', style: TextStyle(
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
                    'This form stretches the abdomen with an up-and-down pull,'
                    'giving the internal organs a gentle massage. Regular practice can ease indigestion,'
                    'poor appetite, bloating and other spleen-and-stomach discomfort.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                      height: 1.7,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 步骤详解 ──
                  _sectionTitle('Step by step'),
                  const SizedBox(height: 16),
                  _numberedStep('1', 'Opening stance', 'Stand naturally, feet shoulder-width apart, hands relaxed at your sides. Breathe three times and relax.'),
                  _numberedStep('2', 'Left hand lifts', 'Turn the left palm up and raise it above the head, palm to the sky, fingers pointing right. Press the right palm down beside the hip.'),
                  _numberedStep('3', 'Pull and stretch', 'Both hands work like holding up the sky and pressing the earth, creating an up-and-down pull. Keep both arms straight.'),
                  _numberedStep('4', 'Return and switch', 'Bring both hands back to your sides, then lift the right hand and press the left down. Alternate sides, 6 times each.'),
                  const SizedBox(height: 28),

                  // ── 呼吸节拍指导 ──
                  _sectionTitle('Breathing rhythm guide'),
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
                              _isBreathing ? 'Stop' : 'Start guided breathing',
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
                          Text('Start full-screen lesson', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 中医原理 ──
                  _infoCard(
                    'Principle',
                    'The spleen and stomach are the foundation of postnatal health and the source of qi and blood. When one arm lifts, one side of the abdomen is stretched and the other compressed,'
                    'massaging the spleen and stomach. The movement directly stimulates the areas along the Spleen and Stomach meridians.',
                    ShunShiColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // ── 心身连接 ──
                  _infoCard(
                    'Mind-body link',
                    'Keep your face relaxed and the corners of your mouth slightly lifted during practice. A tense face spreads tension through the body,'
                    'while a relaxed face makes the movement smoother. Imagine stretching in a garden at dawn.',
                    ShunShiColors.apricot,
                  ),
                  const SizedBox(height: 12),

                  // ── 常见错误 ──
                  _infoCard(
                    'Common mistakes',
                    '• Shrugging: don\'t hunch the shoulders as the arm rises; keep shoulders down and elbows relaxed\n'
                    '• Holding your breath: match movement and breath — inhale as you rise, exhale as you lower\n'
                    '• Leaning back too far: keep the torso upright; don\'t over-arch to get a bigger stretch',
                    ShunShiColors.textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // ── 晨练建议 ──
                  _infoCard(
                    'Morning practice tips',
                    'Best time: 30 minutes after sunrise until 9 a.m., when yang energy rises,'
                    'which suits the lifting movements of Baduanjin. Practise outdoors in fresh air if you can.',
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


