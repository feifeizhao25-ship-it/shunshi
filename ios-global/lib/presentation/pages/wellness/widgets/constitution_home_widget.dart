import 'package:flutter/material.dart';
import '../../../../core/theme/shunshi_colors.dart';
import '../../../../core/theme/shunshi_text_styles.dart';
import 'constitution_data.dart';

/// 体质测试首页 Widget
class ConstitutionHomeWidget extends StatelessWidget {
  final List<ConstitutionType> types;
  final VoidCallback onStartQuiz;
  final Function(ConstitutionType) onShowDetail;

  const ConstitutionHomeWidget({
    super.key,
    required this.types,
    required this.onStartQuiz,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('了解你的体质', style: ShunshiTextStyles.greeting),
          const SizedBox(height: 8),
          Text('中医体质辨识，找到最适合你的养生之道', style: ShunshiTextStyles.bodySecondary),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onStartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunshiColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('开始测试', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
          Text('九种体质', style: ShunshiTextStyles.heading),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return GestureDetector(
                onTap: () => onShowDetail(type),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ShunshiColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ShunshiColors.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ShunshiColors.primaryLight.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(type.emoji, style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunshiColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.description,
                        style: ShunshiTextStyles.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
