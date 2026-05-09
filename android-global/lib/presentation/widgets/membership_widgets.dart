import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';

/// Membership card for home page — only shown for free tier
class MembershipCard extends StatefulWidget {
  const MembershipCard({super.key});

  @override
  State<MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<MembershipCard> {
  bool _isSubscribed = false;
  bool _dismissed = false;

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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ShunShiColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ShunShiColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, size: 22, color: ShunShiColors.gold),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Premium Membership',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D4037),
                    fontFamily: ShunShiTypography.serifFamily,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF8D6E63)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            ('💬', 'Unlimited AI conversations'),
            ('📊', 'Deep wellness insights'),
            ('👨‍👩‍👧‍👦', 'Family sharing'),
            ('📅', 'Exclusive seasonal reports'),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5D4037),
                    fontFamily: ShunShiTypography.sansFamily,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => context.push('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShunShiColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Token balance bar for chat page top
class TokenBalanceBar extends StatelessWidget {
  final int remaining;
  final int limit;
  final bool isVip;
  final VoidCallback? onTapUpgrade;

  const TokenBalanceBar({
    super.key,
    required this.remaining,
    required this.limit,
    required this.isVip,
    this.onTapUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (isVip) return const SizedBox.shrink();

    final isLow = remaining < 3;
    return GestureDetector(
      onTap: isLow ? onTapUpgrade : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLow
              ? Colors.orange.withValues(alpha: 0.1)
              : ShunShiColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLow
                ? Colors.orange.withValues(alpha: 0.2)
                : ShunShiColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLow ? Icons.warning_amber_rounded : Icons.chat_bubble_outline_rounded,
              size: 16,
              color: isLow ? Colors.orange : ShunShiColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLow ? 'Upgrade for unlimited conversations' : '$remaining conversations remaining today',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isLow ? Colors.orange : ShunShiColors.primary,
                  fontFamily: ShunShiTypography.sansFamily,
                ),
              ),
            ),
            if (isLow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                child: const Text('Upgrade', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
