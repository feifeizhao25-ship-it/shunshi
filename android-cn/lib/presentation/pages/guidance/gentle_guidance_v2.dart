/// Gentle Guidance — 参考 gentle_guidance
/// 每thWarm柔提醒卡片流
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';

class GentleGuidanceV2 extends StatelessWidget {
  const GentleGuidanceV2({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                Text('顺时', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF533afd))),
                const Spacer(),
                Icon(Icons.settings, color: ShunShiColors.textTertiary),
              ]),
            ),
          )),

          // Title
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('每日轻语', style: TextStyle(fontSize: 12, color: Color(0xFF533afd), fontWeight: FontWeight.w500, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('温柔指引', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 28, fontWeight: FontWeight.bold, color: ShunShiColors.textPrimary)),
              const SizedBox(height: 4),
              Text('根据你的体质和节气，定制专属提醒节奏。',
                style: TextStyle(fontSize: 13, color: ShunShiColors.textTertiary, height: 1.5)),
            ]),
          )),

          // Morning Ritual
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _buildGuidanceCard(
              icon: Icons.light_mode,
              iconColor: Color(0xFFFF9800),
              title: 'Morning Ritual',
              time: 'Just now',
              content: 'A 5-minute sun-gazing practice to align your circadian rhythm with the early spring light.',
              action: 'Begin Practice',
            ),
          )),

          // Seasonal Tip
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: _buildGuidanceCard(
              icon: Icons.restaurant_menu,
              iconColor: Color(0xFF4CAF50),
              title: '节气小贴士',
              time: '2h ago',
              content: 'Time for bitter greens. Dandelion and arugula will support your liver\'s natural detoxification this afternoon.',
              action: null,
            ),
          )),

          // Body Type Insight
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF533afd), Color(0xFF7c5cfc)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.analytics, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text('风火体质平衡', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
                const SizedBox(height: 4),
                Text('体质洞察', style: TextStyle(fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 10),
                Text('今天下午3点左右能量可能下降。建议用一杯温热的香料茶代替咖啡因，保持身心稳定。',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                const SizedBox(height: 10),
                Text('为你当前的周期定制', style: TextStyle(fontSize: 11, color: Color(0xFFE4C285))),
                const SizedBox(height: 8),
                Text('深入了解', style: TextStyle(fontSize: 13, color: Color(0xFFE4C285), fontWeight: FontWeight.w500)),
              ]),
            ),
          )),

          // Flow State
          SliverToBoxAlternate(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: _buildGuidanceCard(
              icon: Icons.self_improvement,
              iconColor: Color(0xFF533afd),
              title: 'Flow State',
              time: 'Morning',
              content: 'A gentle hip-opening sequence is recommended to release the stagnant energy of the week.',
              action: 'Cultivating Stillness',
            ),
          )),

          const SliverToBoxAlternate(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard({
    required IconData icon, required Color iconColor,
    required String title, required String time,
    required String content, required String? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          ])),
          Text(time, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
        ]),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
        if (action != null) ...[
          const SizedBox(height: 10),
          Text(action, style: TextStyle(fontSize: 13, color: Color(0xFF533afd), fontWeight: FontWeight.w500)),
        ],
      ]),
    );
  }
}

class SliverToBoxAlternate extends SliverToBoxAdapter {
  const SliverToBoxAlternate({super.key, required Widget child}) : super(child: child);
}
