import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/data/services/store_service.dart';

void main() {
  test('0S3 年付唯一：月价为空时显示年价，不把付费档显示成免费', () {
    final plan = SubscriptionPlan.fromJson({
      'id': 'yiyang',
      'name': '会员',
      'price_cents': null,
      'price_yearly_cents': 88800,
      'features': <String, dynamic>{},
    });
    expect(plan.priceCents, 88800);
    expect(plan.priceDisplay, '¥888');
  });

  test('商店只拉取两个在售年付商品', () {
    expect(StoreService.productIds.values.toSet(),
        {'com.shunshi.content.yearly', 'com.shunshi.member.yearly'});
  });
}
