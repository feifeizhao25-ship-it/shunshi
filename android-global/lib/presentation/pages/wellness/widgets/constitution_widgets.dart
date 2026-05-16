import 'package:flutter/material.dart';
import '../../../../core/theme/shunshi_colors.dart';
import '../../../../core/theme/shunshi_text_styles.dart';
import 'constitution_data.dart';
import '../../../../core/network/api_singleton.dart';

/// 答 questions选项卡片
class QuizOptionCard extends StatelessWidget {
  final int index;
  final QuestionOption option;
  final int questionId;
  final bool isSelected;
  final ValueChanged<int> onTap;
  const QuizOptionCard({super.key, required this.index, required this.option, required this.questionId, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? ShunshiColors.primaryLight.withValues(alpha: 0.2) : ShunshiColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? ShunshiColors.primary : ShunshiColors.divider, width: isSelected ? 2 : 1),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(color: isSelected ? ShunshiColors.primary : null, shape: BoxShape.circle, border: isSelected ? null : Border.all(color: ShunshiColors.textHint)),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(option.text, style: TextStyle(fontSize: 15, color: isSelected ? ShunshiColors.primaryDark : ShunshiColors.textPrimary, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400))),
          ]),
        ),
      ),
    );
  }
}

/// 结果页分数条
class ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final bool isPrimary;
  const ScoreBar({super.key, required this.label, required this.score, required this.maxScore, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final pct = maxScore > 0 ? score / maxScore : 0.0;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: isPrimary ? ShunshiColors.primary : ShunshiColors.textSecondary, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
        Text('$score pts', style: TextStyle(fontSize: 13, color: isPrimary ? ShunshiColors.primary : ShunshiColors.textHint)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: ShunshiColors.divider, valueColor: AlwaysStoppedAnimation(isPrimary ? ShunshiColors.primary : ShunshiColors.accent))),
    ]));
  }
}

/// 结果页 Hero 卡片
class ResultHeroCard extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  const ResultHeroCard({super.key, required this.icon, required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [ShunshiColors.primary.withValues(alpha: 0.12), ShunshiColors.accent.withValues(alpha: 0.08)]), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ShunshiColors.textPrimary)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 15, color: ShunshiColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}

/// 通用 Section 容器
class DetailSection extends StatelessWidget {
  final String title;
  final String icon;
  final List<Widget> children;
  const DetailSection({super.key, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: ShunshiColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunshiColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary))]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

/// Details页列表项
class DetailListItem extends StatelessWidget {
  final String text;
  const DetailListItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: ShunshiColors.primary)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: ShunshiColors.textSecondary, height: 1.5))),
    ]));
  }
}

/// Body TypeDetails页
class ConstitutionDetailView extends StatelessWidget {
  final ConstitutionDetail detail;
  const ConstitutionDetailView({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: ShunshiColors.primaryLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 32)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.name, style: ShunshiTextStyles.greeting),
          const SizedBox(height: 4),
          Text(d.description, style: ShunshiTextStyles.bodySecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
      const SizedBox(height: 24),
      if (d.characteristics.isNotEmpty) ...[_detailSection('Body Type Characteristics', d.characteristics), const SizedBox(height: 20)],
      ...d.advice.expand((adv) => [_detailSection('${adv.icon} ${adv.category}', adv.items), const SizedBox(height: 20)]),
      if (d.avoidList.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ShunshiColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: ShunshiColors.warning.withValues(alpha: 0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: ShunshiColors.earth), const SizedBox(width: 10),
          Expanded(child: Text('Precautions: ${d.avoidList}', style: ShunshiTextStyles.bodySecondary.copyWith(color: ShunshiColors.textPrimary))),
        ])),
      const SizedBox(height: 32),
    ]));
  }

  Widget _detailSection(String title, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary)),
      const SizedBox(height: 10),
      ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 8), decoration: const BoxDecoration(color: ShunshiColors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(item, style: ShunshiTextStyles.bodySecondary)),
      ]))),
    ]);
  }
}
