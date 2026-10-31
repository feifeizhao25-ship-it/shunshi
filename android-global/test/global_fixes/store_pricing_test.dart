import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:seasons/data/services/store_pricing.dart';
import 'package:seasons/data/services/subscription_service.dart';

void main() {
  tearDown(() => StorePricing.lookup = (id) => null);

  test('no store data: every plan says price shown at checkout (no hard-coded dollars)', () {
    StorePricing.lookup = (id) => null;
    final paid = SubscriptionProducts.plans.where((p) => p.id != 'free');
    expect(paid, isNotEmpty);
    for (final p in paid) {
      expect(p.priceDisplay, StorePricing.pending, reason: p.id);
    }
  });

  test('store price is used verbatim, in the store currency', () {
    StorePricing.lookup = (id) => id == 'serenity_monthly'
        ? ProductDetails(id: id, title: 't', description: '', price: 'CA\$11.99', rawPrice: 11.99, currencyCode: 'CAD')
        : null;
    expect(StorePricing.price('serenity'), 'CA\$11.99');
    expect(StorePricing.price('harmony'), StorePricing.pending);
    expect(StorePricing.price('unknown'), StorePricing.pending);
  });
}
