import 'package:flutter/material.dart';
import '../../../../core/theme/shunshi_colors.dart';
import '../../../../core/theme/shunshi_text_styles.dart';
import 'constitution_data.dart';
import 'constitution_widgets.dart';

/// 体质测试问卷 Widget
class ConstitutionQuizWidget extends StatelessWidget {
  final List<Question> questions;
  final int currentIndex;
  final Map<int, int> answers;
  final Function(int) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSubmit;

  const ConstitutionQuizWidget({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.onAnswer,
    required this.onNext,
    required this.onPrev,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();
    final question = questions[currentIndex];
    final progress = (currentIndex + 1) / questions.length;
    final hasAnswer = answers.containsKey(question.id);
    final isLast = currentIndex == questions.length - 1;
    final allAnswered = answers.length == questions.length;

    return Column(
      children: [
        // 进度条
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('第 ${currentIndex + 1} 题 / ${questions.length}',
                      style: ShunshiTextStyles.caption),
                  Text('${(progress * 100).toInt()}%',
                      style: ShunshiTextStyles.caption
                          .copyWith(color: ShunshiColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: ShunshiColors.divider,
                  valueColor: const AlwaysStoppedAnimation(ShunshiColors.primary),
                ),
              ),
            ],
          ),
        ),
        // 题目
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(question.id),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(question.text, style: ShunshiTextStyles.heading),
                    const SizedBox(height: 24),
                    ...question.options.asMap().entries.map((entry) {
                      return QuizOptionCard(
                        index: entry.key,
                        option: entry.value,
                        questionId: question.id,
                        isSelected: answers[question.id] == entry.key,
                        onTap: (i) => onAnswer(i),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 底部按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                if (currentIndex > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPrev,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ShunshiColors.textSecondary,
                        side: const BorderSide(color: ShunshiColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('上一题', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasAnswer
                        ? (isLast && allAnswered ? onSubmit : onNext)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShunshiColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ShunshiColors.divider,
                      disabledForegroundColor: ShunshiColors.textHint,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isLast && allAnswered ? '提交答卷' : '下一题',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
