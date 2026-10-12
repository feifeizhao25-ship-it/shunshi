/// The current backend verifies app receipts, not StoreKit 2 transaction JWS.
/// Read the native app receipt for SK2 and fail closed if it is unavailable.
Future<String> appleVerificationReceipt({
  required bool storeKit2,
  required String eventData,
  required Future<String> Function() readAppReceipt,
  Duration timeout = const Duration(seconds: 10),
}) async {
  if (!storeKit2) return eventData;
  final receipt = await readAppReceipt().timeout(timeout);
  if (receipt.trim().isEmpty || receipt.contains('.')) {
    throw StateError('App receipt unavailable');
  }
  return receipt;
}
