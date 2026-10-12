/// Fetch the server's account UUID before opening the store purchase sheet.
/// A credential change at either async boundary invalidates this attempt.
Future<bool> launchAccountBoundPurchase({
  required String? Function() readToken,
  required Future<String?> Function(String token) loadAccountToken,
  required Future<bool> Function(String accountToken) buy,
}) async {
  final token = readToken();
  if (token == null || token.trim().isEmpty) return false;
  try {
    final account = await loadAccountToken(token);
    if (readToken() != token ||
        account == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(account)) {
      return false;
    }
    final launched = await buy(account);
    return readToken() == token && launched;
  } catch (_) {
    return false;
  }
}
