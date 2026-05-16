// test/unit/models/subscription_test.dart
// TC-PAY: 订阅/支付模型测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';

void main() {
  group('Subscription', () {
    test('TC-PAY-001: Subscription fromJson', () {
      final sub = Subscription.fromJson({
        'id': 'sub_123',
        'user_id': 'u1',
        'plan_type': 'yearly',
        'payment_method': 'wechat',
        'started_at': '2026-01-01T00:00:00Z',
        'expires_at': '2027-01-01T00:00:00Z',
        'is_active': true,
      });
      expect(sub.id, 'sub_123');
      expect(sub.planType, 'yearly');
      expect(sub.isActive, isTrue);
    });

    test('TC-PAY-001b: Subscription defaults', () {
      final sub = Subscription.fromJson({'id': 'x', 'user_id': 'u', 'started_at': '2026-01-01'});
      expect(sub.planType, 'free');
      expect(sub.isActive, isTrue);
      expect(sub.paymentMethod, isNull);
    });
  });

  group('SubscriptionPlan', () {
    test('TC-PAY-001c: plan with price in yuan', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'monthly',
        'name': '月度会员',
        'price': 18,
        'level': 1,
      });
      expect(plan.priceCents, 1800);
      expect(plan.priceDisplay, '¥18');
    });

    test('TC-PAY-001d: plan with price_cents', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'yearly',
        'name': '年度会员',
        'price_cents': 16800,
        'level': 2,
      });
      expect(plan.priceCents, 16800);
      expect(plan.priceDisplay, '¥168');
    });

    test('TC-PAY-001e: free plan display', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'free',
        'name': '免费',
        'level': 0,
      });
      expect(plan.priceDisplay, '免费');
    });

    test('TC-PAY-001f: recommended flag on yearly', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'yearly',
        'name': '年度',
        'price_cents': 16800,
        'level': 2,
      });
      expect(plan.isRecommended, isTrue);
    });

    test('TC-PAY-001g: family plan has 4 seats', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 'family',
        'name': '家庭版',
        'price_cents': 59800,
        'level': 3,
      });
      expect(plan.familySeats, 4);
    });
  });

  group('SubscriptionOrder', () {
    test('TC-PAY-010: order fromJson', () {
      final order = SubscriptionOrder.fromJson({
        'order_id': 'ord_123',
        'plan_id': 'yearly',
        'amount_cents': 16800,
        'status': 'pending',
        'created_at': '2026-05-15T10:00:00Z',
      });
      expect(order.orderId, 'ord_123');
      expect(order.status, 'pending');
      expect(order.amountCents, 16800);
    });
  });

  group('UserSubscriptionStatus', () {
    test('TC-PAY-013: user status fromJson', () {
      final status = UserSubscriptionStatus.fromJson({
        'plan_id': 'yearly',
        'plan_name': '年度会员',
        'is_active': true,
        'day_remaining': 250,
        'features': {'unlimited_chat': true},
      });
      expect(status.isActive, isTrue);
      expect(status.dayRemaining, 250);
      expect(status.features['unlimited_chat'], isTrue);
    });

    test('TC-PAY-013b: expired subscription', () {
      final status = UserSubscriptionStatus.fromJson({
        'plan_id': 'monthly',
        'plan_name': '月度会员',
        'is_active': false,
        'day_remaining': 0,
      });
      expect(status.isActive, isFalse);
      expect(status.dayRemaining, 0);
    });
  });
}
