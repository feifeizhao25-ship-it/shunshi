import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/services/rights_status.dart';
import 'package:seasons/data/services/subscription_service.dart';

void main() {
  test('free status is not a paid badge and uses the registry daily limit', () {
    final snap = rightsFromStatusBody({
      'success': true,
      'tier': 'free',
      'active': false,
      'expires_at': null,
      'data': {
        'plan': 'free',
        'is_active': false,
        'features': {'daily_chat_limit': 20},
      },
    });
    expect(snap.paid, isFalse);
    expect(snap.tier, SubscriptionTier.free);
    expect(snap.dailyChatLimit, 20);
  });

  test('registry tier pro is premium, not free, and keeps the unix expiry', () {
    final snap = rightsFromStatusBody({
      'success': true,
      'tier': 'pro',
      'active': true,
      'expires_at': 1800000000,
      'data': {
        'plan': 'yiyang',
        'is_active': true,
        'expires_at': 1800000000,
        'features': {'daily_chat_limit': 200},
      },
    });
    expect(snap.paid, isTrue);
    expect(snap.tier, SubscriptionTier.serenity);
    expect(snap.dailyChatLimit, 200);
    expect(snap.expiresAt, DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true));
  });

  test('reading only the nested object must not treat a missing tier as paid', () {
    final nested = {
      'plan': 'free',
      'is_active': false,
      'features': {'daily_chat_limit': 20},
    };
    // 旧对话页：data['tier'] != 'free'，内层没有 tier，null != 'free' 为真。
    expect(nested['tier'] != 'free', isTrue);
    final snap = rightsFromStatusBody({'success': true, 'tier': 'free', 'data': nested});
    expect(snap.paid, isFalse);
  });
}
