import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';
import 'package:shunshi/data/services/store_service.dart';

const _omit = Object();

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
    expect(plan.familySeats, 0);
  });

  test('family_seats 只接受接口里的非负整数', () {
    SubscriptionPlan parse(Object? seats) {
      final json = <String, dynamic>{
        'id': 'jiahe',
        'name': '家和版（已停售）',
        'price_cents': 69900,
        'level': 3,
        'on_sale': false,
      };
      if (seats != _omit) json['family_seats'] = seats;
      return SubscriptionPlan.fromJson(json);
    }

    expect(parse(_omit).familySeats, 0);
    expect(parse(null).familySeats, 0);
    expect(parse(0).familySeats, 0);
    expect(parse(2).familySeats, 2);
    expect(parse(2.0).familySeats, 2);
    expect(parse(-1).familySeats, 0);
    expect(parse(2.9).familySeats, 0);
    expect(parse(double.nan).familySeats, 0);
    expect(parse(double.infinity).familySeats, 0);
    expect(parse('2').familySeats, 0);
    expect(parse(true).familySeats, 0);
  });

  test('商店只拉取两个在售年付商品', () {
    expect(StoreService.productIds.values.toSet(),
        {'com.shunshi.content.yearly', 'com.shunshi.member.yearly'});
  });
}
