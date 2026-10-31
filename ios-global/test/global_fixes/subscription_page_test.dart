import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:seasons/data/services/store_pricing.dart';
import 'package:seasons/presentation/pages/subscription/subscription_page_v2.dart';

ProductDetails _product(String id, String price, String code) =>
    ProductDetails(id: id, title: id, description: '', price: price, rawPrice: 1, currencyCode: code);

void main() {
  tearDown(() => StorePricing.lookup = (id) => null);

  testWidgets('without store data the page invents no price, currency or count', (tester) async {
    StorePricing.lookup = (id) => null;
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SubscriptionPageV2()));
    expect(find.text('Price shown at checkout'), findsNWidgets(3));
    final all = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join('\n');
    expect(all.contains('128'), isFalse);
    expect(all.contains('¥'), isFalse);
    expect(all.contains(r'$'), isFalse);
    expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(all), isFalse);
  });

  testWidgets('shows the store-localised price and currency exactly as the store reports them', (tester) async {
    StorePricing.lookup = (id) => switch (id) {
          'serenity_monthly' => _product(id, '£8.99', 'GBP'),
          'serenity_yearly' => _product(id, '£69.99', 'GBP'),
          'harmony_monthly' => _product(id, '€12,99', 'EUR'),
          _ => null,
        };
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SubscriptionPageV2()));
    expect(find.byKey(const Key('price_serenity_monthly')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('price_serenity_monthly'))).data, '£8.99 / month');
    expect(tester.widget<Text>(find.byKey(const Key('price_serenity_yearly'))).data, 'or £69.99 / year');
    expect(tester.widget<Text>(find.byKey(const Key('price_harmony_monthly'))).data, '€12,99 / month');
    expect(tester.widget<Text>(find.byKey(const Key('price_family_monthly'))).data, 'Price shown at checkout');
  });
}
