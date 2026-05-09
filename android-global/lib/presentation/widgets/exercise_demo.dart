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
    name: 'Two Hands Hold Up the Heavens',
    description: 'Interlace hands and stretch upward to regulate Sanjiao',
    icon: Icons.arrow_upward,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Draw Bow to Left and Right',
    description: 'Horse stance chest expansion to strengthen Lung function',
    icon: Icons.open_in_full,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Separate Heaven and Earth',
    description: 'Alternate arm raises to regulate Spleen and Stomach',
    icon: Icons.vertical_align_top,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Wise Owl Gazes Backward',
    description: 'Turn head to relieve neck and shoulder tension',
    icon: Icons.rotate_left,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Swing Head and Tail to Clear Heart Fire',
    description: 'Twist waist and hips to clear Heart Fire and open Du Mai',
    icon: Icons.sports_gymnastics,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Touch Toes to Strengthen Kidneys',
    description: 'Bend forward to strengthen Kidneys and Bladder meridian',
    icon: Icons.accessibility_new,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Clench Fists and Glare to Build Power',
    description: 'Clench fists with fierce gaze to boost Liver Qi and strength',
    icon: Icons.front_hand,
    duration: '30s',
  ),
  _BaDuanJinStep(
    name: 'Seven Bounces to Dispel All Illness',
    description: 'Rise on toes and bounce to circulate Qi and Blood',
    icon: Icons.waves,
    duration: '30s',
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
                'Baduanjin · Step by Step',
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
                    'Move $stepNumber',
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