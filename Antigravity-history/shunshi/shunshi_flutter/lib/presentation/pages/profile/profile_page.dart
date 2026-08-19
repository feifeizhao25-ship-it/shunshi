import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../subscription/subscription_page.dart';
import 'settings_page.dart';

/// 我的（个人中心）
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text('顺',
                          style: TextStyle(
                              fontSize: 28,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(height: 12),
                    Text('用户',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.premiumGoldLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 14, color: AppColors.premiumGold),
                            SizedBox(width: 4),
                            Text('连续照护',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.premiumGold,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
                      Text('养生爱好者', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(label: '打卡天数', value: '0', icon: '📅'),
                  const SizedBox(width: 12),
                  _StatCard(label: '收藏', value: '0', icon: '❤️'),
                  const SizedBox(width: 12),
                  _StatCard(label: '连续', value: '0天', icon: '🔥'),
                ],
              ),
              const SizedBox(height: 16),
              _MenuItem(
                  icon: Icons.quiz_outlined,
                  title: '体质测试',
                  subtitle: '了解你的中医体质',
                  onTap: () {}),
              _MenuItem(
                  icon: Icons.assignment_outlined,
                  title: '调理方案',
                  subtitle: '个性化养生计划',
                  onTap: () {}),
              _MenuItem(
                  icon: Icons.favorite_outline,
                  title: '我的收藏',
                  subtitle: '已收藏的内容',
                  onTap: () {}),
              if (!isPremium)
                _MenuItem(
                  icon: Icons.spa_outlined,
                  title: '开启连续照护',
                  subtitle: '深度陪伴，持续养生',
                  isPremium: true,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SubscriptionPage())),
                ),
              _MenuItem(
                icon: Icons.settings_outlined,
                title: '设置',
                subtitle: '智能关怀、隐私与通知',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPremium = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPremium
            ? AppColors.premiumGoldLight.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isPremium
                ? AppColors.premiumGold
                : theme.colorScheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
