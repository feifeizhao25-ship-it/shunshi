import 'dart:async';
import 'package:flutter/material.dart';

/// Delayed loading state — prevents flash/flicker for fast API responses.
/// Per UX_API_SPEC §3.3: loading indicator only shows after 200ms delay.
///
/// Usage:
/// ```dart
/// DelayedLoading(
///   isLoading: _loading,
///   loader: const SkeletonList(),
///   child: ListView(...),
/// )
/// ```
class DelayedLoading extends StatefulWidget {
  final bool isLoading;
  final Widget loader;
  final Widget child;
  final Duration delay;
  /// Minimum time to show loader once it appears (prevents flicker)
  final Duration minShowDuration;

  const DelayedLoading({
    super.key,
    required this.isLoading,
    required this.loader,
    required this.child,
    this.delay = const Duration(milliseconds: 200),
    this.minShowDuration = const Duration(milliseconds: 400),
  });

  @override
  State<DelayedLoading> createState() => _DelayedLoadingState();
}

class _DelayedLoadingState extends State<DelayedLoading> {
  bool _showLoader = false;
  Timer? _delayTimer;
  Timer? _minShowTimer;
  bool _minShowActive = false;

  @override
  void didUpdateWidget(DelayedLoading old) {
    super.didUpdateWidget(old);

    if (widget.isLoading && !old.isLoading) {
      // Started loading — delay before showing
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.delay, () {
        if (mounted && widget.isLoading) {
          setState(() => _showLoader = true);
          _minShowActive = true;
          _minShowTimer?.cancel();
          _minShowTimer = Timer(widget.minShowDuration, () {
            _minShowActive = false;
            _checkHide();
          });
        }
      });
    } else if (!widget.isLoading && old.isLoading) {
      _delayTimer?.cancel();
      _checkHide();
    }
  }

  void _checkHide() {
    if (!_minShowActive && mounted) {
      setState(() => _showLoader = false);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _minShowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoader && widget.isLoading) return widget.loader;
    if (widget.isLoading) return widget.child; // Still loading but not showing loader yet
    return widget.child;
  }
}

/// Fade-in wrapper for content transitions (skeleton → content)
class FadeInContent extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool enabled;

  const FadeInContent({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  @override
  State<FadeInContent> createState() => _FadeInContentState();
}

class _FadeInContentState extends State<FadeInContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.enabled) _controller.forward();
  }

  @override
  void didUpdateWidget(FadeInContent old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
