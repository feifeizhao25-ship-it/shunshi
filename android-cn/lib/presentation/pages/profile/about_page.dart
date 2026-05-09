import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          '关于顺时',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 44, color: ShunShiColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '顺时 ShunShi',
              style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '顺应天时，养心养身',
              style: TextStyle(
                fontSize: 14,
                color: ShunShiColors.textTertiary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '顺时是一款基于中医时辰养生理念的智能健康App。结合二十四节气、十二时辰与个人体质，为你提供个性化的养生建议。',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('版本', 'v1.0.0'),
                  _infoRow('理念', '天人合一，顺应自然'),
                  _infoRow('特色', 'AI + 中医养生'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2024-2026 顺时 ShunShi',
              style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: ShunShiColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
