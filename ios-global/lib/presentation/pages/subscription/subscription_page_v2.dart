/// Membership page for the international edition.
///
/// Prices are the store's own (App Store / Google Play) localised strings via [StorePricing];
/// when the store has not loaded them the page says "Price shown at checkout" instead of
/// inventing an amount or currency. No made-up counts such as "128 suggestions".
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/store_pricing.dart';
import '../../../data/services/store_service.dart';
import '../../../data/services/subscription_service.dart';
import '../../../design_system/theme.dart';

class SubscriptionPageV2 extends StatelessWidget {
  const SubscriptionPageV2({super.key});

  static const _paid = [
    SubscriptionProducts.serenity,
    SubscriptionProducts.harmony,
    SubscriptionProducts.family,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      appBar: AppBar(
        backgroundColor: ShunShiColors.background,
        leading: IconButton(
          key: const Key('subscription_back'),
          icon: const Icon(Icons.arrow_back),
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
          Container(
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
                Text('SEASONS Premium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ShunShiColors.surface)),
                const SizedBox(height: 4),
                const Text('Unlock the full library and unlimited conversations.',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final product in _paid) _PlanTile(product: product),
          const SizedBox(height: 8),
          Text(
            'Prices are set by your app store and shown in your local currency. '
            'Subscriptions renew automatically until you cancel in your store account settings.',
            key: const Key('subscription_footnote'),
            style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary, height: 1.4),
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
    final monthly = StorePricing.price(product.id);
    final yearly = StorePricing.price(product.id, yearly: true);
    final pending = monthly == StorePricing.pending;
    return Container(
      key: Key('plan_${product.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShunShiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShunShiColors.borderGhost),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ShunShiColors.textPrimary)),
          Text(product.description, style: TextStyle(fontSize: 12, color: ShunShiColors.textTertiary)),
          const SizedBox(height: 8),
          Text(
            pending ? monthly : '$monthly / month',
            key: Key('price_${product.id}_monthly'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ShunShiColors.primary),
          ),
          if (!pending && yearly != StorePricing.pending)
            Text('or $yearly / year',
                key: Key('price_${product.id}_yearly'),
                style: TextStyle(fontSize: 12, color: ShunShiColors.textSecondary)),
          const SizedBox(height: 8),
          if (!pending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                key: Key('subscribe_${product.id}'),
                onPressed: () => StoreService().purchase('${product.id}_monthly'),
                child: const Text('Subscribe monthly'),
              ),
            ),
          for (final f in product.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $f', style: TextStyle(fontSize: 13, color: ShunShiColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
