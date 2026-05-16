// Optimistic Update Helper — UX_API_SPEC §6
// Provides optimistic update with automatic rollback on failure
// Usage: OptimisticUpdate<List<CartItem>>.run(
//   optimistic: () => setState(() => cart.add(item)),
//   rollback: () => setState(() => cart.remove(item)),
//   apiCall: () => api.post('/cart/add', data: item),
//   onSuccess: () => showSnackBar('Added!'),
//   onError: () => showSnackBar('Failed — reverted'),
// );

import 'package:flutter/material.dart';

class OptimisticUpdate<T> {
  final VoidCallback optimistic;
  final VoidCallback rollback;
  final Future<T> Function() apiCall;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final Duration timeout;

  const OptimisticUpdate({
    required this.optimistic,
    required this.rollback,
    required this.apiCall,
    this.onSuccess,
    this.onError,
    this.timeout = const Duration(seconds: 8),
  });

  /// Run optimistic update: apply UI change immediately, rollback on API failure
  static Future<void> run<T>({
    required VoidCallback optimistic,
    required VoidCallback rollback,
    required Future<T> Function() apiCall,
    VoidCallback? onSuccess,
    VoidCallback? onError,
    String? undoLabel,
  }) async {
    // 1. Apply optimistic UI change immediately
    optimistic();

    try {
      // 2. Fire API call
      await apiCall();
      onSuccess?.call();
    } catch (_) {
      // 3. Rollback on failure
      rollback();
      onError?.call();
    }
  }

  /// With undo snackbar — shows undo option for 4 seconds
  static Future<void> withUndo<T>({
    required VoidCallback optimistic,
    required VoidCallback rollback,
    required Future<T> Function() apiCall,
    required BuildContext context,
    String message = 'Done',
    String undoLabel = 'Undo',
    Duration undoWindow = const Duration(seconds: 4),
  }) async {
    // 1. Apply immediately
    optimistic();

    final scaffold = ScaffoldMessenger.of(context);

    // 2. Show snackbar with undo
    final controller = scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: undoWindow,
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () {
            rollback();
          },
        ),
      ),
    );

    // 3. Fire API in background
    try {
      await apiCall();
    } catch (_) {
      controller.close();
      rollback();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Action failed — reverted')),
      );
    }
  }
}

/// Toggle helper for boolean states (favorite, like, bookmark)
class OptimisticToggle {
  bool value;

  OptimisticToggle(this.value);

  /// Toggle with optimistic update
  Future<void> flip({
    required VoidCallback rebuild,
    required Future<void> Function(bool newValue) apiCall,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final previous = value;
    value = !value;
    rebuild();

    try {
      await apiCall(value);
      onSuccess?.call();
    } catch (_) {
      value = previous;
      rebuild();
      onError?.call();
    }
  }
}
