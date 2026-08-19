import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/safety/system_notice_messages.dart';
import '../../data/models/content_item.dart';
import '../../design_system/design_system.dart';
import '../providers/content_provider.dart';

class ContentLibraryPage extends ConsumerWidget {
  const ContentLibraryPage({super.key});

  static const _types = [
    (null, '全部'),
    (ContentType.article, '文章'),
    (ContentType.video, '视频'),
    (ContentType.acupoint, '穴位'),
    (ContentType.exercise, '运动'),
    (ContentType.recipe, '食谱'),
    (ContentType.meditation, '冥想'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: '内容库'),
      body: Column(
        children: [
          // Type filter tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _types.length,
              itemBuilder: (ctx, i) {
                final (type, label) = _types[i];
                final selected =
                    contentAsync.value?.selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.sm, bottom: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(contentProvider.notifier).filterByType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: AppRadius.fullAll,
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: AppText.labelMedium(
                        label,
                        color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content list
          Expanded(
            child: contentAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppText.bodyMedium(
                          SystemNoticeMessages.contentLoadFailed),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.outline(
                        label: '重试',
                        onPressed: () => ref.invalidate(contentProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return const Center(
                    child: AppText.bodyMedium('暂时没有相关内容，稍后再来看看。'),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.extentAfter < 100) {
                      ref.read(contentProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (ctx, i) => _ContentCard(
                      item: state.items[i],
                      onTap: () =>
                          context.push('/content/${state.items[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const _ContentCard({required this.item, required this.onTap});

  IconData get _typeIcon {
    switch (item.type) {
      case ContentType.article:
        return Icons.article_outlined;
      case ContentType.video:
        return Icons.play_circle_outline_rounded;
      case ContentType.acupoint:
        return Icons.radio_button_checked_outlined;
      case ContentType.exercise:
        return Icons.sports_gymnastics_outlined;
      case ContentType.recipe:
        return Icons.restaurant_menu_outlined;
      case ContentType.meditation:
        return Icons.self_improvement_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder or type icon
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_typeIcon, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.xs),
                  AppText.labelSmall(item.typeLabel),
                  if (item.isPremium)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: const AppText.labelSmall(
                          '照护会员',
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText.titleMedium(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText.bodySmall('约${item.readTimeMinutes}分钟'),
        ],
      ),
    );
  }
}
