import '../ios-cn/lib/data/models/subscription.dart' as ios;
import '../android-cn/lib/data/models/subscription.dart' as android;
import '../ios-cn/lib/data/models/user.dart' as ios_user;
import '../android-cn/lib/data/models/user.dart' as android_user;

void main() {
  const seconds = 1791676800;
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  for (final parser in [ios.UserSubscriptionStatus.fromJson, android.UserSubscriptionStatus.fromJson]) {
    for (final expiry in [seconds, date.toIso8601String()]) {
      final dynamic status = parser({'plan':'jiahe','plan_name':'家和版','is_active':true,
        'expires_at':expiry,'features':{'family':true}});
      if (status.planId != 'jiahe' || !status.isActive || status.expiresAt != date) {
        throw StateError('Paid membership parsing failed');
      }
    }
    for (final expiry in [null, 'invalid', {}, double.infinity, 1e30]) {
      final dynamic status = parser({'plan':'free','is_active':false,'expires_at':expiry});
      if (status.isActive || status.expiresAt != null) throw StateError('Invalid expiry handling failed');
    }
  }
  for (final parser in [ios_user.User.fromJson, android_user.User.fromJson]) {
    final dynamic user = parser({'id':'owner','subscription_type':'jiahe',
      'subscription_plan':'jiahe','subscription_expires_at':date.toIso8601String()});
    if (user.subscriptionType != 'jiahe' || user.subscriptionExpiresAt != date) {
      throw StateError('Profile membership parsing failed');
    }
  }
  print('Domestic membership model checks passed (16 cases)');
}
