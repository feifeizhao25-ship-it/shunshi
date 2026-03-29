// Seven Day Journey Component
// Part of Ultimate UI Structure

import 'package:flutter/material.dart';

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
            '📆 7天游程',
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
    case '立春':
      return const [
        JourneyDay(dayNumber: 1, title: '早点睡15分钟', description: '提前15分钟上床'),
        JourneyDay(dayNumber: 2, title: '喝一杯姜枣茶', description: '温中散寒'),
        JourneyDay(dayNumber: 3, title: '泡脚8分钟', description: '促进血液循环'),
        JourneyDay(dayNumber: 4, title: '吃些春菜', description: '菠菜、豆芽'),
        JourneyDay(dayNumber: 5, title: '散步20分钟', description: '户外慢走'),
        JourneyDay(dayNumber: 6, title: '按摩太冲穴', description: '疏肝理气'),
        JourneyDay(dayNumber: 7, title: '整理卧室', description: '营造好睡眠环境', isKeyDay: true),
      ];
    case '雨水':
      return const [
        JourneyDay(dayNumber: 1, title: '祛湿健脾', description: '喝山药粥'),
        JourneyDay(dayNumber: 2, title: '按揉阴陵泉', description: '祛湿要穴'),
        JourneyDay(dayNumber: 3, title: '室内运动', description: '太极或瑜伽'),
        JourneyDay(dayNumber: 4, title: '清淡饮食', description: '少油腻'),
        JourneyDay(dayNumber: 5, title: '泡杯薏仁茶', description: '祛湿'),
        JourneyDay(dayNumber: 6, title: '早睡', description: '23点前'),
        JourneyDay(dayNumber: 7, title: '回顾一周', description: '总结感受', isKeyDay: true),
      ];
    default:
      return const [
        JourneyDay(dayNumber: 1, title: 'Day 1 任务', description: '简单开始'),
        JourneyDay(dayNumber: 2, title: 'Day 2 任务', description: '继续坚持'),
        JourneyDay(dayNumber: 3, title: 'Day 3 任务', description: '养成习惯'),
        JourneyDay(dayNumber: 4, title: 'Day 4 任务', description: '加深印象'),
        JourneyDay(dayNumber: 5, title: 'Day 5 任务', description: '回顾调整'),
        JourneyDay(dayNumber: 6, title: 'Day 6 任务', description: '保持状态'),
        JourneyDay(dayNumber: 7, title: 'Day 7 总结', description: '完成闭环', isKeyDay: true),
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
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
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
                  '关键日',
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
  final String relationship; // 爸爸, 妈妈, 配偶
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
        return '状态平稳';
      case 'concern':
        return '建议关心';
      case 'attention':
        return '需要关注';
      default:
        return '状态平稳';
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
                  '建议时长: $durationMinutes 分钟',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          
          // Steps
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '操作步骤',
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
                        '注意事项',
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
              '适合什么时候做',
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
