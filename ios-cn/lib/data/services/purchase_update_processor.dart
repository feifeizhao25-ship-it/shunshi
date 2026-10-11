import 'package:in_app_purchase/in_app_purchase.dart';

/// Serialize store events; finish successful transactions only after verification.
class PurchaseUpdateProcessor {
  PurchaseUpdateProcessor({
    required this.verifyPurchase,
    required this.verifyRestore,
    required this.completePurchase,
    required this.onTerminal,
    required this.onError,
  });
  final Future<bool> Function(PurchaseDetails) verifyPurchase;
  final Future<bool> Function(PurchaseDetails) verifyRestore;
  final Future<void> Function(PurchaseDetails) completePurchase;
  final void Function(PurchaseDetails) onTerminal;
  final void Function() onError;
  Future<void> _queue = Future<void>.value();

  Future<void> handle(
    List<PurchaseDetails> purchases, {
    bool Function()? canVerify,
  }) {
    final batch = List<PurchaseDetails>.of(purchases);
    _queue = _queue.then((_) async {
      for (final purchase in batch) {
        try {
          var readyToComplete = false;
          switch (purchase.status) {
            case PurchaseStatus.purchased:
              if (canVerify?.call() ?? true) {
                readyToComplete = await verifyPurchase(purchase);
                readyToComplete =
                    readyToComplete && (canVerify?.call() ?? true);
              }
              break;
            case PurchaseStatus.restored:
              if (canVerify?.call() ?? true) {
                readyToComplete = await verifyRestore(purchase);
                readyToComplete =
                    readyToComplete && (canVerify?.call() ?? true);
              }
              break;
            case PurchaseStatus.error:
            case PurchaseStatus.canceled:
              onTerminal(purchase);
              // Preserve SDK cleanup for failed/cancelled terminal events;
              // these do not grant any membership.
              readyToComplete = true;
              break;
            case PurchaseStatus.pending:
              break;
          }
          if (readyToComplete && purchase.pendingCompletePurchase) {
            await completePurchase(purchase);
          }
        } catch (_) {
          // Keep the queue alive and leave the transaction unacknowledged.
          try {
            onError();
          } catch (_) {
            /* Observers cannot poison the queue. */
          }
        }
      }
    });
    return _queue;
  }
}
