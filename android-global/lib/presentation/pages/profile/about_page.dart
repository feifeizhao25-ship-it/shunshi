import 'package:flutter/material.dart';
import '../../../core/theme/shunshi_colors.dart';
import '../../../design_system/theme.dart';
import '../../../core/router/safe_pop.dart';
import '../../../core/network/api_singleton.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: isDark ? ShunshiDarkColors.background : ShunShiColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          'AboutSEASONS',
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
              'SEASONS ShunShi',
              style: TextStyle(
                fontFamily: ShunShiTypography.serifFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live in Harmony with Time, Nourish the Heart',
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
                    'SEASONS is a smart health app rooted in TCM ShiChen Wellness philosophy. Combining the 24 Solar Terms, 12 ShiChen periods, and your personal Body Type, it delivers personalized wellness suggestions for you.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Version', 'v1.0.0'),
                  _infoRow('Philosophy', 'Humans integrated with nature, living in harmony with the natural world'),
                  _infoRow('Features', 'AI + TCMWellness'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2024-2026 SEASONS ShunShi',
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
