// Seven Day Journey Component
// Part of Ultimate UI Structure

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

// ==================== Seven Day Journey ====================

class SevenDayJourney extends StatelessWidget {
  final String solarTerm;
  final List<JourneyDay> days;
  final int currentDay;
  final Function(int)? onDayTap;
  
  const SevenDayJourney({
    super.key,
    required this.solarTerm,
    required this.days,
    this.currentDay = 1,
    this.onDayTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '📆 7-Day Journey',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isCompleted = index < currentDay - 1;
              final isCurrent = index == currentDay - 1;
              
              return _JourneyDayCard(
                day: day,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                onTap: () => onDayTap?.call(index + 1),
              );
            },
          ),
        ),
      ],
    );
  }
}

class JourneyDay {
  final int dayNumber;
  final String title;
  final String? description;
  final bool isKeyDay;
  
  const JourneyDay({
    required this.dayNumber,
    required this.title,
    this.description,
    this.isKeyDay = false,
  });
}

// Sample journey data
List<JourneyDay> getSampleJourney(String solarTerm) {
  switch (solarTerm) {
    case 'Start of Spring':
      return const [
        JourneyDay(dayNumber: 1, title: 'Sleep 15min Earlier', description: 'Get to bed 15min early'),
        JourneyDay(dayNumber: 2, title: 'Ginger-Date Tea', description: 'Warm the middle, dispel cold'),
        JourneyDay(dayNumber: 3, title: 'Foot Soak 8min', description: 'Promote blood circulation'),
        JourneyDay(dayNumber: 4, title: 'Eat Spring Greens', description: 'Spinach, bean sprouts'),
        JourneyDay(dayNumber: 5, title: 'Walk 20min', description: 'Outdoor slow walk'),
        JourneyDay(dayNumber: 6, title: 'Press Taichong', description: 'Soothe Liver Qi'),
        JourneyDay(dayNumber: 7, title: 'Tidy Bedroom', description: 'Create a good sleep environment', isKeyDay: true),
      ];
    case 'Rain Water':
      return const [
        JourneyDay(dayNumber: 1, title: 'Resolve Dampness', description: 'Drink yam porridge'),
        JourneyDay(dayNumber: 2, title: 'Press Yinlingquan', description: 'Key point for dampness'),
        JourneyDay(dayNumber: 3, title: 'Indoor Exercise', description: 'Tai Chi or yoga'),
        JourneyDay(dayNumber: 4, title: 'Light Diet', description: 'Less greasy food'),
        JourneyDay(dayNumber: 5, title: 'Coix Seed Tea', description: 'Resolve dampness'),
        JourneyDay(dayNumber: 6, title: 'Early Sleep', description: 'Before 11pm'),
        JourneyDay(dayNumber: 7, title: 'Weekly Review', description: 'Summarize feelings', isKeyDay: true),
      ];
    default:
      return const [
        JourneyDay(dayNumber: 1, title: 'Day 1 Task', description: 'Simple start'),
        JourneyDay(dayNumber: 2, title: 'Day 2 Task', description: 'Keep going'),
        JourneyDay(dayNumber: 3, title: 'Day 3 Task', description: 'Build the habit'),
        JourneyDay(dayNumber: 4, title: 'Day 4 Task', description: 'Deepen the practice'),
        JourneyDay(dayNumber: 5, title: 'Day 5 Task', description: 'Review and adjust'),
        JourneyDay(dayNumber: 6, title: 'Day 6 Task', description: 'Maintain momentum'),
        JourneyDay(dayNumber: 7, title: 'Day 7 Wrap-up', description: 'Close the loop', isKeyDay: true),
      ];
  }
}

class _JourneyDayCard extends StatelessWidget {
  final JourneyDay day;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback? onTap;
  
  const _JourneyDayCard({
    required this.day,
    this.isCompleted = false,
    this.isCurrent = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? statusIcon;
    
    if (isCompleted) {
      backgroundColor = const Color(0xFF4CAF50).withAlpha(26);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF388E3C);
      statusIcon = Icons.check_circle;
    } else if (isCurrent) {
      backgroundColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFC107);
      textColor = const Color(0xFFF57C00);
      statusIcon = Icons.play_circle_filled;
    } else {
      backgroundColor = isDark ? ShunShiColors.darkSurface : Colors.white;
      borderColor = isDark ? ShunShiColors.darkBorder : Colors.grey.shade300;
      textColor = isDark ? ShunShiColors.darkTextSecondary : Colors.grey.shade600;
      statusIcon = null;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: borderColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (statusIcon != null)
                  Icon(statusIcon, size: 16, color: textColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              day.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (day.description != null) ...[
              const SizedBox(height: 4),
              Text(
                day.description!,
                style: TextStyle(
                  color: textColor.withAlpha(179),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (day.isKeyDay) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Key Day',
                  style: TextStyle(
                    color: Color(0xFFF57C00),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== Family Status View ====================

class FamilyStatusCard extends StatelessWidget {
  final String memberName;
  final String relationship; // Father, Mother, Spouse
  final String status; // stable, concern, attention
  final String? suggestion;
  final VoidCallback? onTap;
  final VoidCallback? onContact;
  
  const FamilyStatusCard({
    super.key,
    required this.memberName,
    required this.relationship,
    required this.status,
    this.suggestion,
    this.onTap,
    this.onContact,
  });
  
  Color get statusColor {
    switch (status) {
      case 'stable':
        return const Color(0xFF4CAF50);
      case 'concern':
        return const Color(0xFFFFC107);
      case 'attention':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF4CAF50);
    }
  }
  
  String get statusText {
    switch (status) {
      case 'stable':
        return 'Stable';
      case 'concern':
        return 'Care Suggested';
      case 'attention':
        return 'Needs Attention';
      default:
        return 'Stable';
    }
  }
  
  IconData get statusIcon {
    switch (status) {
      case 'stable':
        return Icons.check_circle;
      case 'concern':
        return Icons.warning_amber;
      case 'attention':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: statusColor.withAlpha(26),
                child: Text(
                  memberName[0],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          memberName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          relationship,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (suggestion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        suggestion!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Contact button
              if (onContact != null)
                IconButton(
                  onPressed: onContact,
                  icon: const Icon(Icons.phone),
                  color: const Color(0xFF4CAF50),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Content Detail Template ====================

class ContentDetailTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Widget? media;
  final List<String> steps;
  final int? durationMinutes;
  final List<String> contraindications;
  final List<String> whenToUse;
  
  const ContentDetailTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.media,
    this.steps = const [],
    this.durationMinutes,
    this.contraindications = const [],
    this.whenToUse = const [],
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          // Media (image/video)
          if (media != null) ...[
            const SizedBox(height: 16),
            media!,
          ],
          
          // Duration
          if (durationMinutes != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer, size: 20, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  'Suggested duration: $durationMinutes min',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          
          // Steps
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          // Contraindications
          if (contraindications.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Precautions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...contraindications.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $c', style: const TextStyle(color: Color(0xFFE65100))),
                  )),
                ],
              ),
            ),
          ],
          
          // When to use
          if (whenToUse.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Best Time to Practice',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: whenToUse.map((w) => Chip(
                label: Text(w),
                backgroundColor: const Color(0xFFE8F5E9),
              )).toList(),
            ),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
