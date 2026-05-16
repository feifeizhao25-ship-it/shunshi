import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_spacing.dart';

/// Offline banner — shows at top when no network
/// Per UX_API_SPEC §12: yellow bar with "Using offline data" message
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final int pendingSyncCount;

  OfflineBanner({
    super.key,
    required this.isOffline,
    this.pendingSyncCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF3CD);
    final textColor = isDark ? const Color(0xFFE8D48B) : const Color(0xFF856404);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.md,
        vertical: SeasonsSpacing.sm,
      ),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.wifi_off, size: 16, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pendingSyncCount > 0
                    ? 'No network · $pendingSyncCount items pending sync'
                    : 'No network · Using cached data',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connectivity provider — tracks online/offline state
class ConnectivityNotifier extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOffline = false;
  int _pendingSync = 0;

  bool get isOffline => _isOffline;
  int get pendingSyncCount => _pendingSync;

  void start() {
    _connectivity.onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        _isOffline = offline;
        notifyListeners();
      }
    });
  }

  void setPendingSync(int count) {
    _pendingSync = count;
    notifyListeners();
  }
}
