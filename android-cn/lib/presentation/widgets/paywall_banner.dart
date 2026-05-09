import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

/// 可关闭的升级提示 Banner — 嵌入页面底部
class PaywallBanner extends StatefulWidget {
  final String message;
  final IconData icon;

  const PaywallBanner({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  State<PaywallBanner> createState() => _PaywallBannerState();
}

class _PaywallBannerState extends State<PaywallBanner> {
  bool _dismissed = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isSubscribed = prefs.getBool('is_subscribed') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _isSubscribed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ShunShiColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ShunShiColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 20, color: ShunShiColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ShunShiColors.secondary,
                fontFamily: ShunShiTypography.sansFamily,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (context.mounted) {
                context.push('/subscription');
              }
            },
            child: const Text(
              '了解更多',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ShunShiColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Icon(Icons.close, size: 16, color: ShunShiColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
