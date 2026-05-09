// Network State Widget
// Shows offline banner and handles network state changes

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/network_service.dart';
import '../../core/offline/offline_sync_service.dart';

class NetworkStateWrapper extends StatefulWidget {
  final Widget child;
  
  const NetworkStateWrapper({super.key, required this.child});
  
  @override
  State<NetworkStateWrapper> createState() => _NetworkStateWrapperState();
}

class _NetworkStateWrapperState extends State<NetworkStateWrapper> {
  StreamSubscription? _subscription;
  bool _isOffline = false;
  
  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _subscription = networkService.statusStream.listen(_onNetworkChange);
  }
  
  Future<void> _checkInitialStatus() async {
    final isOnline = await networkService.isOnline();
    if (mounted) {
      setState(() => _isOffline = !isOnline);
    }
  }
  
  void _onNetworkChange(NetworkStatus status) {
    if (mounted) {
      setState(() => _isOffline = status == NetworkStatus.offline);
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline) _OfflineBanner(),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              '网络已断开，部分功能可能不可用',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Offline-aware button that shows loading when offline
class OfflineAwareButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool showOfflineIndicator;
  
  const OfflineAwareButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.showOfflineIndicator = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: networkService.isOnline(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        
        if (!isOnline && showOfflineIndicator) {
          return Opacity(
            opacity: 0.5,
            child: child,
          );
        }
        
        return InkWell(
          onTap: isOnline ? onPressed : null,
          child: child,
        );
      },
    );
  }
}

// Sync status indicator
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: offlineSyncService.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        
        switch (status) {
          case SyncStatus.idle:
            return const SizedBox.shrink();
          case SyncStatus.syncing:
            return const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('同步中...'),
              ],
            );
          case SyncStatus.completed:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 8),
                const Text('已同步'),
              ],
            );
          case SyncStatus.error:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                const Text('同步失败'),
              ],
            );
        }
      },
    );
  }
}
