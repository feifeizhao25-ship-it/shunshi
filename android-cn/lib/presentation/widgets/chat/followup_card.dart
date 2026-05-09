import 'package:flutter/material.dart';
import 'package:shunshi/core/theme/shunshi_colors.dart';
import 'package:shunshi/core/theme/shunshi_text_styles.dart';

/// Follow-up 跟进卡片 - AI 发送对话后的跟进提醒
class FollowUpCard extends StatelessWidget {
  final Map<String, dynamic> followUpData;
  final ValueChanged<String>? onDismiss;
  final ValueChanged<String>? onSnooze;

  const FollowUpCard({
    super.key,
    required this.followUpData,
    this.onDismiss,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final followUpType = followUpData['type'] ?? 'care_reminder';
    final title = followUpData['title'] ?? '';
    final description = followUpData['description'] ?? '';
    final scheduledAt = followUpData['scheduled_at'] ?? '';
    final priority = followUpData['priority'] ?? 'normal';

    final emoji = _getEmoji(followUpType);
    final color = _getColor(followUpType);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: ShunshiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ShunshiTextStyles.heading.copyWith(fontWeight: FontWeight.w600)),
                      if (scheduledAt.isNotEmpty)
                        Text(_formatTime(scheduledAt), style: ShunshiTextStyles.caption.copyWith(color: ShunshiColors.textHint)),
                    ],
                  ),
                ),
                if (priority == 'high')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: ShunshiColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text('重要', style: ShunshiTextStyles.overline.copyWith(color: ShunshiColors.error)),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(description, style: ShunshiTextStyles.body.copyWith(color: ShunshiColors.textSecondary, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDismiss?.call(followUpData['id'] ?? ''),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ShunshiColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('暂不提醒', style: ShunshiTextStyles.buttonSmall.copyWith(color: ShunshiColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => onSnooze?.call(followUpData['id'] ?? ''),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('稍后提醒', style: ShunshiTextStyles.buttonSmall.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String type) {
    switch (type) {
      case 'daily_checkin': return '📋';
      case 'mood_followup': return '💚';
      case 'sleep_followup': return '😴';
      case 'care_reminder': return '🤗';
      case 'subscription_expiring': return '🔔';
      default: return '📌';
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'daily_checkin': return ShunshiColors.calm;
      case 'mood_followup': return ShunshiColors.success;
      case 'sleep_followup': return const Color(0xFF7E57C2);
      case 'care_reminder': return ShunshiColors.warm;
      case 'subscription_expiring': return ShunshiColors.error;
      default: return ShunshiColors.primary;
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }
}
