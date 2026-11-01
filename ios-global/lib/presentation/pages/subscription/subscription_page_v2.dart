/// Membership page for the international edition.
///
/// Prices are the store's own (App Store / Google Play) localised strings via [StorePricing];
/// when the store has not loaded them the page says "Price shown at checkout" instead of
/// inventing an amount or currency. No made-up counts such as "128 suggestions".
library;

import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';
import '../../widgets/seasons_visual.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/store_pricing.dart';
import '../../../data/services/store_service.dart';
import '../../../data/services/subscription_service.dart';
import '../../../design_system/theme.dart';

class SubscriptionPageV2 extends StatelessWidget {
  const SubscriptionPageV2({super.key});

  static const _paid = [
    SubscriptionProducts.serenity,
    SubscriptionProducts.family,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        leading: IconButton(
          key: const Key('subscription_back'),
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/today'),
        ),
        title: Text(
          'Membership',
          style: TextStyle(fontFamily: ShunShiTypography.serifFamily, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          const SgHeroBanner(
            asset: 'assets/images/sg_hero_member.webp',
            title: 'SEASONS Premium',
            subtitle: 'Unlock the full library and unlimited conversations.',
            height: 160,
          ),
          const SizedBox(height: 16),
          for (final product in _paid) _PlanTile(product: product),
          const SizedBox(height: 8),
          Text(
            'Prices are set by your app store and shown in your local currency. '
            'Subscriptions renew automatically until you cancel in your store account settings.',
            key: const Key('subscription_footnote'),
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context), height: 1.4),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.product});

  final SubscriptionProduct product;

  @override
  Widget build(BuildContext context) {
    final yearly = StorePricing.price(product.id, yearly: true);
    final pending = yearly == StorePricing.pending;
    return Container(
      key: Key('plan_${product.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGhost(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          Text(product.description, style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context))),
          const SizedBox(height: 8),
          Text(
            pending ? yearly : '$yearly / year',
            key: Key('price_${product.id}_yearly'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary(context)),
          ),
          const SizedBox(height: 8),
          if (!pending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                key: Key('subscribe_${product.id}'),
                onPressed: () => StoreService().purchase('${product.id}_yearly'),
                child: const Text('Subscribe yearly'),
              ),
            ),
          for (final f in product.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $f', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
            ),
        ],
      ),
    );
  }
}
