import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';

/// Optimistic update feedback — snackbar with undo capability.
/// Per UX_API_SPEC §6: instant UI update, failure rollback via undo snackbar.
///
/// Usage:
/// ```dart
/// OptimisticFeedback.show(
///   context,
///   message: 'Added to favorites',
///   onUndo: () => _revertFavorite(),
/// );
/// ```

class OptimisticFeedback {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    String? undoLabel,
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 4),
    bool isError = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isError
        ? (isDark ? SeasonsDarkColors.error : SeasonsColors.error)
        : (isDark ? SeasonsDarkColors.surface : const Color(0xFF333333));
    final textColor = isError ? Colors.white : (isDark ? Colors.white : Colors.white);

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: onUndo != null
            ? SnackBarAction(
                label: undoLabel ?? 'Undo',
                textColor: const Color(0xFF4CAF50),
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  /// Shorthand for success feedback
  static void success(BuildContext context, String message) {
    show(context, message: message);
  }

  /// Shorthand for error with retry
  static void error(BuildContext context, String message, {VoidCallback? onRetry}) {
    show(
      context,
      message: message,
      isError: true,
      undoLabel: 'Retry',
      onUndo: onRetry,
    );
  }
}
