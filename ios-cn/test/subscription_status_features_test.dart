import 'package:flutter_test/flutter_test.dart';
import 'package:shunshi/data/models/subscription.dart';

void main() {
  test('GET /api/v1/subscription/status features keep bools when daily_chat_limit is an int', () {
    final status = UserSubscriptionStatus.fromJson({
      'plan_id': 'free',
      'plan_name': '免费版',
      'is_active': true,
      'features': {
        'basic_chat': true,
        'solar_terms': true,
        'daily_chat_limit': 20,
        'unlimited_chat': false,
      },
    });

    expect(status.features, {
      'basic_chat': true,
      'solar_terms': true,
      'unlimited_chat': false,
    });
    expect(status.features.containsKey('daily_chat_limit'), isFalse);
    expect(status.isActive, isTrue);
  });

  test('missing or non-map features do not throw', () {
    expect(UserSubscriptionStatus.fromJson({}).features, isEmpty);
    expect(UserSubscriptionStatus.fromJson({'features': null}).features, isEmpty);
    expect(UserSubscriptionStatus.fromJson({'features': 'nope'}).features, isEmpty);
  });
}
