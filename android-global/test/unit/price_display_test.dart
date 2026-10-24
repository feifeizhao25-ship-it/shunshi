import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/subscription.dart';

void main() {
  test('international app never shows CNY or a guessed currency', () {
    final p = SubscriptionPlan.fromJson({'id': 'y', 'name': 'Wellness', 'price_cents': 39900, 'level': 2});
    expect(p.priceDisplay, SubscriptionPlan.pricePending);
    expect(SubscriptionPlan.formatMoney(39900, 'CNY'), SubscriptionPlan.pricePending);
  });
  test('formats explicit store currencies', () {
    expect(SubscriptionPlan.formatMoney(999, 'USD'), r'$9.99');
    expect(SubscriptionPlan.formatMoney(4900, 'EUR'), '€49');
  });
}
