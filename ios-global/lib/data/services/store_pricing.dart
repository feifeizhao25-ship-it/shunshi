/// Subscription prices come from the app store only (App Store / Google Play), so the
/// amount and currency are the ones the user's store account will actually be charged in.
///
/// Never hard-code an amount: the UI test found a Chinese yuan price and an invented
/// "128 health suggestions" line on the international subscription page.
library;

import 'package:in_app_purchase/in_app_purchase.dart';

import 'store_service.dart';

class StorePricing {
  const StorePricing._();

  static const pending = 'Price shown at checkout';

  /// Test hook: replace to supply product details without a store connection.
  /// The argument is the StoreService.productIds key, for example `serenity_monthly`.
  static ProductDetails? Function(String productId) lookup =
      (id) => StoreService().getProductDetails(id);

  /// Store-localised price string (for example "£8.99" or "¥1,200"), or [pending].
  static String price(String planId, {bool yearly = false}) {
    final key = '${planId}_${yearly ? 'yearly' : 'monthly'}';
    if (!StoreService.productIds.containsKey(key)) return pending;
    final p = lookup(key);
    final text = p?.price;
    return (text == null || text.trim().isEmpty) ? pending : text;
  }
}
