import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login state the home can listen to.
///
/// `context.go('/home')` keeps the shell page alive, so storing a token does
/// not rebuild the personal section unless something notifies it.
class AuthSession extends ChangeNotifier {
  AuthSession({bool loggedIn = false}) : _loggedIn = loggedIn;

  bool _loggedIn;

  bool get loggedIn => _loggedIn;

  /// A token was just stored. Always notifies, so a section that already
  /// loaded the logged-out prompt can reload without a cold start.
  void markLoggedIn() {
    _loggedIn = true;
    notifyListeners();
  }

  void markLoggedOut() {
    if (!_loggedIn) return;
    _loggedIn = false;
    notifyListeners();
  }
}

final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) => AuthSession());
