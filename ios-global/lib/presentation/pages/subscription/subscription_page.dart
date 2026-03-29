import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/components/components.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? SeasonsDarkColors.background : SeasonsColors.background;
    final textPrimary = isDark ? SeasonsDarkColors.textPrimary : SeasonsColors.textPrimary;
    final textSecondary = isDark ? SeasonsDarkColors.textSecondary : SeasonsColors.textSecondary;
    final textHint = isDark ? SeasonsDarkColors.textHint : SeasonsColors.textHint;
    final border = isDark ? SeasonsDarkColors.border : SeasonsColors.border;
    final surfaceDim = isDark ? SeasonsDarkColors.surfaceDim : SeasonsColors.surfaceDim;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SeasonsSpacing.pagePadding,
            vertical: SeasonsSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 关闭按钮 ──
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 22),
                    color: textSecondary,
                  ),
                  const Spacer(),
                ],
              ),

              // ── 标题：insight样式，更大留白 ──
              const SizedBox(height: SeasonsSpacing.sm),
              Center(
                child: Text(
                  'Unlock Full Experience',
                  style: SeasonsTextStyles.insight.copyWith(
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: SeasonsSpacing.xs),
              Center(
                child: Text(
                  'Choose what feels right for you',
                  style: SeasonsTextStyles.bodySecondary.copyWith(
                    color: textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: SeasonsSpacing.xl),

              // ── 计划卡片 ──
              ...(subscriptionState.plans.isEmpty
                  ? _fallbackPlanCards(subscriptionState, ref, isDark, textPrimary, textSecondary, textHint, border, surfaceDim)
                  : subscriptionState.plans
                      .map((plan) => _buildPlanCard(
                          plan, subscriptionState, ref, isDark, textPrimary, textSecondary, textHint, border, surfaceDim))),

              // ── 恢复购买 ──
              const SizedBox(height: SeasonsSpacing.lg),
              Center(
                child: Column(
                  children: [
                    if (subscriptionState.isRestoring)
                      const Padding(
                        padding: EdgeInsets.only(bottom: SeasonsSpacing.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    TextButton(
                      onPressed: subscriptionState.isRestoring
                          ? null
                          : () =>
                              ref.read(subscriptionProvider.notifier).restore(),
                      child: Text(
                        'Restore Purchases',
                        style: SeasonsTextStyles.caption.copyWith(
                          color: textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 条款 ──
              const SizedBox(height: SeasonsSpacing.sm),
              Center(
                child: Text(
                  'Auto-renews unless cancelled. 7-day free trial for new subscribers.',
                  textAlign: TextAlign.center,
                  style: SeasonsTextStyles.overline.copyWith(
                    color: textHint,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: SeasonsSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback plan cards — Free/$0, Serenity/$9.99, Harmony/$19.99, Family/$29.99
  List<Widget> _fallbackPlanCards(
      SubscriptionState state, WidgetRef ref, bool isDark,
      Color textPrimary, Color textSecondary, Color textHint,
      Color border, Color surfaceDim) {
    final tiers = [
      (SubscriptionTier.free, 'Free', '\$0', null, false, <String>[]),
      (SubscriptionTier.serenity, 'Serenity', '\$9.99', 'month', true, [
        'Unlimited AI companion',
        'All content library',
        'Seasonal insights',
        'Unlimited reflections',
        'Sleep audio & stories',
      ]),
      (SubscriptionTier.harmony, 'Harmony', '\$19.99', 'month', false, [
        'Everything in Serenity',
        'Family features',
        'Priority support',
        'Weekly AI insights',
      ]),
      (SubscriptionTier.family, 'Family', '\$29.99', 'month', false, [
        'Everything in Harmony',
        'Up to 5 family members',
        'Shared insights',
        'Dedicated support',
      ]),
    ];

    return tiers.map((t) {
      final (tier, name, price, period, isPopular, features) = t;
      return Padding(
        padding: const EdgeInsets.only(bottom: SeasonsSpacing.md),
        child: _PlanCard(
          tier: tier,
          name: name,
          price: price,
          period: period,
          isCurrentPlan: state.currentTier == tier,
          isPopular: isPopular,
          features: features,
          isLoading: state.isPurchasing,
          onSelect: () =>
              ref.read(subscriptionProvider.notifier).purchase(tier),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textHint: textHint,
          border: border,
          surfaceDim: surfaceDim,
        ),
      );
    }).toList();
  }

  Widget _buildPlanCard(
      SubscriptionPlan plan, SubscriptionState state, WidgetRef ref,
      bool isDark, Color textPrimary, Color textSecondary,
      Color textHint, Color border, Color surfaceDim) {
    final tier = _planIdToTier(plan.id);
    if (tier == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: SeasonsSpacing.md),
      child: _PlanCard(
        tier: tier,
        name: plan.name,
        price: plan.priceDisplay,
        period: plan.period,
        isCurrentPlan: state.currentTier == tier,
        isPopular: tier == SubscriptionTier.serenity,
        features: plan.features,
        isLoading: state.isPurchasing,
        onSelect: () =>
            ref.read(subscriptionProvider.notifier).purchase(tier),
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textHint: textHint,
        border: border,
        surfaceDim: surfaceDim,
      ),
    );
  }

  SubscriptionTier? _planIdToTier(String planId) {
    switch (planId) {
      case 'free':
        return SubscriptionTier.free;
      case 'serenity':
        return SubscriptionTier.serenity;
      case 'harmony':
        return SubscriptionTier.harmony;
      case 'family':
        return SubscriptionTier.family;
      default:
        return null;
    }
  }
}

// ==================== Plan Card ====================

class _PlanCard extends StatelessWidget {
  final SubscriptionTier tier;
  final String name;
  final String price;
  final String? period;
  final bool isCurrentPlan;
  final bool isPopular;
  final List<String> features;
  final bool isLoading;
  final VoidCallback onSelect;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color surfaceDim;

  const _PlanCard({
    required this.tier,
    required this.name,
    required this.price,
    required this.period,
    required this.isCurrentPlan,
    this.isPopular = false,
    required this.features,
    this.isLoading = false,
    required this.onSelect,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.surfaceDim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: SeasonsColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPopular
            ? Border.all(color: SeasonsColors.warm, width: 2)
            : Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SeasonsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: SeasonsTextStyles.heading.copyWith(
                      color: textPrimary,
                    ),
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.sm,
                      vertical: SeasonsSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: SeasonsColors.sage.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(SeasonsSpacing.radiusFull),
                    ),
                    child: Text(
                      'Current',
                      style: SeasonsTextStyles.overline.copyWith(
                        color: SeasonsColors.sage,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeasonsSpacing.sm,
                      vertical: SeasonsSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: SeasonsColors.warm.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(SeasonsSpacing.radiusFull),
                    ),
                    child: Text(
                      'Popular',
                      style: SeasonsTextStyles.overline.copyWith(
                        color: SeasonsColors.warm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // 价格
            const SizedBox(height: SeasonsSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: SeasonsTextStyles.insight.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (period != null) ...[
                  const SizedBox(width: SeasonsSpacing.xs),
                  Text(
                    '/$period',
                    style: SeasonsTextStyles.bodySecondary.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            // 功能列表 (仅非Free显示)
            if (features.isNotEmpty) ...[
              const SizedBox(height: SeasonsSpacing.md),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: SeasonsSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: SeasonsColors.sage,
                          size: 18,
                        ),
                        const SizedBox(width: SeasonsSpacing.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: SeasonsTextStyles.bodySecondary.copyWith(
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // 按钮
            if (tier != SubscriptionTier.free) ...[
              const SizedBox(height: SeasonsSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: GentleButton(
                  text: isCurrentPlan ? 'Current Plan' : 'Subscribe Now',
                  isPrimary: true,
                  isLoading: isLoading,
                  horizontalPadding: SeasonsSpacing.xl,
                  onPressed:
                      (isCurrentPlan || isLoading) ? null : onSelect,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
