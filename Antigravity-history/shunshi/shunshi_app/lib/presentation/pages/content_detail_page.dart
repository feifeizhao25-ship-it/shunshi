import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/safety/system_notice_messages.dart';
import '../../data/models/content_item.dart';
import '../../design_system/design_system.dart';
import '../providers/content_provider.dart';
import '../providers/infrastructure_providers.dart';

class ContentDetailPage extends ConsumerWidget {
  final String contentId;

  const ContentDetailPage({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_contentDetailProvider(contentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '详情',
        showBack: true,
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText.bodyMedium(SystemNoticeMessages.contentLoadFailed),
                const SizedBox(height: AppSpacing.lg),
                AppButton.outline(
                  label: '返回',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return const Center(
              child: AppText.bodyMedium('内容不存在或已下架。'),
            );
          }
          return _buildDetail(context, item);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ContentItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover/media area - graceful degradation
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.lgAll,
            ),
            child: item.cover != null
                ? ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    child: Image.network(
                      item.cover!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _mediaFallback(item),
                    ),
                  )
                : _mediaFallback(item),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Tags
          if (item.tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              children: item.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: AppText.labelSmall(t),
                      ))
                  .toList(),
            ),

          const SizedBox(height: AppSpacing.lg),

          AppText.headlineLarge(item.title),
          if (item.subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText.bodyMedium(item.subtitle!),
          ],
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              AppText.bodySmall('约${item.readTimeMinutes}分钟'),
              if (item.isPremium) ...[
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.favorite_rounded,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.xs),
                const AppText.bodySmall('照护会员内容',
                    color: AppColors.secondary),
              ],
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(),
          ),

          if (item.description != null)
            AppText.bodyLarge(item.description!),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _mediaFallback(ContentItem item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.type == ContentType.video
              ? Icons.play_circle_outline_rounded
              : Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText.bodySmall(item.typeLabel),
      ],
    );
  }
}

/// Provider for a single content detail
final _contentDetailProvider =
    FutureProvider.family<ContentItem?, String>((ref, id) async {
  return ref.watch(contentRepositoryProvider).getContentDetail(id);
});
