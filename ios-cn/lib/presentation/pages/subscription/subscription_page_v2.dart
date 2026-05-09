/// 会员订阅中心 — 参考UI _11
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';

class SubscriptionPageV2 extends StatelessWidget {
  const SubscriptionPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('会员中心', style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.help_outline), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SVIP Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF144227), Color(0xFF2D7A4A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SVIP 尊享', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.surface)),
                  const SizedBox(height: 4),
                  Text('开启您的智能养生之旅', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Text('已为您定制 128 条健康建议', style: TextStyle(fontSize: 12, color: Color(0xFFE4C285))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 年度会员 - Recommended
            GestureDetector(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ShunShiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ShunShiColors.primary, width: 2),
                  boxShadow: [BoxShadow(color: ShunShiColors.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: ShunShiColors.primary, borderRadius: BorderRadius.circular(6)),
                        child: Text('RECOMMENDED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text('年度会员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
                    Text('首年特惠 · 每日仅需 ¥0.54', style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('¥199', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ShunShiColors.primary)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('¥299', style: TextStyle(fontSize: 14, color: ShunShiColors.textTertiary, decoration: TextDecoration.lineThrough)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 月度卡 + 家庭卡
            Row(children: [
              Expanded(child: _buildPlanCard('月度卡', '¥25', '随用随开 · 自由续费', false)),
              const SizedBox(width: 12),
              Expanded(child: _buildPlanCard('家庭卡', '¥299', '3人共享 · 健康互联', false)),
            ]),
            const SizedBox(height: 24),

            // 会员权益
            Text('会员尊享权益', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 12),
            _buildBenefit(Icons.auto_awesome, 'AI私人订制方案', '基于二十四节气与体质实时调整的个性化调理建议。'),
            _buildBenefit(Icons.restaurant_menu, '全站食谱解锁', '5000+ 药膳食谱，包含详细营养成分与时令搭配。'),
            _buildBenefit(Icons.headphones, '高保真音频随心听', '沉浸式冥想导引、中医名家访谈，高品质声学体验。'),
            _buildBenefit(Icons.family_restroom, '家庭成员健康互联', '一人订阅，全家守护。实时关注家人的健康动态。'),
            _buildBenefit(Icons.military_tech, '专属会员勋章', '独有的身份标识，记录您的养生打卡每一刻荣誉。'),
            const SizedBox(height: 20),

            // FAQ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ShunShiColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.help_outline, color: ShunShiColors.textTertiary, size: 18),
                const SizedBox(width: 8),
                Text('如何取消自动续费？', style: TextStyle(fontSize: 14, color: ShunShiColors.textSecondary)),
                const Spacer(),
                Icon(Icons.chevron_right, color: ShunShiColors.textTertiary, size: 18),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('立即开通', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? ShunShiColors.primary : ShunShiColors.borderGhost),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
        const SizedBox(height: 6),
        Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.primary)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary)),
      ]),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ShunShiColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: ShunShiColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: ShunShiColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
            const SizedBox(height: 2),
            Text(desc, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.5)),
          ])),
        ]),
      ),
    );
  }
}
