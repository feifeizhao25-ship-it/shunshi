import 'package:shared_preferences/shared_preferences.dart';

import '../../data/network/api_client.dart';
import '../pages/chat/chat_membership.dart';
import 'account_surface.dart';

/// Reads the three settings lines from the account record, the entitlement
/// status, and the solar-term table. Tests pass [readMembership] so this
/// never calls a payment or network service.
Future<AccountSurface> loadSettingsAccount({
  Future<bool?> Function()? readMembership,
  DateTime? beijingDay,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final loggedIn = (prefs.getString('auth_token') ?? '').trim().isNotEmpty;
  final nickname = accountNickname(
    userInfoJson: prefs.getString('user_info'),
    userName: prefs.getString('user_name'),
  );
  bool? active;
  if (loggedIn) {
    try {
      active = await (readMembership ?? readMembershipStatus)();
    } catch (_) {
      active = null;
    }
  }
  return accountSurface(
    loggedIn: loggedIn,
    nickname: nickname,
    membershipActive: loggedIn ? active : null,
    beijingDay: beijingDay,
  );
}

Future<bool?> readMembershipStatus() async {
  final res = await ApiClient().get(kMembershipStatusPath);
  return parseChatMembership(res.data);
}
