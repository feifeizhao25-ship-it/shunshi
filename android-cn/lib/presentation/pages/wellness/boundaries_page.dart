import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../core/theme/shunshi_spacing.dart';
import '../../../core/theme/shunshi_text_styles.dart';

/// 顺时边界公示页 — 清楚告知用户产品边界
class BoundariesPage extends StatelessWidget {
  const BoundariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunshiColors.background,
      appBar: AppBar(
        backgroundColor: ShunshiColors.background,
        foregroundColor: ShunshiColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('产品边界'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ShunshiColors.primary.withValues(alpha: 0.1),
                    ShunshiColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '🌿',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '顺时不是什么',
                    style: ShunshiTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '我们坚守的产品底线，为你的健康负责',
                    style: ShunshiTextStyles.body.copyWith(
                      color: ShunshiColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 顺时不提供
            _SectionTitle(
              emoji: '❌',
              title: '顺时不提供',
              subtitle: '以下内容超出产品范围，可能对你的健康造成风险',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🏥',
              title: '医疗诊断',
              description:
                  '我们不提供任何疾病的诊断服务。身体不适时请及时就医，咨询专业医生。AI 不能替代医学检查和诊断。',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💊',
              title: '药物推荐',
              description:
                  '我们不推荐任何中西药物。用药需在医生指导下进行，擅自用药可能产生严重后果。',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🩺',
              title: '症状分析',
              description:
                  '我们不解读体检报告中的异常指标，不提供"你可能有什么病"之类的推测。',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '📊',
              title: '健康评分',
              description:
                  '我们不给你打分。健康是多维度的，不应该用一个数字来衡量。',
              color: const Color(0xFFE57373),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😰',
              title: '情绪评分',
              description:
                  '我们不评价你的情绪状态。情绪没有好坏之分，每种感受都值得被尊重。',
              color: const Color(0xFFE57373),
            ),

            const SizedBox(height: 32),

            // 顺时提供
            _SectionTitle(
              emoji: '✅',
              title: '顺时提供',
              subtitle: '我们专注于让你生活得更好的方面',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍃',
              title: '生活方式建议',
              description:
                  '根据节气、体质和场景，提供饮食、运动、作息等生活方式建议，帮助你顺应自然节律。',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🌱',
              title: '节气养生指导',
              description:
                  '24节气的饮食调理、茶饮、运动导引、穴位保健和睡眠起居建议，与自然同步生活。',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '💬',
              title: '情绪陪伴',
              description:
                  '在你需要倾听时陪伴你，用温暖的方式回应，不评判、不催促、不诊断。',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '😴',
              title: '睡眠改善建议',
              description:
                  '基于中医理论和生活习惯，提供温和的睡眠改善方法，如泡脚、按摩、放松技巧等。',
              color: const Color(0xFF81C784),
            ),
            const SizedBox(height: 12),
            _BoundaryCard(
              emoji: '🍵',
              title: '食疗与茶饮',
              description:
                  '根据体质推荐时令食材和食疗方案，适合日常养生的茶饮配方。',
              color: const Color(0xFF81C784),
            ),

            const SizedBox(height: 32),

            // 重要提示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '如果你正在经历',
                          style: ShunshiTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '持续的情绪低落、失眠、食欲不振、有自我伤害的想法，请立即寻求专业帮助：\n'
                          '• 拨打心理援助热线：400-161-9995\n'
                          '• 或前往就近医院精神科就医\n'
                          '• 你不是一个人，寻求帮助是一种勇气',
                          style: ShunshiTextStyles.body.copyWith(
                            fontSize: 13,
                            color: const Color(0xFFBF360C),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 底部
            Center(
              child: Text(
                '顺时 · 祝你顺应自然，身心和谐',
                style: ShunshiTextStyles.caption.copyWith(
                  color: ShunshiColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              title,
              style: ShunshiTextStyles.heading.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: ShunshiTextStyles.caption.copyWith(
              color: ShunshiColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _BoundaryCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ShunshiTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ShunshiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: ShunshiTextStyles.body.copyWith(
                    fontSize: 13,
                    color: ShunshiColors.textSecondary,
                    height: 1.5,
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
