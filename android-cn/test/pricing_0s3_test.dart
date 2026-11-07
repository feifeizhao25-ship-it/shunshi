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

  test('365 天商品按年展示，不回退成基础功能或按天', () {
    final plan = SubscriptionPlan.fromJson({
      'product_id': 'content_yearly',
      'name': '内容订阅·年付',
      'price_cents': 39900,
      'duration_days': 365,
      'description': '每天 100 次对话+今日计划，适合养生爱好者',
      'features': {'basic_chat': true, 'today_plan': true},
    });
    expect(plan.periodName, '年');
    expect(plan.description, contains('100'));
    expect(plan.description, isNot(contains('基础功能')));
    expect(plan.familySeats, 0);
  });

  test('family_seats 以接口为准，level 不能改写成 4', () {
    final plan = SubscriptionPlan.fromJson({
      'id': 'jiahe',
      'name': '家和版（已停售）',
      'price_cents': 69900,
      'level': 3,
      'family_seats': 2,
      'on_sale': false,
    });
    expect(plan.familySeats, 2);
    expect(SubscriptionPlan.fromJson({
      'id': 'jiahe',
      'level': 3,
      'price_cents': 69900,
    }).familySeats, 0);
  });

  test('商店只拉取两个在售年付商品', () {
    expect(StoreService.productIds.values.toSet(),
        {'com.shunshi.content.yearly', 'com.shunshi.member.yearly'});
  });
}
