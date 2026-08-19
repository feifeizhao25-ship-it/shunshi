import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/solar_term_ext.dart';
import '../../../domain/entities/solar_term.dart';
import '../../../core/theme/app_theme.dart';

class HomePremiumHero extends StatelessWidget {
  final String greeting;
  final String userName;
  final String dateText;
  final int completed;
  final int total;
  final SolarTerm? solarTerm;
  final VoidCallback onSolarTermTap;
  final VoidCallback onMoodTap;

  const HomePremiumHero({
    super.key,
    required this.greeting,
    required this.userName,
    required this.dateText,
    required this.completed,
    required this.total,
    this.solarTerm,
    required this.onSolarTermTap,
    required this.onMoodTap,
  });

  double get progress => total > 0 ? completed / total : 0;

  @override
  Widget build(BuildContext context) {
    final themeColor = solarTerm?.themeColor ?? AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Elements
          if (solarTerm != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor.withValues(alpha: 0.8), themeColor.withValues(alpha: 0.4), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
              ),
            ),
            
          if (solarTerm != null)
            Positioned(
              left: 100, top: -50,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withValues(alpha: 0.15),
                ),
              ).blur(radius: 60),
            ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$greeting，$userName', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(dateText, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                        ],
                      ),
                    ),
                    
                    if (solarTerm != null)
                      GestureDetector(
                        onTap: onSolarTermTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: Colors.white.withValues(alpha: 0.2), // ultraThinMaterial approximation
                              child: Column(
                                children: [
                                  Text(solarTerm!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text(solarTerm!.nameEn.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Wellness Progress Strip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Progress Circle
                      SizedBox(
                        width: 44, height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 4,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                              color: Colors.white,
                            ),
                            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('今日养生活度', style: TextStyle(fontSize: 12, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(total > 0 ? '已完成 $completed/$total 项建议' : '新的一天，探索生活的节奏', 
                                style: const TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                      // Mini Mood Entry
                      DailyPulseIconRow(onMoodTap: onMoodTap),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyPulseIconRow extends StatefulWidget {
  final VoidCallback onMoodTap;
  const DailyPulseIconRow({super.key, required this.onMoodTap});

  @override
  State<DailyPulseIconRow> createState() => _DailyPulseIconRowState();
}

class _DailyPulseIconRowState extends State<DailyPulseIconRow> {
  String? recordedMood;
  final moods = [
    (Icons.bolt, "有活力"),
    (Icons.eco, "轻松"),
    (Icons.grid_view_sharp, "平稳"),
    (Icons.bedtime, "疲惫"),
    (Icons.air, "压力"),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: moods.map((item) {
        final isSelected = recordedMood == item.$2;
        return GestureDetector(
          onTap: () {
            setState(() => recordedMood = item.$2);
            widget.onMoodTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(
              item.$1, 
              size: 14, 
              color: isSelected ? AppColors.primary : Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}

extension BlurExtension on Widget {
  Widget blur({double radius = 10}) {
    return ImageFilterWidget(
      imageFilter: ImageFilter.blur(sigmaX: radius, sigmaY: radius),
      child: this,
    );
  }
}

class ImageFilterWidget extends StatelessWidget {
  final ImageFilter imageFilter;
  final Widget child;

  const ImageFilterWidget({super.key, required this.imageFilter, required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(filter: imageFilter, child: child);
  }
}

class SmartInsightHub extends StatefulWidget {
  final String focusTitle;
  final String summary;
  final VoidCallback onOpenPlan;

  const SmartInsightHub({
    super.key,
    required this.focusTitle,
    required this.summary,
    required this.onOpenPlan,
  });

  @override
  State<SmartInsightHub> createState() => _SmartInsightHubState();
}

class _SmartInsightHubState extends State<SmartInsightHub> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('顺时建议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Row(
              children: [
                _buildTab('计划', 0),
                const SizedBox(width: 8),
                _buildTab('陪伴', 1),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.list_alt, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.focusTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(widget.summary, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onOpenPlan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('查看每日计划', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class HomeQuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  HomeQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class HealthToolboxGrid extends StatelessWidget {
  final List<HomeQuickAction> actions;
  final Function(int) onTap;

  const HealthToolboxGrid({
    super.key,
    required this.actions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('健康工具箱', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: action.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(action.icon, color: action.color, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(action.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(action.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class SolarTermPoemCard extends StatelessWidget {
  final SolarTerm solarTerm;
  final VoidCallback onTap;

  const SolarTermPoemCard({
    super.key,
    required this.solarTerm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = solarTerm.themeColor;
    final poem = solarTerm.poem;
    
    if (poem == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, themeColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('节气诗词', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(poem.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.auto_stories_rounded, color: themeColor.withValues(alpha: 0.6), size: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              poem.content,
              style: const TextStyle(fontSize: 17, height: 1.8, fontFamily: 'Serif', letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '【${poem.dynasty}】${poem.author}',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary, fontFamily: 'Serif'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('查看详细解读', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.white, size: 12),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

