/// 养生报告。没有个人记录时不展示编造的分数或英文评估。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/app_colors.dart';

class WellnessReportPage extends StatelessWidget {
  const WellnessReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : AppColors.background(context);
    final card = isDark ? ShunShiColors.darkSurface : AppColors.surfaceContainerLowest(context);
    final title = isDark ? ShunShiColors.darkTextPrimary : AppColors.textPrimary(context);
    final body = isDark ? ShunShiColors.darkTextSecondary : AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: title,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('养生报告', style: TextStyle(
          fontFamily: ShunShiTypography.serifFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: title,
        )),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/wellness/empty_basket.webp', width: 220, height: 165, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 165)),
                )),
                const SizedBox(height: 16),
                Text('还没有个人评估', style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: title,
                  fontFamily: ShunShiTypography.serifFamily,
                )),
                const SizedBox(height: 10),
                Text(
                  '个人评估需要你自己的打卡和作息记录。当前没有这些记录，所以这里不显示精力、睡眠或其他分数，也不把示例数字当成你的结果。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: body,
                    fontFamily: ShunShiTypography.sansFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('回到今日'),
            ),
          ),
        ],
      ),
    );
  }
}
