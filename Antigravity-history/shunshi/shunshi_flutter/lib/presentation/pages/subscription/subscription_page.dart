import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// 订阅页 — 强调"连续照护"而非"解锁功能"
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('连续照护')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.premiumGoldLight.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('连续照护',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('让养生不再间断，持续的陪伴与关怀',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BenefitRow(
                      icon: Icons.psychology_outlined,
                      title: '高级AI顾问',
                      desc: '深度模型提供更个性化、更深层的养生洞察'),
                  _BenefitRow(
                      icon: Icons.calendar_today_outlined,
                      title: '每日个性化计划',
                      desc: '结合体质、节气、情绪，深度定制今日方案'),
                  _BenefitRow(
                      icon: Icons.memory_outlined,
                      title: '阶段记忆',
                      desc: '持续了解你的状态变化，提供连续性关怀'),
                  _BenefitRow(
                      icon: Icons.notifications_active_outlined,
                      title: '主动跟进关怀',
                      desc: '在你需要时主动关心，稳定时安静退让'),
                  _BenefitRow(
                      icon: Icons.library_books_outlined,
                      title: '内容库完整访问',
                      desc: '穴位、食谱、运动全库访问'),
                ],
              ),
            ),
            if (!isPremium) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _PriceCard(
                        title: '月度',
                        price: '¥18',
                        period: '/月',
                        isRecommended: false,
                        onTap: () => _handlePurchase(
                            ref, AppConstants.monthlyPremiumId)),
                    const SizedBox(width: 12),
                    _PriceCard(
                        title: '年度',
                        price: '¥128',
                        period: '/年',
                        isRecommended: true,
                        badge: '省42%',
                        onTap: () => _handlePurchase(
                            ref, AppConstants.annualPremiumId)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () {},
                  child: const Text('恢复购买')),
            ] else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.premiumGoldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.premiumGold),
                      const SizedBox(width: 12),
                      Text('您已开启连续照护',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.premiumGold,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '订阅将自动续费，可随时在系统设置中取消。\n付款将通过您的 Apple ID / Google 账户处理。',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(WidgetRef ref, String productId) {
    // TODO: Trigger in_app_purchase
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _BenefitRow(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.premiumGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final bool isRecommended;
  final String? badge;
  final VoidCallback onTap;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.period,
    this.isRecommended = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRecommended
                ? AppColors.premiumGoldLight.withValues(alpha: 0.3)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended
                  ? AppColors.premiumGold
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isRecommended ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.premiumGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              if (badge != null) const SizedBox(height: 8),
              Text(title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isRecommended
                            ? AppColors.premiumGold
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(text: period, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
