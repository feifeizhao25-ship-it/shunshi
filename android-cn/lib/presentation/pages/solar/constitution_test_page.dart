import '../../../core/router/safe_pop.dart';
import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../widgets/paywall_banner.dart';

/// 体质测试结果页
class ConstitutionTestPage extends StatelessWidget {
  final String? constitutionType;
  const ConstitutionTestPage({super.key, this.constitutionType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ShunShiColors.darkBackground : ShunShiColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('体质测试结果', style: TextStyle(fontFamily: ShunShiTypography.serifFamily)),
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => safePop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── 体质类型卡片 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ShunShiColors.primary, Color(0xFF2D5A3D)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.spa, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  Text(constitutionType ?? '气虚质', style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: ShunShiTypography.serifFamily,
                  )),
                  const SizedBox(height: 8),
                  const Text('您的体质类型', style: TextStyle(fontSize: 13, color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 体质特征 ──
            _sectionTitle('体质特征'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
              child: const Text(
                '气虚质人群常表现为疲乏无力、气短懒言、易出汗、面色偏白。'
                '抵抗力较弱，容易感冒，恢复较慢。舌淡苔白，脉象虚弱。',
                style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary, height: 1.7),
              ),
            ),
            const SizedBox(height: 24),

            // ── 升级提示 Banner ──
            const PaywallBanner(
              message: '解锁详细体质分析',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 20),

            // ── 调养建议 ──
            _sectionTitle('调养建议'),
            const SizedBox(height: 12),
            _adviceCard('饮食调养', '宜食补气食物：山药、黄芪、红枣、小米粥。忌生冷寒凉。', Icons.restaurant, ShunShiColors.primary),
            const SizedBox(height: 12),
            _adviceCard('运动调养', '适宜柔和运动：散步、太极拳、八段锦。避免剧烈运动耗气。', Icons.self_improvement, ShunShiColors.secondary),
            const SizedBox(height: 12),
            _adviceCard('起居调养', '保证充足睡眠，避免过度劳累。午间小憩有益补气。', Icons.bedtime, ShunShiColors.blue),
            const SizedBox(height: 32),

            // ── 按钮 ──
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制分享链接'), duration: Duration(seconds: 1))); },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('分享结果'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShunShiColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ShunShiColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('重新测试'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: ShunShiTypography.serifFamily, color: ShunShiColors.textPrimary)),
  );

  Widget _adviceCard(String title, String desc, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShunShiColors.borderGhost)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color, fontFamily: ShunShiTypography.serifFamily)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, color: ShunShiColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
