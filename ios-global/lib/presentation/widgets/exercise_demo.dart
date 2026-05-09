import 'package:flutter/material.dart';
import '../../design_system/theme.dart';
import '../../design_system/theme_helper.dart';

/// 八段锦式名数据
class _BaDuanJinStep {
  final String name;
  final String description;
  final IconData icon;
  final String duration;

  const _BaDuanJinStep({
    required this.name,
    required this.description,
    required this.icon,
    required this.duration,
  });
}

const List<_BaDuanJinStep> _kSteps = [
  _BaDuanJinStep(
    name: '两手托天理三焦',
    description: '双手交叉上托，拉伸脊柱，调理三焦气机',
    icon: Icons.arrow_upward,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '左右开弓似射雕',
    description: '马步扩胸，增强肺功能，舒展胸臂',
    icon: Icons.open_in_full,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '调理脾胃须单举',
    description: '左右交替上举，调理脾胃升降功能',
    icon: Icons.vertical_align_top,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '五劳七伤往后瞧',
    description: '头部左右转动，缓解颈肩疲劳',
    icon: Icons.rotate_left,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '摇头摆尾去心火',
    description: '转腰摆臀，清心降火，疏通督脉',
    icon: Icons.sports_gymnastics,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '双手攀足固肾腰',
    description: '弯腰触足，强腰固肾，拉伸膀胱经',
    icon: Icons.accessibility_new,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '攥拳怒目增气力',
    description: '握拳瞪目，增强肝气，激发全身力量',
    icon: Icons.front_hand,
    duration: '30秒',
  ),
  _BaDuanJinStep(
    name: '背后七颠百病消',
    description: '踮脚振动，通畅气血，调和全身',
    icon: Icons.waves,
    duration: '30秒',
  ),
];

/// 八段锦功法演示 Widget
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({super.key});

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '八段锦 · 动作分解',
                style: TextStyle(
                  fontFamily: ShunShiTypography.serifFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Text(
                '${_currentPage + 1} / ${_kSteps.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _kSteps.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final step = _kSteps[index];
              return _ExerciseStepCard(
                stepNumber: index + 1,
                step: step,
                isActive: index == _currentPage,
              );
            },
          ),
        ),
        // Page indicator dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _kSteps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? ShunShiColors.primary
                      : ShunShiColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseStepCard extends StatelessWidget {
  final int stepNumber;
  final _BaDuanJinStep step;
  final bool isActive;

  const _ExerciseStepCard({
    required this.stepNumber,
    required this.step,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: isActive ? 0 : 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? ShunShiColors.primary.withValues(alpha: 0.3)
              : AppColors.border(context),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: ShunShiColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Illustration area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Step number background
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ShunShiColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ShunShiColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Stick figure icon
                  Icon(
                    step.icon,
                    size: 72,
                    color: ShunShiColors.primary.withValues(alpha: 0.35),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: ShunShiColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            step.duration,
                            style: TextStyle(
                              fontSize: 10,
                              color: ShunShiColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Text area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第$stepNumber式',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.name,
                    style: TextStyle(
                      fontFamily: ShunShiTypography.serifFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}