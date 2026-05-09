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
  String _breathPhase = '准备';
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
      setState(() => _breathPhase = '吸气 4秒');
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = '屏气 2秒');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_isBreathing) break;
      setState(() => _breathPhase = '呼气 6秒');
      await Future.delayed(const Duration(seconds: 6));
    }
    if (mounted) setState(() => _breathPhase = '准备');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
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
                          '${widget.exerciseName ?? '八段锦'}·第三式',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: ShunShiTypography.serifFamily,
                          ),
                        ),
                        Text(
                          '调理脾胃须单举',
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
                        Text('12分钟', style: TextStyle(
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
                    '这一式通过上下对拉的动作，充分伸展腹部腔体，'
                    '对内脏进行柔和的按摩。长期练习可以改善消化不良、'
                    '食欲不振、腹胀等脾胃不适症状。',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                      height: 1.7,
                      fontFamily: ShunShiTypography.sansFamily,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 步骤详解 ──
                  _sectionTitle('步骤详解'),
                  const SizedBox(height: 16),
                  _numberedStep('一', '起势', '自然站立，两脚与肩同宽，双手自然垂于体侧。调息三次，身心放松。'),
                  _numberedStep('二', '左手翻托', '左手翻掌上举至头顶上方，掌心朝天，指尖向右。右手翻掌下按至髋侧。'),
                  _numberedStep('三', '对拉伸展', '双手如分别托天按地，形成上下对拉。注意两臂保持伸直，不要弯曲。'),
                  _numberedStep('四', '还原换手', '双手还原至体侧，换右手翻托上举，左手下按。左右交替，各做6次。'),
                  const SizedBox(height: 28),

                  // ── 呼吸节拍指导 ──
                  _sectionTitle('呼吸节拍指导'),
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
                            _breathBar('吸气', '4s', ShunShiColors.primary),
                            const SizedBox(width: 12),
                            _breathBar('屏气', '2s', ShunShiColors.gold),
                            const SizedBox(width: 12),
                            _breathBar('呼气', '6s', ShunShiColors.apricot),
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
                              _isBreathing ? '停止' : '开始跟练呼吸',
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
                          Text('开始全屏教学', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 中医原理 ──
                  _infoCard(
                    '中医原理',
                    '脾胃为后天之本，气血生化之源。单臂上举时，一侧的腹腔被拉伸，另一侧被压缩，'
                    '形成对脾胃的按摩效应。这个动作直接刺激足太阴脾经和足阳明胃经的循行区域。',
                    ShunShiColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // ── 心身连接 ──
                  _infoCard(
                    '心身连接',
                    '练习时面部保持放松，嘴角微微上扬。紧张的面部会传导到全身，'
                    '放松的面部能让动作更加流畅自然。想象自己在清晨的花园里舒展身体。',
                    ShunShiColors.apricot,
                  ),
                  const SizedBox(height: 12),

                  // ── 常见错误 ──
                  _infoCard(
                    '常见错误',
                    '• 耸肩：手臂上举时肩膀不要耸起，保持沉肩坠肘\n'
                    '• 憋气：动作和呼吸配合，上升时吸气，下落时呼气\n'
                    '• 过度后仰：上身保持中正，不要为了拉伸而过度后仰',
                    ShunShiColors.textSecondary,
                  ),
                  const SizedBox(height: 12),

                  // ── 晨练建议 ──
                  _infoCard(
                    '晨练建议',
                    '最佳练习时间：日出后30分钟至上午9点。此时阳气升发，'
                    '与八段锦的升举动作相得益彰。建议在空气清新的户外练习。',
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


