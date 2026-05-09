// SEASONS Profile Page — International Version
// Account / Wellness / Support sections

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../design_system/theme.dart';
import '../../../core/utils/units.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _useCelsius = true;
  bool _useKg = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useCelsius = prefs.getBool('use_celsius') ?? true;
      _useKg = prefs.getBool('use_kg') ?? true;
    });
  }

  Future<void> _setTempUnit(bool celsius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_celsius', celsius);
    setState(() => _useCelsius = celsius);
    Units.useCelsius = celsius;
  }

  Future<void> _setWeightUnit(bool kg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_kg', kg);
    setState(() => _useKg = kg);
    Units.useKg = kg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SEASONS',
                      style: TextStyle(
                        fontFamily: ShunShiTypography.serifFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ShunShiColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: ShunShiColors.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── User Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: ShunShiColors.surfaceContainerLow,
                          ),
                          child: const Icon(Icons.person, size: 36, color: ShunShiColors.textTertiary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: ShunShiColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: ShunShiColors.background, width: 2),
                            ),
                            child: const Icon(Icons.verified, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SEASONS Member',
                          style: TextStyle(
                            fontFamily: ShunShiTypography.serifFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ShunShiColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ShunShiColors.goldLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, size: 12, color: ShunShiColors.gold),
                              const SizedBox(width: 4),
                              Text(
                                'SVIP',
                                style: TextStyle(
                                  fontFamily: ShunShiTypography.sansFamily,
                                  fontSize: 10,
                                  color: ShunShiColors.gold,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    _StatCard('Points', '2,560'),
                    const SizedBox(width: 8),
                    _StatCard('Streak', '14 days'),
                    const SizedBox(width: 8),
                    _StatCard('Saved', '12'),
                  ],
                ),
              ),
            ),

            // ── Account Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: _SectionHeader(title: 'Account'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _MenuTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile - Coming Soon'), duration: Duration(seconds: 1)));
                    }),
                    _MenuTile(icon: Icons.card_membership, title: 'Subscription', onTap: () => context.push('/subscription')),
                    _MenuTile(icon: Icons.family_restroom, title: 'Family Wellness', onTap: () => context.push('/family')),
                    _MenuTile(icon: Icons.history, title: 'My Records', onTap: () => context.push('/records')),
                  ],
                ),
              ),
            ),

            // ── Wellness Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _SectionHeader(title: 'Wellness'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _MenuTile(icon: Icons.emoji_events_outlined, title: 'Achievements', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Achievements - Coming Soon'), duration: Duration(seconds: 1)));
                    }),
                    _MenuTile(icon: Icons.insights, title: 'Wellness Insights', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wellness Insights - Coming Soon'), duration: Duration(seconds: 1)));
                    }),
                    _MenuTile(icon: Icons.favorite_outline, title: 'Saved Content', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved Content - Coming Soon'), duration: Duration(seconds: 1)));
                    }),
                  ],
                ),
              ),
            ),

            // ── Preferences Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _SectionHeader(title: 'Preferences'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ToggleTile(
                      title: 'Temperature',
                      optionA: '°C',
                      optionB: '°F',
                      isA: _useCelsius,
                      onChanged: _setTempUnit,
                    ),
                    _ToggleTile(
                      title: 'Weight',
                      optionA: 'kg',
                      optionB: 'lb',
                      isA: _useKg,
                      onChanged: _setWeightUnit,
                    ),
                  ],
                ),
              ),
            ),

            // ── Support Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _SectionHeader(title: 'Support'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _MenuTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => context.push('/settings')),
                    _MenuTile(icon: Icons.help_outline, title: 'Help Center', onTap: () => context.push('/settings')),
                    _MenuTile(icon: Icons.headset_mic_outlined, title: 'Contact Support', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Support - Coming Soon'), duration: Duration(seconds: 1)));
                    }),
                    _MenuTile(icon: Icons.privacy_tip_outlined, title: 'Privacy & Data', onTap: () => context.push('/privacy')),
                    _MenuTile(icon: Icons.policy_outlined, title: 'GDPR Privacy Policy', onTap: () => context.push('/gdpr')),
                  ],
                ),
              ),
            ),

            // ── Brand Motto ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 1, color: ShunShiColors.border),
                      const SizedBox(width: 12),
                      Text(
                        'Live in harmony with nature',
                        style: TextStyle(
                          fontFamily: ShunShiTypography.serifFamily,
                          fontSize: 14,
                          color: ShunShiColors.textTertiary,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 16, height: 1, color: ShunShiColors.border),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShunShiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ShunShiShadows.sm,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              fontSize: 11,
              color: ShunShiColors.textTertiary,
            )),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(
              fontFamily: ShunShiTypography.serifFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ShunShiColors.primary,
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: ShunShiTypography.sansFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ShunShiColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: ShunShiColors.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(
                  fontFamily: ShunShiTypography.sansFamily,
                  fontSize: 15,
                  color: ShunShiColors.textPrimary,
                )),
              ),
              Icon(Icons.chevron_right, size: 18, color: ShunShiColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String optionA;
  final String optionB;
  final bool isA;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.title, required this.optionA, required this.optionB, required this.isA, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.tune, color: ShunShiColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(
              fontFamily: ShunShiTypography.sansFamily,
              fontSize: 15,
              color: ShunShiColors.textPrimary,
            )),
          ),
          _SegButton(label: optionA, active: isA, onTap: () => onChanged(true)),
          const SizedBox(width: 4),
          _SegButton(label: optionB, active: !isA, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ShunShiColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? ShunShiColors.primary : ShunShiColors.borderGhost),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: ShunShiTypography.sansFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ShunShiColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
