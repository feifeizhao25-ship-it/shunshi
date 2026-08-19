import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/safety/system_notice_messages.dart';
import '../../design_system/design_system.dart';
import '../providers/daily_plan_provider.dart';
import '../providers/subscription_provider.dart';

class DailyPlanPage extends ConsumerWidget {
  const DailyPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dailyPlanProvider);
    final isPremium = ref.watch(subscriptionProvider).value?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '今日计划',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(dailyPlanProvider.notifier).refresh(),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => _buildLoading(),
        error: (_, __) => _buildError(ref),
        data: (state) => _buildPlan(context, ref, state, isPremium),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.lg),
          AppText.bodyMedium(SystemNoticeMessages.dailyPlanLoading),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppNoticeCard(
              message: SystemNoticeMessages.dailyPlanOffline,
              type: AppNoticeType.info,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.outline(
              label: '重新加载',
              onPressed: () => ref.read(dailyPlanProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlan(
    BuildContext context,
    WidgetRef ref,
    DailyPlanState state,
    bool isPremium,
  ) {
    final plan = state.plan;
    if (plan == null) return _buildError(ref);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(dailyPlanProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                AppText.labelMedium(_todayLabel()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Degraded notice
            if (state.isDegraded) ...[
              const AppNoticeCard(
                message: SystemNoticeMessages.dailyPlanOffline,
                type: AppNoticeType.info,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Main insight (1 sentence)
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: AppSpacing.xs),
                      AppText.labelMedium('今日洞察', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText.bodyLarge(plan.text),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Action cards (3 items max on one screen)
            if (plan.cards != null && plan.cards!.isNotEmpty) ...[
              const AppText.titleLarge('今日行动'),
              const SizedBox(height: AppSpacing.md),
              ...plan.cards!.take(3).map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard.outlined(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppText.titleMedium(
                              card.title ?? card.type,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Expand more - Premium only, but with length limit
            if (isPremium && plan.cards != null && plan.cards!.length > 3) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: state.isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText.titleLarge('更多建议'),
                          const SizedBox(height: AppSpacing.md),
                          ...plan.cards!.skip(3).take(3).map((card) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppCard.filled(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: AppText.bodyMedium(
                                    card.title ?? card.type,
                                  ),
                                ),
                              )),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              AppButton.text(
                label: state.isExpanded ? '收起' : '展开更多',
                icon: state.isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                onPressed: () =>
                    ref.read(dailyPlanProvider.notifier).toggleExpanded(),
              ),
            ] else if (!isPremium && plan.cards != null && plan.cards!.length > 3)
              AppCard.filled(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_outline_rounded,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: AppText.bodyMedium('开启连续照护，获取完整的每日计划支持。'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/subscribe'),
                      child: const AppText.labelMedium(
                        '了解',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final wd = weekdays[now.weekday - 1];
    return '${now.month}月${now.day}日 · $wd';
  }
}
