import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/design_system.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../providers/subscription_provider.dart';

class SubscribePage extends ConsumerStatefulWidget {
  const SubscribePage({super.key});

  @override
  ConsumerState<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends ConsumerState<SubscribePage> {
  String? _selectedProductId;
  List<SubscriptionProduct> _products = [];
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products =
        await ref.read(subscriptionProvider.notifier).getProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _loadingProducts = false;
        if (products.isNotEmpty) {
          _selectedProductId = products.first.id;
        }
      });
    }
  }

  Future<void> _purchase() async {
    if (_selectedProductId == null) return;
    await ref.read(subscriptionProvider.notifier).purchase(_selectedProductId!);
    if (mounted) {
      final sub = ref.read(subscriptionProvider).value;
      if (sub?.isPremium == true) {
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  Future<void> _restore() async {
    await ref.read(subscriptionProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);
    final isPremium = subAsync.value?.isPremium ?? false;
    final isLoading = subAsync.value?.isLoading ?? false;
    final error = subAsync.value?.error;

    if (isPremium) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(title: '照护方案', showBack: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded,
                    size: 64, color: AppColors.secondary),
                SizedBox(height: AppSpacing.xl),
                AppText.headlineMedium('连续照护已开启'),
                SizedBox(height: AppSpacing.md),
                AppText.bodyMedium(
                  '感谢你的信任，我会一直在这里陪伴你。',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: '照护方案',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            AppCard.elevated(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded,
                          color: AppColors.secondary, size: 24),
                      SizedBox(width: AppSpacing.sm),
                      AppText.headlineMedium('连续照护'),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppText.bodyLarge('持续的陪伴，让顺时更了解你的节律与需要。'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            const AppText.titleLarge('照护会员包含'),
            const SizedBox(height: AppSpacing.md),

            ..._benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: AppText.bodyMedium(b)),
                    ],
                  ),
                )),

            const SizedBox(height: AppSpacing.xl),

            // Products
            if (_loadingProducts)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (_products.isEmpty)
              const AppNoticeCard(
                message: '暂时无法获取方案信息，请稍后再试。',
                type: AppNoticeType.info,
              )
            else ...[
              const AppText.titleLarge('选择方案'),
              const SizedBox(height: AppSpacing.md),
              ..._products.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ProductCard(
                      product: p,
                      isSelected: _selectedProductId == p.id,
                      onTap: () =>
                          setState(() => _selectedProductId = p.id),
                    ),
                  )),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Error
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppNoticeCard(message: error, type: AppNoticeType.warning),
              ),

            // Purchase button
            AppButton.primary(
              label: isLoading ? '处理中…' : '开启连续照护',
              isLoading: isLoading,
              fullWidth: true,
              onPressed: _products.isEmpty || isLoading ? null : _purchase,
            ),

            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _restore,
                child: const AppText.labelMedium(
                  '恢复购买记录',
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            const AppText.bodySmall(
              '通过 App Store / Google Play 管理订阅。购买前请确认已阅读相关条款。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  static const _benefits = [
    '完整的每日计划，包含个性化建议',
    '持续记忆，更懂你的生活节律',
    '照护会员专属内容（视频、深度文章）',
    '复杂跟进计划与本地提醒',
    '无限聊天，随时陪伴',
  ];
}

class _ProductCard extends StatelessWidget {
  final SubscriptionProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: product.id,
              groupValue: isSelected ? product.id : null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleLarge(product.period.label),
                  AppText.bodySmall(product.description),
                ],
              ),
            ),
            AppText.headlineSmall(product.price,
                color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
