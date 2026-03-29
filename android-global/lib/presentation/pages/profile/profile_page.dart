import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/seasons_colors.dart';
import '../../../core/theme/seasons_text_styles.dart';
import '../../../core/theme/seasons_spacing.dart';
import '../../../data/services/store_service.dart';
import '../../../data/services/subscription_service.dart';
import '../../providers/profile_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/components/components.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? SeasonsDarkColors.background : SeasonsColors.background;
    final surface = isDark ? SeasonsDarkColors.surface : SeasonsColors.surface;
    final surfaceDim = isDark ? SeasonsDarkColors.surfaceDim : SeasonsColors.surfaceDim;
    final textPrimary = isDark ? SeasonsDarkColors.textPrimary : SeasonsColors.textPrimary;
    final textSecondary = isDark ? SeasonsDarkColors.textSecondary : SeasonsColors.textSecondary;
    final textHint = isDark ? SeasonsDarkColors.textHint : SeasonsColors.textHint;
    final border = isDark ? SeasonsDarkColors.border : SeasonsColors.border;
    final primary = isDark ? SeasonsDarkColors.primary : SeasonsColors.primary;
    final primaryLight = isDark ? SeasonsDarkColors.primaryLight : SeasonsColors.primaryLight;
    final error = isDark ? SeasonsDarkColors.error : SeasonsColors.error;
    final divider = isDark ? SeasonsDarkColors.divider : SeasonsColors.divider;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SeasonsSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 标题：greeting样式(30sp w200) ──
              Text(
                'Profile',
                style: SeasonsTextStyles.greeting.copyWith(color: textPrimary),
              ),
              const SizedBox(height: SeasonsSpacing.xl),

              // ── 用户卡片 ──
              _UserCard(
                user: profileState.user,
                isDark: isDark,
                primary: primary,
                primaryLight: primaryLight,
                textPrimary: textPrimary,
                surfaceDim: surfaceDim,
              ),

              const SizedBox(height: SeasonsSpacing.xl),

              // ── 统计 — 极简展示 ──
              _StatsRow(
                streakDays: profileState.streakDays,
                reflectionsCount: profileState.reflectionsCount,
                isDark: isDark,
                surface: surface,
                surfaceDim: surfaceDim,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: SeasonsSpacing.xl),

              // ── Subscription Card ──
              _SubscriptionCard(
                tier: subscriptionState.currentTier,
                onTap: () {
                  if (!subscriptionState.isPremium) {
                    context.push('/subscribe');
                  } else {
                    ref
                        .read(subscriptionProvider.notifier)
                        .manageSubscription();
                  }
                },
                isDark: isDark,
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textHint: textHint,
              ),

              const SizedBox(height: SeasonsSpacing.xl),

              // ── Health Records ──
              _HealthRecordsCard(
                isDark: isDark,
                surface: surface,
                surfaceDim: surfaceDim,
                textPrimary: textPrimary,
                textHint: textHint,
              ),

              const SizedBox(height: SeasonsSpacing.xl),

              // ── Settings Menu ──
              _MenuSection(
                isDark: isDark,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textHint: textHint,
                divider: divider,
                primary: primary,
                error: error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== User Card ====================

class _UserCard extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  final Color primary;
  final Color primaryLight;
  final Color textPrimary;
  final Color surfaceDim;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.primary,
    required this.primaryLight,
    required this.textPrimary,
    required this.surfaceDim,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name ?? 'User';
    final email = user.email ?? '';
    final avatarUrl = user.avatarUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeasonsSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                : Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: SeasonsTextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: SeasonsSpacing.md),
          Text(
            name,
            style: SeasonsTextStyles.heading.copyWith(
              color: Colors.white,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: SeasonsSpacing.xs),
            Text(
              email,
              style: SeasonsTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== Stats Row (极简) ====================

class _StatsRow extends StatelessWidget {
  final int streakDays;
  final int reflectionsCount;
  final bool isDark;
  final Color surface;
  final Color surfaceDim;
  final Color textPrimary;
  final Color textSecondary;

  const _StatsRow({
    required this.streakDays,
    required this.reflectionsCount,
    required this.isDark,
    required this.surface,
    required this.surfaceDim,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SoftCard(
            borderRadius: SeasonsSpacing.radiusLarge,
            child: Column(
              children: [
                Text(
                  '$streakDays',
                  style: SeasonsTextStyles.heading.copyWith(
                    color: SeasonsColors.warm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day Streak',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: SeasonsSpacing.sm),
        Expanded(
          child: SoftCard(
            borderRadius: SeasonsSpacing.radiusLarge,
            child: Column(
              children: [
                Text(
                  '$reflectionsCount',
                  style: SeasonsTextStyles.heading.copyWith(
                    color: SeasonsColors.sky,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reflections',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== Subscription Card ====================

class _SubscriptionCard extends StatelessWidget {
  final dynamic tier;
  final VoidCallback onTap;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const _SubscriptionCard({
    required this.tier,
    required this.onTap,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = tier != 'free' && tier != SubscriptionTier.free;

    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPremium
                  ? SeasonsColors.warm.withValues(alpha: 0.2)
                  : (isDark ? SeasonsDarkColors.surfaceDim : SeasonsColors.surfaceDim),
              borderRadius: BorderRadius.circular(SeasonsSpacing.radiusMedium),
            ),
            child: Icon(
              isPremium ? Icons.star : Icons.star_outline,
              color: isPremium ? SeasonsColors.warm : textHint,
            ),
          ),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium' : 'Free',
                  style: SeasonsTextStyles.body.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? 'Full access unlocked'
                      : 'Upgrade to unlock more',
                  style: SeasonsTextStyles.caption.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: textHint, size: 14),
        ],
      ),
    );
  }
}

// ==================== Health Records ====================

class _HealthRecordsCard extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final Color surfaceDim;
  final Color textPrimary;
  final Color textHint;

  const _HealthRecordsCard({
    required this.isDark,
    required this.surface,
    required this.surfaceDim,
    required this.textPrimary,
    required this.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: SeasonsSpacing.radiusLarge,
      onTap: () => context.push('/records'),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              color: SeasonsColors.sage, size: 24),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Text(
              'Health Records',
              style: SeasonsTextStyles.body.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: textHint, size: 14),
        ],
      ),
    );
  }
}

// ==================== Menu Section ====================

class _MenuSection extends StatefulWidget {
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color divider;
  final Color primary;
  final Color error;

  const _MenuSection({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.divider,
    required this.primary,
    required this.error,
  });

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
  bool _memoryEnabled = true;
  bool _dndEnabled = false;
  bool _notificationsEnabled = true;
  String _hemisphere = 'north';

  @override
  void initState() {
    super.initState();
    _loadHemisphere();
  }

  Future<void> _loadHemisphere() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _hemisphere = prefs.getString('hemisphere') ?? 'north');
  }

  Future<void> _setHemisphere(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hemisphere', value);
    if (mounted) {
      setState(() => _hemisphere = value);
      context.go('/home');
    }
  }

  void _showHemisphereSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: widget.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Select Hemisphere', style: SeasonsTextStyles.heading.copyWith(color: widget.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Affects seasonal content shown on home screen',
              style: SeasonsTextStyles.caption.copyWith(color: widget.textHint),
            ),
            const SizedBox(height: 20),
            _HemisphereOption(
              label: 'Northern Hemisphere',
              desc: 'North America, Europe, Asia (north)',
              isSelected: _hemisphere == 'north',
              onTap: () { Navigator.pop(ctx); _setHemisphere('north'); },
              primary: widget.primary,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
            ),
            const SizedBox(height: 12),
            _HemisphereOption(
              label: 'Southern Hemisphere',
              desc: 'South America, Australia, Africa (south)',
              isSelected: _hemisphere == 'south',
              onTap: () { Navigator.pop(ctx); _setHemisphere('south'); },
              primary: widget.primary,
              textPrimary: widget.textPrimary,
              textSecondary: widget.textSecondary,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: SeasonsSpacing.sm),
          child: Text(
            'Settings',
            style: SeasonsTextStyles.overline.copyWith(
              color: widget.textHint,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.border, width: 1),
          ),
          child: Column(
            children: [
              _SettingsSwitch(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                textPrimary: widget.textPrimary,
                primary: widget.primary,
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsSwitch(
                icon: Icons.do_not_disturb_on_outlined,
                label: 'Do Not Disturb',
                value: _dndEnabled,
                subtitle: _dndEnabled ? '10 PM - 8 AM' : null,
                onChanged: (v) => setState(() => _dndEnabled = v),
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                primary: widget.primary,
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsTile(
                icon: Icons.public,
                label: 'Hemisphere',
                value: _hemisphere == 'north' ? 'Northern' : 'Southern',
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                primary: widget.primary,
                onTap: () => _showHemisphereSheet(context),
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsSwitch(
                icon: Icons.psychology_outlined,
                label: 'AI Memory',
                value: _memoryEnabled,
                onChanged: (v) => setState(() => _memoryEnabled = v),
                textPrimary: widget.textPrimary,
                primary: widget.primary,
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsLink(
                icon: Icons.delete_outline,
                label: 'Clear Memory',
                color: widget.error,
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                isLast: false,
                onTap: () => _showClearDialog(context),
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsLink(
                icon: Icons.restore,
                label: 'Restore Purchases',
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                isLast: false,
                onTap: () => _handleRestorePurchase(context),
              ),
              _SettingsDivider(divider: widget.divider),
              _SettingsLink(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy & Safety',
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                isLast: false,
                onTap: () => context.push('/settings'),
              ),
              _SettingsLink(
                icon: Icons.help_outline,
                label: 'Help & Support',
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                isLast: false,
                onTap: () => context.push('/help'),
              ),
              _SettingsLink(
                icon: Icons.info_outline,
                label: 'About',
                textPrimary: widget.textPrimary,
                textHint: widget.textHint,
                isLast: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear Memory',
          style: SeasonsTextStyles.heading.copyWith(color: widget.textPrimary),
        ),
        content: Text(
          'This will remove everything the AI knows about you. You can start fresh.',
          style: SeasonsTextStyles.bodySecondary.copyWith(
            color: widget.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: SeasonsTextStyles.button.copyWith(
                color: widget.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _memoryEnabled = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory cleared')),
              );
            },
            child: Text(
              'Clear',
              style: SeasonsTextStyles.button.copyWith(color: widget.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestorePurchase(BuildContext context) async {
    final store = StoreService();
    if (!store.isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-App Purchase not available on this device'),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
    );

    try {
      await store.restorePurchases();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restoring purchases...'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
}

// ==================== Settings Components ====================

class _SettingsDivider extends StatelessWidget {
  final Color divider;
  const _SettingsDivider({required this.divider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SeasonsSpacing.md),
      child: Divider(color: divider, height: 1),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;
  final Color? textHint;
  final Color primary;

  const _SettingsSwitch({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    this.textHint,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SeasonsSpacing.md,
        vertical: SeasonsSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Icon(icon, color: SeasonsColors.textSecondary, size: 22),
          const SizedBox(width: SeasonsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SeasonsTextStyles.body.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: SeasonsTextStyles.overline.copyWith(
                      color: textHint ?? SeasonsColors.textHint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLast;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textHint;

  const _SettingsLink({
    required this.icon,
    required this.label,
    this.color,
    this.isLast = false,
    required this.onTap,
    required this.textPrimary,
    required this.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.md,
          vertical: SeasonsSpacing.md + 2,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? SeasonsColors.textSecondary, size: 22),
            const SizedBox(width: SeasonsSpacing.md),
            Expanded(
              child: Text(
                label,
                style: SeasonsTextStyles.body.copyWith(
                  color: color ?? textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: textHint, size: 14),
          ],
        ),
      ),
    );
  }
}

// ==================== OAuth Section (preserved) ====================
// Note: OAuth section removed from profile page for minimal design
// Can be added back as a separate card if needed

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textHint;
  final Color primary;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textHint,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SeasonsSpacing.md,
          vertical: SeasonsSpacing.md + 2,
        ),
        child: Row(
          children: [
            Icon(icon, color: SeasonsColors.textSecondary, size: 22),
            const SizedBox(width: SeasonsSpacing.md),
            Expanded(
              child: Text(
                label,
                style: SeasonsTextStyles.body.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              value,
              style: SeasonsTextStyles.body.copyWith(
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: textHint, size: 14),
          ],
        ),
      ),
    );
  }
}

class _HemisphereOption extends StatelessWidget {
  final String label;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const _HemisphereOption({
    required this.label,
    required this.desc,
    required this.isSelected,
    required this.onTap,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? primary : textSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SeasonsTextStyles.body.copyWith(color: textPrimary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(desc, style: SeasonsTextStyles.caption.copyWith(color: textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

