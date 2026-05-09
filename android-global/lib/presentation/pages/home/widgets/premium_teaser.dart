import 'package:flutter/material.dart';
import '../../../../../design_system/theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_localizations.dart';

class PremiumTeaser extends StatelessWidget {
  const PremiumTeaser({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/subscription'),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('home_unlock_personalized_wellness'),
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context).t('home_exclusive_body_type_plans_longterm_tracking_a'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(AppLocalizations.of(context).t('home_7dayfree'),
              style: TextStyle(color: Color(0xFFFFA500), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
