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

  test('365 天商品按年展示，不回退成月付文案', () {
    final plan = SubscriptionPlan.fromJson({
      'product_id': 'content_yearly',
      'name': '内容订阅·年付',
      'price_cents': 39900,
      'duration_days': 365,
      'description': '每天 100 次对话+今日计划，适合养生爱好者',
      'features': {'basic_chat': true, 'today_plan': true},
    });
    expect(plan.periodName, '年');
    expect(plan.period, 'year');
    expect(plan.description, contains('100'));
    expect(plan.description, isNot(contains('月度')));
  });

  test('商店只拉取两个在售年付商品', () {
    expect(StoreService.productIds.values.toSet(),
        {'com.shunshi.content.yearly', 'com.shunshi.member.yearly'});
  });
}
