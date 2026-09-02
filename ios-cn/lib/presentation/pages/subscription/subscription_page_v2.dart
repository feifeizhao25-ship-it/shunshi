/// 会员订阅中心 — 参考UI _11
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/theme.dart';
import '../../../data/services/store_service.dart';

class SubscriptionPageV2 extends StatefulWidget {
  const SubscriptionPageV2({super.key});

  @override
  State<SubscriptionPageV2> createState() => _SubscriptionPageV2State();
}

class _SubscriptionPageV2State extends State<SubscriptionPageV2> {
  bool _purchasing = false;

  Future<void> _purchaseAnnual() async {
    setState(() => _purchasing = true);
    try {
      final store = StoreService();
      if (!store.isAvailable) throw Exception('当前设备暂不支持 App Store 内购');
      final launched = await store.purchase('yiyang_yearly');
      if (!launched) throw Exception('未能发起 App Store 购买');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('购买请求已提交，服务端验证收据后会员权益将自动生效')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('购买失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '会员中心',
          style: TextStyle(
            fontFamily: ShunShiTypography.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF144227), Color(0xFF2D7A4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SVIP 尊享',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ShunShiColors.surface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '开启您的智能养生之旅',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '权益以订单确认页和当前已上线功能为准',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE4C285)),
                  ),
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
                  boxShadow: [
                    BoxShadow(
                      color: ShunShiColors.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ShunShiColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '年度会员',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ShunShiColors.textPrimary,
                      ),
                    ),
                    Text(
                      '颐养版年付 · 每日约 ¥1.09',
                      style: TextStyle(
                        fontSize: 12,
                        color: ShunShiColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '¥399/年',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: ShunShiColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 月度卡 + 家庭卡
            Row(
              children: [
                Expanded(
                  child: _buildPlanCard('颐养月付', '¥59', '按月购买 · 支付前确认', false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlanCard('家和年付', '¥699', '最多4个家庭席位', false),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 会员权益
            Text(
              '会员尊享权益',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildBenefit(
              Icons.auto_awesome,
              'AI私人订制方案',
              '基于二十四节气与体质实时调整的个性化调理建议。',
            ),
            _buildBenefit(
              Icons.restaurant_menu,
              '完整内容库',
              '解锁当前已上架并持续更新的食养、作息与节气内容。',
            ),
            _buildBenefit(Icons.headphones, '会员音频', '按实际上架范围收听冥想导引与养生音频。'),
            _buildBenefit(
              Icons.family_restroom,
              '家庭成员关怀',
              '家和版最多提供4个家庭席位，并由成员自行控制共享范围。',
            ),
            _buildBenefit(
              Icons.insights,
              '长期趋势与周度报告',
              '在数据充足时生成趋势视图和周度深度报告，并明确数据范围。',
            ),
            const SizedBox(height: 8),
            Text(
              '当前支付宝年付为单次购买，不自动续费；支付前会再次展示金额与订单信息。',
              style: TextStyle(
                fontSize: 12,
                color: ShunShiColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // FAQ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShunShiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: ShunShiColors.textTertiary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '如何取消自动续费？',
                    style: TextStyle(
                      fontSize: 14,
                      color: ShunShiColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: ShunShiColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _purchasing ? null : _purchaseAnnual,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _purchasing ? '等待支付确认…' : '立即开通',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String price,
    String subtitle,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? ShunShiColors.primary : ShunShiColors.borderGhost,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ShunShiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ShunShiColors.primary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: ShunShiColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ShunShiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ShunShiColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ShunShiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: ShunShiColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
